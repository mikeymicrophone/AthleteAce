# Seasonal membership is independent of a player's current team or active status.
class SeasonTeamMatchPool
  attr_reader :season, :team_ids

  def initialize(season:, team_ids:)
    @season = season
    @team_ids = team_ids
  end

  def players
    Player.where(id: assignments.keys)
  end

  def team_for(player)
    teams.fetch(assignments.fetch(player.id))
  end

  def ambiguous_count
    grouped.count { |_, teams| teams.size > 1 && (teams & team_ids).any? }
  end

  private

  def assignments
    @assignments ||= grouped.filter_map do |player_id, teams|
      [ player_id, teams.first ] if teams.one? && team_ids.include?(teams.first)
    end.to_h
  end

  def teams
    @teams ||= Team.where(id: assignments.values).index_by(&:id)
  end

  def grouped
    @grouped ||= begin
      membership = Activation.joins(:campaign).where(campaigns: { season_id: season.id })
        .select("activations.player_id, campaigns.team_id").to_sql
      connection = ApplicationRecord.connection
      # Newer catalogs can contain roster observations without a legacy Activation.
      if connection.data_source_exists?("roster_entries") && connection.data_source_exists?("rosters")
        roster = "SELECT roster_entries.player_id, campaigns.team_id FROM roster_entries " \
          "INNER JOIN rosters ON rosters.id = roster_entries.roster_id " \
          "INNER JOIN campaigns ON campaigns.id = rosters.campaign_id " \
          "WHERE campaigns.season_id = #{connection.quote(season.id)}"
        membership = "#{membership} UNION #{roster}"
      end
      connection.select_rows("SELECT DISTINCT player_id, team_id FROM (#{membership}) AS memberships")
        .map { |player_id, team_id| [ player_id.to_i, team_id.to_i ] }
        .group_by(&:first).transform_values { |pairs| pairs.map(&:last).uniq }
    end
  end
end
