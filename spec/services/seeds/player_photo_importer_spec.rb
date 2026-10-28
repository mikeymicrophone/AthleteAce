require "rails_helper"
require "tmpdir"

RSpec.describe Seeds::PlayerPhotoImporter do
  it "fills empty coded photos, preserves existing photos and replays without changes" do
    player = create(:player, entity_code: "BKT-NBA-PLAYER-BRUNSON_JALEN")
    customized = create(:player, entity_code: "BKT-NBA-PLAYER-HART_JOSH", photo_urls: [ "/portraits/josh.jpg" ])
    Dir.mktmpdir do |directory|
      source = Pathname.new(directory).join("photos.json")
      entries = [ [ player.entity_code, "1628973" ], [ customized.entity_code, "1628404" ], [ "BKT-NBA-PLAYER-UNKNOWN", "123" ] ].map do |code, key|
        { code: code, source_key: key, photo_url: "https://cdn.nba.com/headshots/nba/latest/1040x760/#{key}.png" }
      end
      source.write(JSON.generate(players: entries))
      importer = described_class.new(source: source)
      expect { @report = importer.call }.not_to change(Player, :count)
      expect(@report).to eq(updated: [ player.entity_code ], unchanged: [], skipped: [ customized.entity_code, "BKT-NBA-PLAYER-UNKNOWN" ])
      expect(player.reload.photo_urls).to eq([ entries.first[:photo_url] ])
      expect(customized.reload.photo_urls).to eq([ "/portraits/josh.jpg" ])
      expect(importer.call[:updated]).to be_empty
      expect(importer.call[:unchanged]).to eq([ player.entity_code ])
    end
  end
end
