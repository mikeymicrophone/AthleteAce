module ParticipationValidation
  extend ActiveSupport::Concern

  private

  def validate_player_sport(team)
    return unless player&.sport_id && team&.league
    errors.add :player, "must belong to the team's sport" if player.sport_id != team.league.sport_id
  end

  def validate_linked_stint(team, date)
    return unless stint
    errors.add :stint, "must belong to the player" if stint.player != player
    errors.add :stint, "must belong to the participating team" if team && stint.team != team
    errors.add :stint, "must include the known participation date" unless stint.permits_date?(date)
  end
end
