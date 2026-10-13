class GameRoundSetup
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :game_type, :string, default: "player_team_match"
  attribute :length, :integer, default: 10
  attribute :include_inactive, :boolean, default: false
  %i[sport_id league_id season_id conference_id division_id city_id state_id team_id].each { |key| attribute key, :integer }
  attribute :team_ids, default: -> { [] }
  attribute :team_query, :string

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
    return if Player.where(team_id: scoped_teams.select(:id)).exists?
    return @season_suggestion if defined?(@season_suggestion)

    @season_suggestion = nil
    seasons.limit(10).each do |record|
      candidate = self.class.new(scope_params.merge("season_id" => record.id))
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
    %w[player_team_match name_ciphers].include?(game_type)
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
      scope = scope.where(active: [ true, nil ]) unless season || include_inactive
      NameCipherRound.new(players: scope.includes(:team).order(:id).to_a, season: season,
        team_for: season ? season_pool.method(:team_for) : nil)
    end
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
      scope = scope.where("CONCAT(teams.territory, ' ', teams.mascot, ' ', teams.abbreviation) ILIKE ?", "%#{Team.sanitize_sql_like(team_query)}%")
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
    return Player.where(id: cipher_pool.players.map(&:id)) if game_type == "name_ciphers"
    return season_pool.players if season && game_type == "player_team_match"

    if game_type == "guess_the_division"
      playable_leagues = Division.joins(:conference).group("conferences.league_id").having("COUNT(DISTINCT divisions.id) >= 2").select("conferences.league_id")
      Team.where(id: scoped_teams.joins(:division).where(league_id: playable_leagues).select(:id))
    else
      playable_leagues = Team.group(:league_id).having("COUNT(*) >= 2").select(:league_id)
      pool = selected_team_ids.size > 1 ? scoped_teams : scoped_teams.where(league_id: playable_leagues)
      scope = Player.where(team_id: pool.select(:id))
      scope = scope.where(active: [ true, nil ]) unless include_inactive
      scope
    end
  end

  def available_count
    @available_count ||= if valid?
      game_type == "name_ciphers" ? cipher_pool.available_count : subjects.count
    else
      0
    end
  end

  def scope_label
    names = [ sport&.name, season ? season.name : league&.name ]
    names << Conference.find_by(id: conference_id)&.name if conference_id
    names << Division.find_by(id: division_id)&.name if division_id
    names << City.find_by(id: city_id)&.name if city_id
    names << State.find_by(id: state_id)&.name if state_id
    names << (selected_team_ids.any? ? teams.where(id: selected_team_ids).order(:territory, :mascot).map(&:name).join(" + ") : "Any team")
    names.compact.join " · "
  end

  def scope_params
    fields = attributes.except("team_query").compact
    fields = fields.except("include_inactive") if season_id
    team_ids.any? ? fields.except("team_id") : fields
  end

  def start!(ace)
    raise ActiveModel::ValidationError, self unless valid?
    if available_count.zero?
      errors.add :base, "No playable questions in this scope. Try another team or league."
      raise ActiveModel::ValidationError, self
    end

    return save_round!(ace, cipher_pool.questions(length: length)) if game_type == "name_ciphers"

    candidates = subjects.reorder(Arel.sql("RANDOM()")).limit(length)
    candidates = game_type == "player_team_match" ? candidates.includes(team: :league) : candidates.includes(:division, :league)
    candidates = candidates.to_a
    create_round! ace, candidates.cycle.take(length)
  end

  def start_misses!(ace)
    misses = PlayProgress.new(ace: ace).misses
    players = misses.map { |miss| miss.fetch(:player) }
    raise GameRound::InvalidAction, "There are no playable missed names to drill right now." if players.empty?

    recorded = misses.filter_map { |miss| [ miss.fetch(:player).id, miss[:question] ] if miss[:question] }.to_h
    create_round! ace, players, drill: true, recorded_questions: recorded
  end

  private

  def create_round!(ace, candidates, drill: false, recorded_questions: {})
    pools = {}
    questions = candidates.map do |subject|
      next recorded_questions.fetch(subject.id) if recorded_questions.key?(subject.id)

      target = season ? season_pool.team_for(subject) : (game_type == "player_team_match" ? subject.team : subject.division)
      question_league = season ? season.league : subject.league
      pool = pools[question_league.id] ||= choice_pool(question_league)
      choices = ((pool - [ target ]).sample(5) + [ target ]).shuffle
      { subject_type: subject.class.name, subject_id: subject.id, subject_name: subject.name,
        target_type: target.class.name, target_id: target.id, target_name: target.name,
        choices: choices.map { |item| { id: item.id, name: item.name, abbreviation: item.abbreviation } } }.tap do |question|
        question[:season_name] = season.name if season
      end
    end
    label = drill ? "Recent misses · Team Match" : scope_label
    scope = drill ? scope_params.merge("drill" => true, "length" => questions.size) : scope_params
    save_round! ace, questions, scope: scope, label: label
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

  def valid_scope
    errors.add(:season, "is no longer available") if season_id && !season
    if season
      errors.add(:season, "is outside the selected league") if league_id && season.league_id != league_id
      errors.add(:season, "is outside the selected sport") if sport_id && season.league.sport_id != sport_id
      errors.add(:season, "is supported for Team Match and Name Ciphers only") unless seasonal_game?
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
