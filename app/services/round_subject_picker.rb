# Give each represented team a turn before drawing another player from it.
class RoundSubjectPicker
  def self.pick(subjects, length:, &team_key)
    pool = subjects.uniq(&:id).shuffle
    return pool.take(length) unless team_key

    teams = pool.group_by(&team_key).values.shuffle
    picked = []
    until teams.empty? || picked.size >= length
      teams.each do |players|
        break if picked.size >= length

        picked << players.shift
      end
      teams.reject!(&:empty?)
    end
    picked.shuffle
  end
end
