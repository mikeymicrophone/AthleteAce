class QuickRound
  def initialize(ace:)
    @ace = ace
  end

  def start!
    if ReviewQueue.new(ace: @ace).entries.any?
      return GameRoundSetup.new(game_type: "phased_repetition", include_inactive: true).start!(@ace)
    end
    if PlayProgress.new(ace: @ace).misses.any?
      return GameRoundSetup.new(include_inactive: true).start_misses!(@ace, limit: 10)
    end

    setup = followed_players_setup || preferred_teams_setup
    setup.start!(@ace)
  end

  private

  def followed_players_setup
    ids = @ace.follows.where(followable_type: "Player").order(created_at: :desc, id: :desc).limit(30).pluck(:followable_id)
    return if ids.empty?

    setup = GameRoundSetup.new(player_ids: ids, include_inactive: true)
    return setup if setup.available_count.positive?
    return setup.season_suggestion if setup.season_suggestion

    ciphers = GameRoundSetup.new(game_type: "name_ciphers", player_ids: ids, include_inactive: true)
    ciphers if ciphers.available_count.positive?
  end

  def preferred_teams_setup
    affinity = @ace.ratings.active.where(target_type: "Team", spectrum: Spectrum.approved.where(name: "Affinity"))
      .where("value >= 5000").order(value: :desc).limit(30).pluck(:target_id)
    following = @ace.follows.where(followable_type: "Team").order(created_at: :desc, id: :desc).limit(30).pluck(:followable_id)
    setup = GameRoundSetup.new(team_ids: (following + affinity).uniq.first(30))
    setup = setup.season_suggestion || GameRoundSetup.new if setup.available_count.zero?
    setup = setup.season_suggestion if setup.available_count.zero? && setup.season_suggestion
    setup
  end
end
