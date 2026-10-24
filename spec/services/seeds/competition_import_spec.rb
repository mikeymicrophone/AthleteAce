require "rails_helper"
require "tmpdir"

RSpec.describe "Competition seed import" do
  it "imports a federation-owned cup and fixture without tying them to a league season" do
    Dir.mktmpdir do |directory|
      path = File.join(directory, "fa-cup.json")
      File.write(path, JSON.generate(format: "micharisma-seeds/v1", namespace: "MIC", catalog: "ALA", records: [
        { type: "Federation", code: "FA", attributes: { name: "The Football Association" } },
        { type: "Contest", code: "FA-CUP-2026", attributes: { name: "2026 FA Cup", kind: "tournament" }, references: { context: "FA" } },
        { type: "Game", code: "FA-CUP-FINAL-2026", attributes: { name: "FA Cup final" }, references: { context: "FA" } },
        { type: "ContestGame", code: "FA-CUP-FINAL-LINK", attributes: { metadata: { round: "final" } }, references: { contest: "FA-CUP-2026", game: "FA-CUP-FINAL-2026" } }
      ]))
      report = Seeds::LibraryImporter.new.call([ path ])
      expect(report[:created].size).to eq(4)
      cup = Contest.competitions.find_by!(entity_code: "FA-CUP-2026")
      expect(cup.context).to eq(Federation.find_by!(entity_code: "FA"))
      expect(cup.season).to be_nil
      expect(cup.games.sole.name).to eq("FA Cup final")
      expect(Seeds::LibraryImporter.new.call([ path ])[:created]).to be_empty
    end
  end

  it "imports rules, a shared Game, memberships and a title with semantic references and replays without duplicates" do
    league = create(:league, name: "MLS", entity_code: "MLS")
    EntityCode.create!(namespace: "MIC", catalog: "ALA", code: "MLS", canonical_code: "MLS", record: league)
    team = create(:team, league: league, territory: "Miami", mascot: "Inter")
    campaign = Campaign.create!(team: team, season: create(:season, league: league), entity_code: "MIAMI-2026")
    records = [
      { type: "Contest", code: "MLS-PLAYOFFS-2026", attributes: { name: "MLS Cup Playoffs", kind: "playoffs", format_rules: { rounds: [ { key: "final", best_of: 1 } ] } }, references: { context: "MLS" } },
      { type: "Contest", code: "MLS-TABLE-2026", attributes: { name: "MLS regular season", kind: "regular_season" }, references: { context: "MLS" } },
      { type: "Contestant", code: "MIAMI-PLAYOFFS", references: { contest: "MLS-PLAYOFFS-2026", campaign: "MIAMI-2026" } },
      { type: "Contestant", code: "MIAMI-TABLE", references: { contest: "MLS-TABLE-2026", campaign: "MIAMI-2026" } },
      { type: "Game", code: "MIAMI-FINAL", attributes: { name: "Miami cup final", details: { venue: "Miami" } }, references: { context: "MLS" } },
      { type: "Contestant", code: "MIAMI-FINAL-ENTRY", references: { contest: "MIAMI-FINAL", campaign: "MIAMI-2026" } },
      { type: "ContestGame", code: "MLS-PLAYOFF-FINAL", attributes: { metadata: { round: "final", game_number: 1 } }, references: { contest: "MLS-PLAYOFFS-2026", game: "MIAMI-FINAL" } },
      { type: "ContestGame", code: "MLS-TABLE-GAME", attributes: { metadata: { matchweek: 34 } }, references: { contest: "MLS-TABLE-2026", game: "MIAMI-FINAL" } },
      { type: "TitleAward", code: "MLS-CUP-2026", attributes: { key: "mls_cup", name: "MLS Cup" }, references: { contest: "MLS-PLAYOFFS-2026", winner: "MIAMI-PLAYOFFS" } }
    ]
    Dir.mktmpdir do |directory|
      path = File.join(directory, "competitions.json")
      File.write(path, JSON.generate(format: "micharisma-seeds/v1", namespace: "MIC", catalog: "ALA", records: records))
      importer = Seeds::LibraryImporter.new
      result = importer.call([ path ])
      expect(result[:created].size).to eq(9)
      game = Game.find_by!(entity_code: "MIAMI-FINAL")
      expect(game.competitions.count).to eq(2)
      expect(game.contestants.sole.campaign).to eq(campaign)
      expect(TitleAward.sole.team).to eq(team)
      expect(EntityCode.find_by!(code: "MIAMI-FINAL").record_type).to eq("Contest")
      replay = Seeds::LibraryImporter.new.call([ path ])
      expect(replay[:created]).to be_empty
      expect(replay[:conflicts]).to be_empty
      expect(Game.count).to eq(1)
      records[6][:attributes][:metadata][:round] = "missing_round"
      records[6][:code] = "INVALID-MEMBERSHIP"
      records[6][:references][:game] = "ANOTHER-GAME"
      records << { type: "Game", code: "ANOTHER-GAME", attributes: { name: "Another fixture" }, references: { context: "MLS" } }
      File.write(path, JSON.generate(format: "micharisma-seeds/v1", namespace: "MIC", catalog: "ALA", records: records))
      expect { Seeds::LibraryImporter.new.call([ path ]) }.to raise_error(ActiveRecord::RecordInvalid, /round/)
      expect(Game.count).to eq(1)
    end
  end

  it "continues importing legacy game definitions and resolves them through the Game model" do
    league = create(:league, entity_code: "NBA")
    EntityCode.create!(namespace: "MIC", catalog: "ALA", code: "NBA", canonical_code: "NBA", record: league)
    Dir.mktmpdir do |directory|
      path = File.join(directory, "legacy-game.json")
      File.write(path, JSON.generate(format: "micharisma-seeds/v1", namespace: "MIC", catalog: "ALA", records: [
        { type: "Contest", code: "NBA-OPENER", attributes: { name: "Opening game", kind: "game" }, references: { context: league.entity_code } }
      ]))
      importer = Seeds::LibraryImporter.new
      importer.call([ path ])
      game = importer.resolve_code("Game", "NBA-OPENER")
      expect(game).to be_a(Game)
      expect(importer.resolve_code("Contest", "NBA-OPENER")).to eq(game)
      expect(Seeds::LibraryImporter.new.call([ path ])[:conflicts]).to be_empty
    end
  end
end
