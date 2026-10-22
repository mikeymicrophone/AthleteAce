class PlayerFactRound
  attr_reader :players

  def initialize(players:, game_type:, fact_type:, season: nil, team_for: nil, subject_ids: nil)
    @season, @team_for = season, team_for
    @game_type = game_type
    @fact_type = fact_type
    @players = players.select { |player| target_for(player) && (game_type != "image_recognition" || player.photo_url.present?) }
    @players = @players.uniq { |player| player.name.squish.downcase } if game_type == "image_recognition"
    @targets = @players.map { |player| target_for(player) }.uniq(&:id)
    @players = @players.select { |player| subject_ids.include?(player.id) } if subject_ids
  end

  def available_count
    @targets.size >= 2 ? players.size : 0
  end

  def questions(length:, balance_teams: false)
    key = balance_teams ? ->(player) { team_for(player)&.id } : nil
    RoundSubjectPicker.pick(players, length: length, &key).map do |player|
      target = target_for(player)
      choices = ((@targets - [ target ]).sample(3) + [ target ]).shuffle
      { subject_type: "Player", subject_id: player.id, subject_name: player.name,
        target_type: target.class.name, target_id: target.id, target_name: target.name,
        game_type: @game_type, fact_type: @fact_type, team_id: team_for(player)&.id, team_name: team_for(player)&.name,
        season_id: @season&.id, season_name: @season&.name,
        subject_photo_url: player.photo_url,
        choices: choices.map { |choice| { id: choice.id, name: choice.name } } }
    end
  end

  private

  def team_for(player)
    @team_for ? @team_for.call(player) : player.team
  end

  def target_for(player)
    return player if @game_type == "image_recognition"

    return team_for(player) if @fact_type == "team"

    player.public_send(GameRoundSetup::FACTS.fetch(@fact_type).last)
  end
end
