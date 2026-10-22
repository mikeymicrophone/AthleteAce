class GameRoundSetup
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :game_type, :string, default: "player_team_match"
  attribute :length, :integer, default: 10
  attribute :include_inactive, :boolean, default: false
  %i[sport_id league_id season_id conference_id division_id city_id state_id team_id].each { |key| attribute key, :integer }
  attribute :team_ids, default: -> { [] }
  attribute :team_query, :string
  attribute :goal_achievement_id, :integer
  attribute :player_group_id, :integer
  attribute :player_ids, default: -> { [] }
  attribute :player_id, :integer
  attribute :fact_type, :string, default: "team"
  attribute :practice_filter, :string, default: "all"
  attr_accessor :ace

  FACTS = { "team" => [ "Team", "team" ], "birth_city" => [ "City", "birth_city" ], "birth_country" => [ "Country", "birth_country" ] }.freeze
  PRACTICE_FILTERS = { "all" => "All members", "remaining" => "Not yet answered correctly", "missed" => "Needs practice" }.freeze
  validates :practice_filter, inclusion: { in: PRACTICE_FILTERS.keys }
  validates :fact_type, inclusion: { in: FACTS.keys }

  validates :game_type, inclusion: { in: GameRound::GAMES.keys }
  validates :length, inclusion: { in: GameRound::LENGTHS }
  validate :valid_scope

  def sport
    @sport ||= Sport.find_by id: sport_id if sport_id
  end

  def league
    @league ||= League.find_by id: league_id if league_id
  end

  def season
    @season ||= Season.find_by(id: season_id) if season_id
  end

  def seasons
    scope = Season.includes(:year, :league)
    scope = scope.where(league_id: league_id) if league_id
    scope = scope.joins(:league).where(leagues: { sport_id: sport_id }) if sport_id
    scope.recent
  end

  def season_suggestion
    return unless seasonal_game? && !season_id && valid? && available_count.zero?
    return if practice_players(scoped_players).where.not(team_id: nil).exists?
    return @season_suggestion if defined?(@season_suggestion)

    @season_suggestion = nil
    seasons.limit(10).each do |record|
      candidate = self.class.new(scope_params.merge("season_id" => record.id, "ace" => ace))
      if candidate.available_count.positive?
        @season_suggestion = candidate
        break
      end
    end
    @season_suggestion
  end

  def season_pool
    @season_pool ||= SeasonTeamMatchPool.new(season: season, team_ids: scoped_teams.pluck(:id))
  end

  def seasonal_game?
    %w[player_team_match name_ciphers multiple_choice image_recognition].include?(game_type)
  end

  def cipher_pool
    @cipher_pool ||= begin
      scope = if season
        season_pool.players
      elsif [ sport_id, league_id, conference_id, division_id, city_id, state_id, *selected_team_ids ].any?
        Player.where(team_id: scoped_teams.select(:id))
      else
        Player.all
      end
      scope = filter_players(scope)
      NameCipherRound.new(players: scope.includes(:team).order(:id).to_a, season: season, subject_ids: practice_subject_ids,
        team_for: season ? season_pool.method(:team_for) : nil)
    end
  end

  def player_group
    @player_group ||= PlayerGroup.find_by(id: player_group_id) if player_group_id
  end

  def goal_achievement
    @goal_achievement ||= GoalAchievement.joins(:goal).where(goals: { ace_id: ace.id }).find_by(id: goal_achievement_id) if ace && goal_achievement_id
  end

  def group_players
    goal_achievement ? Player.where(id: goal_achievement.required_player_ids) : player_group.players
  end

  def team
    @team ||= Team.find_by id: team_id if team_id
  end

  def leagues
    (sport ? sport.leagues : League.all).order :name
  end

  def teams
    if season
      campaigns = Campaign.where(season_id: season.id)
      campaigns = campaigns.where(conference_id: conference_id) if conference_id
      campaigns = campaigns.where(division_id: division_id) if division_id
      campaigns = campaigns.where(city_id: city_id) if city_id
      campaigns = campaigns.joins(:city).where(cities: { state_id: state_id }) if state_id
      return Team.where(id: campaigns.select(:team_id))
    end

    scope = Team.joins(:league)
    scope = scope.where(leagues: { sport_id: sport_id }) if sport_id
    scope = scope.where(league_id: league_id) if league_id
    scope = scope.joins(:division).where(divisions: { conference_id: conference_id }) if conference_id
    scope = scope.joins(:division).where(divisions: { id: division_id }) if division_id
    scope = scope.joins(:stadium).where(stadiums: { city_id: city_id }) if city_id
    scope = scope.joins(stadium: :city).where(cities: { state_id: state_id }) if state_id
    scope.distinct
  end

  def selectable_teams
    scope = teams
    if team_query.present?
      scope = scope.matching_name(team_query)
    end
    scope.order(:territory, :mascot).limit(100)
  end

  def selected_team_ids
    team_ids.any? ? team_ids.map(&:to_i) : [ team_id ].compact
  end

  def team_options
    selected = teams.where(id: selected_team_ids).order(:territory, :mascot).to_a
    selected + (selectable_teams.to_a - selected)
  end

  def scoped_teams
    selected_team_ids.any? ? teams.where(id: selected_team_ids) : teams
  end

  def subjects
    return Player.where(id: fact_pool.players.map(&:id)) if %w[multiple_choice image_recognition].include?(game_type)
    return Player.where(id: cipher_pool.players.map(&:id)) if game_type == "name_ciphers"
    return practice_players(filter_players(season_pool.players)) if season && game_type == "player_team_match"

    if game_type == "guess_the_division"
      playable_leagues = Division.joins(:conference).group("conferences.league_id").having("COUNT(DISTINCT divisions.id) >= 2").select("conferences.league_id")
      scope = scoped_teams.joins(:division).where(league_id: playable_leagues)
      if player_group || player_ids.any?
        players = practice_players(filter_players(Player.all, include_inactive: true))
        scope = scope.where(id: players.select(:team_id))
      end
      Team.where(id: scope.select(:id))
    else
      playable_leagues = Team.group(:league_id).having("COUNT(*) >= 2").select(:league_id)
      pool = selected_team_ids.size > 1 ? scoped_teams : scoped_teams.where(league_id: playable_leagues)
      scope = Player.where(team_id: pool.select(:id))
      practice_players(filter_players(scope))
    end
  end

  def fact_pool
    @fact_pool ||= PlayerFactRound.new(players: (season ? filter_players(season_pool.players) : scoped_players).includes(:team, :birth_city, :birth_country).to_a,
      game_type: game_type, fact_type: fact_type, subject_ids: practice_subject_ids, season: season, team_for: season ? season_pool.method(:team_for) : nil)
  end

  def scoped_players
    scope = (player_group || player_ids.any?) && !team_scope? ? Player.all : Player.where(team_id: scoped_teams.select(:id))
    filter_players(scope)
  end

  def review_queue
    @review_queue ||= ReviewQueue.new(ace: ace, teams: [ sport_id, league_id, conference_id, division_id, city_id, state_id, *selected_team_ids ].any? ? scoped_teams : nil, player_id: player_id, players: (player_group || player_ids.any?) ? practice_players(filter_players(Player.all, include_inactive: true)) : nil)
  end

  def available_count
    @available_count ||= if valid?
      case game_type
      when "name_ciphers" then cipher_pool.available_count
      when "multiple_choice", "image_recognition" then fact_pool.available_count
      when "phased_repetition" then review_queue.entries.size
      else subjects.count
      end
    else
      0
    end
  end

  def scope_label
    names = [ ("#{player_ids.size} selected players" if player_ids.any?), player_group&.name, sport&.name, season ? season.name : league&.name ]
    names << Conference.find_by(id: conference_id)&.name if conference_id
    names << Division.find_by(id: division_id)&.name if division_id
    names << City.find_by(id: city_id)&.name if city_id
    names << State.find_by(id: state_id)&.name if state_id
    names << (selected_team_ids.any? ? teams.where(id: selected_team_ids).order(:territory, :mascot).map(&:name).join(" + ") : "Any team")
    names << PRACTICE_FILTERS[practice_filter] if practice_filter != "all"
    names.compact.join " · "
  end

  def question_count
    [ length.to_i, available_count ].min
  end

  def pool_coverage
    return [] unless seasonal_game? && valid?

    players = case game_type
    when "name_ciphers" then cipher_pool.players
    when "multiple_choice", "image_recognition" then fact_pool.players
    else subjects.includes(:team).to_a
    end
    entries = players.group_by { |player| season ? season_pool.team_for(player) : player.team }
      .map { |team, members| { team: team, count: members.size } }
    missing = selected_team_ids - entries.filter_map { |entry| entry.fetch(:team)&.id }
    entries += Team.where(id: missing).map { |team| { team: team, count: 0 } }
    entries.sort_by { |entry| entry.fetch(:team)&.name || "Unassigned players" }
  end

  def scope_params
    fields = attributes.except("team_query").compact
    fields = fields.except("include_inactive") if season_id
    fields = fields.except("practice_filter") if practice_filter == "all"
    team_ids.any? ? fields.except("team_id") : fields
  end

  def preview_question
    return unless valid? && game_type == "player_team_match" && available_count.positive?

    subject = subjects.reorder(Arel.sql("RANDOM()")).first
    question = questions_for([ subject ]).first.deep_stringify_keys
    correct = question.fetch("choices").find { |choice| choice.fetch("id") == question.fetch("target_id") }
    question["choices"] = ((question.fetch("choices") - [ correct ]).sample(3) + [ correct ]).shuffle
    question
  end

  def start!(ace)
    self.ace = ace
    raise ActiveModel::ValidationError, self unless valid?
    if available_count.zero?
      errors.add :base, "No playable questions in this scope. Try another team or league."
      raise ActiveModel::ValidationError, self
    end

    if %w[multiple_choice image_recognition].include?(game_type)
      return save_round!(ace, fact_pool.questions(length: length, balance_teams: selected_team_ids.size > 1))
    end
    if game_type == "phased_repetition"
      return save_round!(ace, review_queue.questions(length: length), label: "Due review · #{scope_label}")
    end

    if game_type == "name_ciphers"
      return save_round!(ace, cipher_pool.questions(length: length, balance_teams: selected_team_ids.size > 1))
    end

    balanced = game_type == "player_team_match" && selected_team_ids.size > 1
    candidates = balanced ? subjects : subjects.reorder(Arel.sql("RANDOM()")).limit(length)
    candidates = game_type == "player_team_match" ? candidates.includes(team: :league) : candidates.includes(:division, :league)
    candidates = candidates.to_a
    if balanced
      candidates = RoundSubjectPicker.pick(candidates, length: length) { |player| season ? season_pool.team_for(player).id : player.team_id }
    end
    save_round! ace, questions_for(candidates)
  end

  def start_misses!(ace, limit: 3)
    misses = PlayProgress.new(ace: ace).misses(limit: limit)
    players = misses.map { |miss| miss.fetch(:player) }
    raise GameRound::InvalidAction, "There are no playable missed names to drill right now." if players.empty?

    recorded = misses.filter_map { |miss| [ miss.fetch(:player).id, miss[:question] ] if miss[:question] }.to_h
    questions = questions_for(players, recorded_questions: recorded).map { |question| question.deep_stringify_keys.reverse_merge("game_type" => "player_team_match") }
    ace.game_rounds.create! game_type: "phased_repetition", length: questions.size, questions: questions,
      scope: { "drill" => true, "include_inactive" => true }, scope_label: "Recent misses", started_at: Time.current, question_started_at: Time.current
  end

  private

  def questions_for(candidates, recorded_questions: {})
    pools = {}
    questions = candidates.map do |subject|
      next recorded_questions.fetch(subject.id) if recorded_questions.key?(subject.id)

      target = season ? season_pool.team_for(subject) : (game_type == "player_team_match" ? subject.team : subject.division)
      question_league = season ? season.league : subject.league
      pool = pools[question_league.id] ||= choice_pool(question_league)
      choices = ((pool - [ target ]).sample(5) + [ target ]).shuffle
      { subject_type: subject.class.name, subject_id: subject.id, subject_name: subject.name,
        team_id: subject.is_a?(Player) ? target.id : subject.id, season_id: season_id,
        target_type: target.class.name, target_id: target.id, target_name: target.name,
        choices: choices.map { |item|
          { id: item.id, name: item.name, abbreviation: item.abbreviation }.tap do |choice|
            if item.is_a?(Team)
              choice.merge!(territory: item.territory, mascot: item.mascot,
                primary_color: item.primary_color, secondary_color: item.secondary_color, text_color: item.text_color)
            end
          end
        } }.tap do |question|
        question[:season_name] = season.name if season
        if subject.is_a?(Player)
          question[:subject_photo_url] = subject.photo_url
          question[:subject_primary_color] = target.primary_color
          question[:subject_secondary_color] = target.secondary_color
          question[:subject_text_color] = target.text_color
          number = JerseyNumberLookup.new(player: subject, team: target, season: season).call
          question[:subject_jersey_number] = number&.number
          question[:subject_jersey_number_on] = number&.observed_on&.iso8601
          question[:subject_position] = subject.current_position unless season
        end
      end
    end
    questions
  end

  def save_round!(ace, questions, scope: scope_params, label: scope_label)
    ace.game_rounds.create! game_type: game_type, length: questions.size, scope: scope, scope_label: label,
      questions: questions, started_at: Time.current, question_started_at: Time.current
  end

  def choice_pool(question_league)
    return question_league.divisions.to_a unless game_type == "player_team_match"

    pool = selected_team_ids.size > 1 ? Team.where(id: selected_team_ids) : question_league.teams
    pool = pool.where(id: Campaign.where(season_id: season_id).select(:team_id)) if season_id
    pool.to_a
  end

  def team_scope?
    [ sport_id, league_id, conference_id, division_id, city_id, state_id, *selected_team_ids ].any?
  end

  def filter_players(scope, include_inactive: self.include_inactive)
    scope = scope.where(id: group_players.select(:id)) if player_group
    scope = scope.where(id: player_id) if player_id
    scope = scope.where(id: player_ids) if player_ids.any?
    scope = scope.where(active: [ true, nil ]) unless season || include_inactive || player_group
    scope
  end

  def practice_subject_ids
    return if practice_filter == "all"
    return [] unless player_group && ace

    @practice_subject_ids ||= begin
      progress = PlayProgress.new(ace: ace, players: group_players)
      case practice_filter
      when "remaining"
        correct_ids = goal_achievement ? goal_achievement.player_ids : progress.correct_player_ids
        group_players.where.not(id: correct_ids).pluck(:id)
      when "missed" then progress.missed_player_ids
      else []
      end
    end
  end

  def practice_players(scope)
    ids = practice_subject_ids
    ids ? scope.where(id: ids) : scope
  end

  def valid_scope
    if practice_filter != "all"
      errors.add(:practice_filter, "requires a player group") unless player_group
      errors.add(:practice_filter, "requires sign-in") unless ace
    end
    if player_ids.any? && (player_ids.size > 30 || player_ids.map(&:to_i).uniq.size != player_ids.size || Player.where(id: player_ids).count != player_ids.size)
      errors.add(:players, "must be between 1 and 30 different recorded players")
    end
    if goal_achievement_id && (!goal_achievement || goal_achievement.achievement.target_type != "PlayerGroup" || goal_achievement.achievement.target_id != player_group_id)
      errors.add(:goal_achievement, "is not an adopted achievement for this group")
    end
    errors.add(:player_group, "is no longer available") if player_group_id && !player_group
    errors.add(:player, "is no longer available") if player_id && !Player.exists?(player_id)
    errors.add(:season, "is no longer available") if season_id && !season
    if season
      errors.add(:season, "is outside the selected league") if league_id && season.league_id != league_id
      errors.add(:season, "is outside the selected sport") if sport_id && season.league.sport_id != sport_id
      errors.add(:season, "is supported for player games only") unless seasonal_game?
      errors.add(:season, "needs at least two recorded teams for answer choices") if game_type == "player_team_match" && teams.count < 2
    end
    errors.add(:sport, "is no longer available") if sport_id && !sport
    errors.add(:league, "is outside the selected sport") if league_id && (!league || (sport_id && league.sport_id != sport_id))
    errors.add(:team, "is outside the selected scope") if team_id && !teams.exists?(team_id)
    errors.add(:conference, "is no longer available") if conference_id && !Conference.exists?(conference_id)
    errors.add(:division, "is no longer available") if division_id && !Division.exists?(division_id)
    errors.add(:city, "is no longer available") if city_id && !City.exists?(city_id)
    errors.add(:state, "is no longer available") if state_id && !State.exists?(state_id)
    if team_ids.any? && (team_ids.map(&:to_i).uniq.size != team_ids.size || team_ids.size > 30 || teams.where(id: team_ids).count != team_ids.map(&:to_i).uniq.size)
      errors.add :base, "Select between 1 and 30 different teams within the selected scope."
    end
  end
end
