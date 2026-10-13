# Build a stable puzzle and name choices before the round starts.
class NameCipherRound
  attr_reader :players

  def initialize(players:, season: nil, team_for: nil)
    @players = players.select { |player| player.name.upcase.scan(/\p{L}/).uniq.size > 1 }
      .uniq { |player| player.name.squish.downcase }
    @season = season
    @team_for = team_for
  end

  def available_count
    players.size > 1 ? players.size : 0
  end

  def questions(length:, balance_teams: false)
    team_key = balance_teams ? ->(player) { team_for(player)&.id } : nil
    RoundSubjectPicker.pick(players, length: length, &team_key).map do |player|
      choices = ((players - [ player ]).sample(3) + [ player ]).shuffle
      team = team_for(player)
      { subject_type: "Player", subject_id: player.id, subject_name: player.name,
        target_type: "Player", target_id: player.id, target_name: player.name,
        scrambled_name: scramble(player.name), team_id: team&.id, team_name: team&.name,
        season_name: @season&.name,
        choices: choices.map { |choice| { id: choice.id, name: choice.name } } }.compact
    end
  end

  private

  def team_for(player)
    @team_for ? @team_for.call(player) : player.team
  end

  def scramble(name)
    characters = name.upcase.chars
    letters = characters.grep(/\p{L}/)
    shuffled = letters.shuffle
    shuffled = letters.rotate if shuffled == letters
    characters.map { |character| character.match?(/\p{L}/) ? shuffled.shift : character }.join
  end
end
