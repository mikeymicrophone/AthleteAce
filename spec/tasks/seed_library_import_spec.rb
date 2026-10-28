require "rails_helper"
require "rake"
require "tmpdir"

RSpec.describe "seeds:import" do
  it "gives players created by a fresh import their recorded photos" do
    url = "https://cdn.nba.com/headshots/nba/latest/1040x760/1628973.png"
    Dir.mktmpdir("seed-library") do |directory|
      root = Pathname.new(directory)
      library = root.join("yaml")
      library.mkpath
      FileUtils.cp(Rails.root.join("db/seeds/athlete_ace_data/yaml/entity_sequences.yaml"), library)
      library.join("players.yaml").write(YAML.dump("format" => "micharisma-seeds/v1", "namespace" => "MIC", "catalog" => "ALA", "records" => [
        { "type" => "Sport", "code" => "SPORT-BKT", "attributes" => { "name" => "Basketball" } },
        { "type" => "Player", "code" => "BKT-NBA-PLAYER-BRUNSON_JALEN", "attributes" => { "first_name" => "Jalen", "last_name" => "Brunson" },
          "references" => { "sport" => "SPORT-BKT" } }
      ]))
      root.join("sources").mkpath
      root.join("sources/nba_player_photos.json").write(JSON.generate(players: [
        { code: "BKT-NBA-PLAYER-BRUNSON_JALEN", source_key: "1628973", photo_url: url }
      ]))

      Rails.application.load_tasks unless Rake::Task.task_defined?("seeds:import")
      output = StringIO.new
      original_output, original_root = $stdout, ENV["SEED_LIBRARY_ROOT"]
      begin
        $stdout = output
        ENV["SEED_LIBRARY_ROOT"] = library.to_s
        %w[seeds:import seeds:current_teams].each { |name| Rake::Task[name].reenable }
        Rake::Task["seeds:import"].invoke
      ensure
        $stdout = original_output
        ENV["SEED_LIBRARY_ROOT"] = original_root
      end

      expect(Player.find_by!(entity_code: "BKT-NBA-PLAYER-BRUNSON_JALEN").photo_urls).to eq([ url ])
      expect(output.string).to include('{"player_photos":{"updated":0,"unchanged":0,"skipped":1}}', '{"new_player_photos":{"updated":1,"unchanged":0,"skipped":0}}')
    end
  end
end
