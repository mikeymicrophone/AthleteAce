namespace :seeds do
  def library_paths
    root = Pathname.new(ENV.fetch("SEED_LIBRARY_ROOT", Rails.root.join("db/seeds/athlete_ace_data/yaml").to_s))
    sequence_path = root.join("entity_sequences.yaml")
    paths = Dir.glob(root.join("**/*.{yaml,yml,json}").to_s).sort.reject { |path| Pathname.new(path) == sequence_path }
    raise "No seed files in #{root}" if paths.empty?
    [paths, MICharismaSeeders::SequenceRegistry.read(sequence_path)]
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
  end
end
