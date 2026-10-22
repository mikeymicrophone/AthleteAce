class GroupPracticeOverview
  def initialize(groups:, progress:)
    @groups = groups.to_a
    @progress = progress
  end

  def rows
    members = PlayerGroupMembership.where(player_group_id: @groups.map(&:id))
      .pluck(:player_group_id, :player_id).group_by(&:first)
    correct = @progress.correct_player_ids.to_set
    missed = @progress.missed_player_ids.to_set
    @groups.map do |group|
      ids = members.fetch(group.id, []).map(&:last)
      covered = ids.count { |id| correct.include?(id) }
      { group: group, total: ids.size, correct: covered, remaining: ids.size - covered,
        missed: ids.count { |id| missed.include?(id) } }
    end
  end
end
