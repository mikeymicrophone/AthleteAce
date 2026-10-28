namespace :catalog_edits do
  desc "Export the catalog correction log as JSONL to stdout"
  task export: :environment do
    count = 0
    CatalogEdit.find_each do |edit|
      puts JSON.generate(edit.export_entry)
      count += 1
    end
    warn "Exported #{count} catalog edits. Export does not mark corrections as incorporated into seeds."
  end
end
