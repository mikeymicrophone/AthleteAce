module Seeds
  # Give each player the team they are listed with in their league's latest
  # rostered season. Full-season rosters keep departed players, so a player
  # listed with several teams that season stays unassigned. Existing teams are
  # preserved and differences reported, like the rest of the seed replay.
  class CurrentTeamImporter
    def call
      report = { updated: [], unchanged: [], ambiguous: [], conflicts: [] }
      existing = Player.where(id: memberships.keys).pluck(:id, :team_id).to_h
      assignments = Hash.new { |hash, team_id| hash[team_id] = [] }

      memberships.each do |player_id, team_ids|
        if team_ids.many?
          report[:ambiguous] << { player_id: player_id, team_ids: team_ids }
        elsif existing[player_id].nil?
          assignments[team_ids.first] << player_id
        elsif existing[player_id] == team_ids.first
          report[:unchanged] << player_id
        else
          report[:conflicts] << { player_id: player_id, existing: existing[player_id], incoming: team_ids.first }
        end
      end

      ApplicationRecord.transaction do
        assignments.each do |team_id, player_ids|
          Player.where(id: player_ids, team_id: nil).update_all(team_id: team_id, updated_at: Time.current)
          report[:updated].concat player_ids
        end
      end
      report
    end

    private

    def memberships
      @memberships ||= begin
        listed = "#{Activation.joins(:campaign).select('activations.player_id, campaigns.team_id, campaigns.season_id').to_sql} UNION " \
          "#{RosterEntry.joins(roster: :campaign).select('roster_entries.player_id, campaigns.team_id, campaigns.season_id').to_sql}"
        latest = Season.joins(:year).where("seasons.id IN (SELECT season_id FROM (#{listed}) AS listed)")
          .select("DISTINCT ON (seasons.league_id) seasons.id").order("seasons.league_id, years.number DESC, seasons.id DESC")
        ApplicationRecord.connection.select_rows("SELECT DISTINCT player_id, team_id FROM (#{listed}) AS listed WHERE season_id IN (#{latest.to_sql}) ORDER BY player_id, team_id")
          .map { |row| row.map(&:to_i) }.group_by(&:first).transform_values { |rows| rows.map(&:last) }
      end
    end
  end
end
