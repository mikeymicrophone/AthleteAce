class GameRoundSetup
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :game_type, :string, default: "player_team_match"
  attribute :length, :integer, default: 10
  attribute :include_inactive, :boolean, default: false
  %i[sport_id league_id conference_id division_id city_id state_id team_id].each { |key| attribute key, :integer }
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

  def team
    @team ||= Team.find_by id: team_id if team_id
  end

  def leagues
    (sport ? sport.leagues : League.all).order :name
  end

  def teams
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

  def scoped_teams
    scope = teams
    scope = scope.where(id: team_id) if team_id
    scope = scope.where(id: team_ids) if team_ids.any?
    scope
  end

  def subjects
    if game_type == "guess_the_division"
      playable_leagues = Division.joins(:conference).group("conferences.league_id").having("COUNT(DISTINCT divisions.id) >= 2").select("conferences.league_id")
      Team.where(id: scoped_teams.joins(:division).where(league_id: playable_leagues).select(:id))
    else
      playable_leagues = Team.group(:league_id).having("COUNT(*) >= 2").select(:league_id)
      pool = team_ids.any? ? scoped_teams : scoped_teams.where(league_id: playable_leagues)
      scope = Player.where(team_id: pool.select(:id))
      scope = scope.where(active: [true, nil]) unless include_inactive
      scope
    end
  end

  def available_count
    @available_count ||= valid? ? subjects.count : 0
  end

  def scope_label
    names = [sport&.name, league&.name]
    names << Conference.find_by(id: conference_id)&.name if conference_id
    names << Division.find_by(id: division_id)&.name if division_id
    names << City.find_by(id: city_id)&.name if city_id
    names << State.find_by(id: state_id)&.name if state_id
    names << (team&.name || (team_ids.any? ? Team.where(id: team_ids).map(&:name).join(" + ") : "Any team"))
    names.compact.join " · "
  end

  def scope_params
    attributes.except("team_query").compact
  end

  def start! ace
    raise ActiveModel::ValidationError, self unless valid?
    if available_count.zero?
      errors.add :base, "No playable questions in this scope. Try another team or league."
      raise ActiveModel::ValidationError, self
    end

    candidates = subjects.reorder(Arel.sql("RANDOM()")).limit(length)
    candidates = game_type == "player_team_match" ? candidates.includes(team: :league) : candidates.includes(:division, :league)
    candidates = candidates.to_a
    pools = {}
    questions = candidates.cycle.take(length).map do |subject|
      target = game_type == "player_team_match" ? subject.team : subject.division
      pool = pools[subject.league.id] ||= if game_type == "player_team_match"
        team_ids.any? ? Team.where(id: team_ids).to_a : subject.league.teams.to_a
      else
        subject.league.divisions.to_a
      end
      choices = ((pool - [target]).sample(5) + [target]).shuffle
      { subject_type: subject.class.name, subject_id: subject.id, subject_name: subject.name,
        target_type: target.class.name, target_id: target.id, target_name: target.name,
        choices: choices.map { |item| { id: item.id, name: item.name, abbreviation: item.abbreviation } } }
    end
    ace.game_rounds.create! game_type: game_type, length: length, scope: scope_params, scope_label: scope_label,
      questions: questions, started_at: Time.current, question_started_at: Time.current
  end

  private

  def valid_scope
    errors.add(:sport, "is no longer available") if sport_id && !sport
    errors.add(:league, "is outside the selected sport") if league_id && (!league || (sport_id && league.sport_id != sport_id))
    errors.add(:team, "is outside the selected scope") if team_id && !teams.exists?(team_id)
    errors.add(:conference, "is no longer available") if conference_id && !Conference.exists?(conference_id)
    errors.add(:division, "is no longer available") if division_id && !Division.exists?(division_id)
    errors.add(:city, "is no longer available") if city_id && !City.exists?(city_id)
    errors.add(:state, "is no longer available") if state_id && !State.exists?(state_id)
    if team_ids.any? && (team_ids.map(&:to_i).uniq.size < 2 || team_ids.size > 30 || teams.where(id: team_ids).count != team_ids.map(&:to_i).uniq.size)
      errors.add :base, "Select between 2 and 30 available teams for a team-pair drill."
    end
  end
end
