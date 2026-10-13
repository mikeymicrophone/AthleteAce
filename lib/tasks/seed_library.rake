namespace :seeds do
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
    report = Seeds::LibraryImporter.new(registry: registry).call(paths)
    puts report.transform_values(&:length).to_json
    report[:conflicts].each { |conflict| puts conflict.to_json }
    # A custom YAML library may have its own sibling sports catalog. Do not apply
    # the default catalog's palettes to an unrelated library.
    root = Pathname.new(ENV.fetch("SEED_LIBRARY_ROOT", Rails.root.join("db/seeds/athlete_ace_data/yaml").to_s))
    palettes = Seeds::TeamPaletteImporter.new(root: root.parent.join("sports")).call
    puts({ team_palettes: palettes.transform_values(&:length) }.to_json)
  end
end
