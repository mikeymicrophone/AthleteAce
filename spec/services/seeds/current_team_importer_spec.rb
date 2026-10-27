require "rails_helper"

RSpec.describe Seeds::CurrentTeamImporter do
  let(:league) { create(:league) }
  let(:reds) { create(:team, league: league) }
  let(:cubs) { create(:team, league: league) }
  let(:previous) { create(:season, league: league, year: create(:year, number: 2025)) }
  let(:latest) { create(:season, league: league, year: create(:year, number: 2026)) }

  def list(player, team, season, roster: false)
    campaign = Campaign.find_or_create_by!(team: team, season: season)
    if roster
      Roster.find_or_create_by!(campaign: campaign, kind: "full_season_inventory").roster_entries.create!(player: player)
    else
      Activation.create!(player: player, campaign: campaign)
    end
  end

  it "uses each league's latest rostered season, skips traded players, and preserves existing teams" do
    moved = create(:player, team: nil)
    list moved, reds, previous
    list moved, cubs, latest, roster: true
    departed = create(:player, team: nil)
    list departed, reds, previous
    traded = create(:player, team: nil)
    list traded, reds, latest
    list traded, cubs, latest, roster: true
    kept = create(:player, team: reds)
    list kept, cubs, latest
    create(:season, league: league, year: create(:year, number: 2027))

    report = described_class.new.call
    expect(moved.reload.team).to eq(cubs)
    expect([ departed, traded, kept ].map { |player| player.reload.team_id }).to eq([ nil, nil, reds.id ])
    expect(report[:updated]).to eq([ moved.id ])
    expect(report[:ambiguous]).to eq([ { player_id: traded.id, team_ids: [ reds.id, cubs.id ].sort } ])
    expect(report[:conflicts]).to eq([ { player_id: kept.id, existing: reds.id, incoming: cubs.id } ])

    replay = described_class.new.call
    expect(replay[:updated]).to be_empty
    expect(replay[:unchanged]).to eq([ moved.id ])
  end
end
