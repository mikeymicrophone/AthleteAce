require "rails_helper"
require "tmpdir"

RSpec.describe Seeds::TeamPaletteImporter do
  around do |example|
    Dir.mktmpdir do |directory|
      @root = Pathname.new(directory)
      example.run
    end
  end

  def write_palette(entries)
    path = @root.join("basketball/USA/NBA/teams.json")
    FileUtils.mkdir_p(path.dirname)
    path.write(JSON.generate(teams: entries))
  end

  it "enriches coded teams, preserves identities, and replays without changes" do
    team = create(:team, entity_code: "BKT-NBA-TEAM-NYK", abbreviation: "NYK")
    uncoded = create(:team, abbreviation: "NYK")
    write_palette([ { abbreviation: "NYK", primary_color: "#006bb6", secondary_color: "#f58426" },
      { abbreviation: "OLD", primary_color: "#000000" } ])
    importer = described_class.new(root: @root)
    expect { @report = importer.call }.not_to change(Team, :count)
    expect(@report).to eq(updated: [ "BKT-NBA-TEAM-NYK" ], unchanged: [], skipped: [ "BKT-NBA-TEAM-OLD" ])
    expect(team.reload.attributes.slice("primary_color", "secondary_color", "text_color")).to eq(
      "primary_color" => "#006BB6", "secondary_color" => "#F58426", "text_color" => "#FFFFFF")
    expect(uncoded.reload.primary_color).to be_nil
    expect(importer.call).to eq(updated: [], unchanged: [ "BKT-NBA-TEAM-NYK" ], skipped: [ "BKT-NBA-TEAM-OLD" ])
  end

  it "skips malformed palettes and does not load palettes from outside the supplied catalog" do
    team = create(:team, entity_code: "BKT-NBA-TEAM-NYK")
    expect(described_class.new(root: @root).call).to eq(updated: [], unchanged: [], skipped: [])
    write_palette([ { abbreviation: "NYK", primary_color: "#FFFFFF", secondary_color: "invalid" } ])
    expect(described_class.new(root: @root).call[:skipped]).to eq([ "BKT-NBA-TEAM-NYK" ])
    expect(team.reload.primary_color).to be_nil
  end
end
