class JerseyNumberLookup
  Result = Data.define(:number, :observed_on)

  def initialize(player:, team:, on: Date.current, season: nil)
    @player, @team, @on, @season = player, team, on, season
  end

  def call
    return unless @player && @team

    assignments = JerseyNumberAssignment.where(player: @player, team: @team)
    if @season
      return unless @season.league_id == @team.league_id || @season.campaigns.exists?(team: @team)
      from, through = @season.start_date, @season.playoff_end_date || @season.end_date
      # A season label/year alone cannot place a dated assignment in time.
      assignments = if from && through
        assignments.overlapping(from, through).to_a
      else
        assignments.where(start_date: nil, end_date: nil).to_a
      end
      observations = observed_numbers
      numbers = (assignments.map(&:number) + observations.map(&:first)).uniq
      return unless numbers.one?

      if assignments.any? { |assignment| assignment.covers?(from, through) }
        Result.new(number: numbers.first, observed_on: nil)
      elsif observations.any?
        Result.new(number: numbers.first, observed_on: observations.map(&:last).compact.max)
      end
    else
      assignments = assignments.overlapping(@on, @on).to_a
      observations = observed_numbers
      numbers = (assignments.map(&:number) + observations.map(&:first)).uniq
      return unless numbers.one?

      Result.new(number: numbers.first, observed_on: assignments.any? ? nil : @on)
    end
  end

  private

  def observed_numbers
    connection = ApplicationRecord.connection
    observations = []
    if connection.data_source_exists?("roster_entries") && connection.data_source_exists?("rosters")
      entries = RosterEntry.joins(roster: :campaign).where(player: @player, campaigns: { team_id: @team.id })
      entries = @season ? entries.where(campaigns: { season_id: @season.id }) : entries.where(rosters: { effective_on: @on })
      observations += entries.pluck(:jersey_number, "rosters.effective_on")
    end
    if connection.data_source_exists?("appearances")
      entries = Appearance.joins(contestant: [ :campaign, :contest ]).where(player: @player, campaigns: { team_id: @team.id })
      entries = @season ? entries.where(campaigns: { season_id: @season.id }) : entries.where(contests: { begin_date: @on })
      observations += entries.pluck(:jersey_number, "contests.begin_date").map { |number, date| [ number, date&.to_date ] }
    end
    observations.select { |number, _| JerseyNumberAssignment.valid_number?(number) }
  end
end
