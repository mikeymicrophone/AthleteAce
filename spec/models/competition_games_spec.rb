require "rails_helper"

RSpec.describe "Competition games and titles" do
  let(:league) { create(:league, name: "MLS") }
  let(:season) { create(:season, league: league) }
  let(:team) { create(:team, league: league, territory: "Miami", mascot: "Inter", abbreviation: "MIA") }
  let(:campaign) { Campaign.create!(team: team, season: season) }
  let(:competition) { Contest.create!(name: "MLS playoffs", kind: "playoffs", context: league, season: season,
    format_rules: { "rounds" => [ { "key" => "first_round", "best_of" => 3 }, { "key" => "final", "best_of" => 1 } ] }) }

  def enter_and_schedule(contest = competition)
    entry = Contestant.create!(contest: contest, campaign: campaign)
    game = Game.create!(name: "Miami playoff opener", context: league, season: season, begin_date: Date.new(2026, 11, 1))
    Contestant.create!(contest: game, campaign: campaign)
    [ entry, game, ContestGame.create!(contest: contest, game: game, metadata: { "round" => "first_round", "game_number" => 1 }) ]
  end

  it "gives games a model while retaining legacy Contest identities and appearance links" do
    legacy = Contest.create!(name: "Miami opener", kind: "game", context: league)
    participant = Contestant.create!(contest: legacy, campaign: campaign)
    player = create(:player, first_name: "Lionel", last_name: "Messi", team: nil, sport: league.sport)
    appearance = Appearance.create!(player: player, contestant: participant, statistics: { "goals" => 1 })
    game = Game.find(legacy.id)
    expect(game.kind).to eq("game")
    expect(game.appearances.sole.id).to eq(appearance.id)
    expect(Contest.find(legacy.id)).to be_a(Game)
    expect(Contest.competitions).not_to include(game)
    expect(Game.columns_hash["details"].type).to eq(:jsonb)
  end

  it "stores a game once while giving it different round metadata in separate competitions" do
    _, game, membership = enter_and_schedule
    table = Contest.create!(name: "MLS regular season", kind: "regular_season", context: league, season: season)
    Contestant.create!(contest: table, campaign: campaign)
    second = ContestGame.create!(contest: table, game: game, metadata: { "matchweek" => 32 })
    expect(game.competitions).to match_array([ competition, table ])
    expect(game.competition_memberships.count).to eq(2)
    expect(Game.count).to eq(1)
    expect(ContestGame.where("metadata @> ?::jsonb", { round: "first_round" }.to_json)).to eq([ membership ])
    expect(second.metadata).to eq("matchweek" => 32)
    expect(ContestGame.new(contest: competition, game: game)).not_to be_valid
  end

  it "accepts cross-league cup entries without creating additional team-season campaigns" do
    other_league = create(:league, name: "Liga MX", sport: league.sport)
    other_team = create(:team, league: other_league, territory: "Mexico City", mascot: "América")
    other_campaign = Campaign.create!(team: other_team, season: create(:season, league: other_league))
    organizer = Organization.create!(name: "Leagues Cup")
    cup = Contest.create!(name: "2026 Leagues Cup", kind: "tournament", context: organizer)
    [ campaign, other_campaign ].each { |entrant| Contestant.create!(contest: cup, campaign: entrant) }
    game = Game.create!(name: "Miami v América", context: organizer)
    [ campaign, other_campaign ].each { |entrant| Contestant.create!(contest: game, campaign: entrant) }
    ContestGame.create!(contest: cup, game: game, metadata: { "round" => "group_stage", "group" => "A" })
    expect(cup.leagues).to match_array([ league, other_league ])
    expect(cup.games.sole).to eq(game)
    expect(Campaign.count).to eq(2)
    expect { cup.update!(season: season) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "allows extra JSON fields and validates only the operational round and best-of fields" do
    competition.update!(format_rules: { "rounds" => [ { "key" => "final", "best_of" => 7, "home_advantage" => { "policy" => "higher_seed" } } ], "future_rule" => [ 1, true, nil ] })
    expect(competition.format_rules["future_rule"]).to eq([ 1, true, nil ])
    [ {}, { "rounds" => [] } ].each { |rules| expect(competition.update(format_rules: rules)).to be(true) }
    [ nil, [], { "rounds" => {} }, { "rounds" => [ "final" ] }, { "rounds" => [ { "key" => "final", "best_of" => "seven" } ] },
      { "rounds" => [ { "key" => "final" }, { "key" => "final" } ] } ].each do |rules|
      expect(competition.update(format_rules: rules)).to be(false)
    end
  end

  it "rejects unknown rounds, bad JSON shapes and deletion of referenced round definitions" do
    _, game, membership = enter_and_schedule
    expect(membership.update(metadata: { "round" => "semifinal" })).to be(false)
    expect(membership.update(metadata: [])).to be(false)
    expect(membership.update(metadata: { "round" => "final", "game_number" => 0 })).to be(false)
    expect(membership.update(metadata: { "round" => "final", "leg" => "2" })).to be(false)
    expect(membership.update(metadata: { "round" => "final", "series" => [] })).to be(false)
    expect(competition.update(format_rules: { "rounds" => [ { "key" => "final" } ] })).to be(false)
    expect(competition.update(format_rules: {})).to be(false)
    expect(ContestGame.new(contest: game, game: game)).not_to be_valid
    expect(competition.update(kind: "game")).to be(false)
    expect(game.update(kind: "tournament")).to be(false)
  end

  it "requires game participants to be entered and preserves those entries while games use them" do
    entry, game, membership = enter_and_schedule
    stranger = Campaign.create!(team: create(:team, league: league), season: season)
    expect(Contestant.new(contest: game, campaign: stranger)).not_to be_valid
    expect(entry.update(campaign: stranger)).to be(false)
    expect(entry.reload.update(contest: Game.create!(name: "Another fixture", context: league))).to be(false)
    expect(entry.reload.destroy).to be(false)
    other = Contest.create!(name: "Cup", context: league)
    expect(ContestGame.new(contest: other, game: game)).not_to be_valid
    membership.destroy!
    expect(entry.destroy).to be_truthy
  end

  it "rejects campaign season changes that would invalidate a competition's entered season" do
    enter_and_schedule
    expect(campaign.update(season: create(:season, league: league))).to be(false)
    expect(campaign.errors[:season]).to be_present
  end

  it "awards distinct regular-season and playoff titles and constrains the winning entry" do
    entry, _, = enter_and_schedule
    table = Contest.create!(name: "MLS table", context: league, season: season)
    table_entry = Contestant.create!(contest: table, campaign: campaign)
    cup = TitleAward.create!(contest: competition, winner: entry, key: "mls_cup", name: "MLS Cup")
    shield = TitleAward.create!(contest: table, winner: table_entry, key: "supporters_shield", name: "Supporters' Shield")
    expect([ cup.team, shield.team ]).to eq([ team, team ])
    expect(team.title_awards).to match_array([ cup, shield ])
    expect(TitleAward.new(contest: table, winner: entry, key: "wrong", name: "Wrong winner")).not_to be_valid
    expect(TitleAward.new(contest: competition, winner: entry, key: "mls_cup", name: "Duplicate")).not_to be_valid
    expect(entry.update(campaign: Campaign.create!(team: create(:team, league: league), season: season))).to be(false)
    expect { cup.update_columns(winner_id: table_entry.id) }.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "removes a competition and its memberships and awards without deleting shared games" do
    entry, game, = enter_and_schedule
    TitleAward.create!(contest: competition, winner: entry, key: "mls_cup", name: "MLS Cup")
    competition.destroy!
    expect(Game.find(game.id)).to be_present
    expect(ContestGame.count).to eq(0)
    expect(TitleAward.count).to eq(0)
  end
end
