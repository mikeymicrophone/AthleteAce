namespace :seeds do
  desc "Report captured 2026 coverage and imported season counts"
  task coverage: :environment do
    root = Pathname.new(ENV.fetch("SEED_LIBRARY_ROOT", Rails.root.join("db/seeds/athlete_ace_data/yaml").to_s)).parent
    report = JSON.parse(root.join("sources/coverage_2026/report.json").read)
    report.fetch("coverage").each do |name, capture|
      league = League.find_by!(abbreviation: name.start_with?("nba") ? "NBA" : name.upcase)
      season = league.seasons.find_by!(label: capture.fetch("season"))
      capture["imported_teams"] = season.campaigns.count
      capture["imported_memberships"] = season.activations.count
    end
    report.delete("identity_bindings")
    puts JSON.pretty_generate(report)
  end

  namespace :assets do
    desc "Verify every imported canonical asset file against its size and SHA-256"
    task verify: :environment do
      require "digest"
      root = Pathname.new(ENV.fetch("SEED_LIBRARY_ROOT", Rails.root.join("db/seeds/athlete_ace_data/yaml").to_s)).parent
      count = 0
      AssetRepresentation.find_each do |asset|
        path = asset.local_path(root: root)
        raise "Missing asset: #{path}" unless path.file?
        raise "Asset size differs: #{path}" unless path.size == asset.byte_size
        raise "Asset checksum differs: #{path}" unless Digest::SHA256.file(path).hexdigest == asset.sha256
        count += 1
      end
      raise "No asset representations imported" if count.zero?
      puts "Verified #{count} canonical asset files."
    end
  end

  desc "Apply the captured NHL schedule dates and scheduling details to existing seeded games"
  task refresh_nhl_schedule: :environment do
    root = Pathname.new(ENV.fetch("SEED_LIBRARY_ROOT", Rails.root.join("db/seeds/athlete_ace_data/yaml").to_s)).parent
    capture = JSON.parse(root.join("sources/coverage_2026/nhl.json").read)
    raise "Unexpected NHL season" unless capture.fetch("season") == "2026_2027"
    games = capture.fetch("games")
    raise "Incomplete NHL schedule" unless games.size == 1344 && games.map { |game| game.fetch("source_id") }.uniq.size == 1344
    changed = 0
    Game.transaction do
      games.each do |incoming|
        game = Game.find_by!(entity_code: "HCK-NHL-GAME_#{incoming.fetch('source_id')}")
        expected = { "home" => incoming.fetch("home"), "away" => incoming.fetch("away") }
        actual = game.contestants.includes(:campaign).to_h { |entry| [ entry.tiebreakers.fetch("side"), entry.campaign.abbreviation ] }
        raise "NHL participants changed for #{game.entity_code}" unless actual == expected
        details = game.details.merge(incoming.slice("start_time_utc", "venue", "state"))
        game.assign_attributes(begin_date: incoming.fetch("date"), end_date: incoming.fetch("date"), details: details)
        if game.changed?
          game.save!
          changed += 1
        end
      end
    end
    puts({ games: games.size, changed: changed }.to_json)
  end

  desc "Export the live catalog field contract for portable schema generation (CHECK=1 verifies drift)"
  task schema_contract: :environment do
    require Rails.root.join("app/services/seeds/library_importer").to_s
    path = Rails.root.join("db/seeds/athlete_ace_data/schemas/ala.contract.json")
    contents = JSON.pretty_generate(Seeds::CatalogContract.document) + "\n"
    if ENV["CHECK"] == "1"
      raise "Stale catalog contract: #{path}" unless path.file? && path.read == contents
      puts "Published catalog contract matches the live adapter."
    else
      FileUtils.mkdir_p(path.dirname)
      path.write(contents)
      puts "Exported #{path}"
    end
  end

  def library_paths
    root = Pathname.new(ENV.fetch("SEED_LIBRARY_ROOT", Rails.root.join("db/seeds/athlete_ace_data/yaml").to_s))
    sequence_path = root.join("entity_sequences.yaml")
    paths = Dir.glob(root.join("**/*.{yaml,yml,json}").to_s).sort.reject { |path| Pathname.new(path) == sequence_path }
    raise "No seed files in #{root}" if paths.empty?
    [ paths, MICharismaSeeders::SequenceRegistry.read(sequence_path) ]
  end

  desc "Validate JSON/YAML seed envelopes and optional sequence configuration"
  task validate: :environment do
    require Rails.root.join("app/services/seeds/library_importer").to_s
    paths, registry = library_paths
    puts Seeds::LibraryImporter.new(registry: registry).validate(paths).to_json
  end

  desc "Import the scoped seed library while preserving existing catalog values"
  task import: :environment do
    require Rails.root.join("app/services/seeds/library_importer").to_s
    paths, registry = library_paths
    root = Pathname.new(ENV.fetch("SEED_LIBRARY_ROOT", Rails.root.join("db/seeds/athlete_ace_data/yaml").to_s))
    # Fill photos on existing players before the library compares values, then
    # again for players the library has just created.
    photos = Seeds::PlayerPhotoImporter.new(source: root.parent.join("sources/nba_player_photos.json"))
    puts({ player_photos: photos.call.transform_values(&:length) }.to_json)
    report = Seeds::LibraryImporter.new(registry: registry).call(paths)
    puts report.transform_values(&:length).to_json
    report[:conflicts].each { |conflict| puts conflict.to_json }
    puts({ new_player_photos: photos.call.transform_values(&:length) }.to_json)
    # A custom YAML library may have its own sibling sports catalog. Do not apply
    # the default catalog's palettes to an unrelated library.
    palettes = Seeds::TeamPaletteImporter.new(root: root.parent.join("sports")).call
    puts({ team_palettes: palettes.transform_values(&:length) }.to_json)
    venues = Seeds::HomeVenueImporter.new(source: root.parent.join("sources/geography_2026/bindings.json")).call
    puts({ home_venues: venues.transform_values(&:length) }.to_json)
    venues[:conflicts].each { |conflict| puts conflict.to_json }
    Rake::Task["seeds:current_teams"].invoke
  end

  desc "Assign players the team they are listed with in their league's latest rostered season"
  task current_teams: :environment do
    report = Seeds::CurrentTeamImporter.new.call
    puts({ current_teams: report.transform_values(&:length) }.to_json)
    report[:conflicts].each { |conflict| puts conflict.to_json }
  end
end
