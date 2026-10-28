require "rails_helper"

RSpec.describe "Team visual assets" do
  let(:team) { create(:team) }
  let(:source) { { url: "https://www.nhl.com/blues/team/brand" } }

  it "allows concurrent logos and distinguishes unknown dates from ongoing use" do
    primary = Logo.create!(team: team, name: "Blue Note", role: "primary", start_date: "2025-06-20", ongoing: true, source: source)
    alternate = Logo.create!(team: team, name: "Fleur", role: "alternate", start_date: "2025-06-20", ongoing: true, source: source)
    expect(team.logos).to contain_exactly(primary, alternate)
    expect(Logo.new(team: team, name: "Archive mark", source: source)).to be_valid
    expect(Logo.new(team: team, name: "Invalid period", start_date: "2026-01-01", end_date: "2025-01-01")).not_to be_valid
    primary.end_date = "2026-10-26"
    expect(primary).not_to be_valid
  end

  it "reuses a uniform across seasons and prevents assignment to another team" do
    uniform = Uniform.create!(team: team, name: "Home blue", source: source)
    first = Campaign.create!(team: team, season: create(:season, league: team.league))
    second = Campaign.create!(team: team, season: create(:season, league: team.league))
    uniform.campaigns << first << second
    expect(uniform.campaigns).to contain_exactly(first, second)
    other_team = create(:team)
    other_campaign = Campaign.create!(team: other_team, season: create(:season, league: other_team.league))
    expect(UniformCampaign.new(uniform: uniform, campaign: other_campaign)).not_to be_valid
    expect(uniform.uniform_pieces.create!(name: "sweater").name).to eq("sweater")
    expect(uniform.uniform_pieces.create!(name: "pants").name).to eq("pants")
  end

  it "stores distinct formats and views with one canonical file for each" do
    uniform = Uniform.create!(team: team, name: "Association")
    piece = uniform.uniform_pieces.create!(name: "jersey")
    attributes = { subject: piece, view: "front", canonical_path: "media/pilot/jersey.svg", file_format: "svg", content_type: "image/svg+xml", byte_size: 100, sha256: "a" * 64 }
    AssetRepresentation.create!(attributes)
    expect(AssetRepresentation.new(attributes)).not_to be_valid
    expect(AssetRepresentation.new(attributes.merge(file_format: "png", canonical_path: "media/pilot/jersey.png", content_type: "image/png"))).to be_valid
    expect(AssetRepresentation.new(attributes.merge(view: "back"))).to be_valid
    expect(AssetRepresentation.new(attributes.merge(canonical_path: "media/../../outside.svg"))).not_to be_valid
  end
end
