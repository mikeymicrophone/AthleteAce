require "rails_helper"
require "rake"

RSpec.describe "catalog_edits:export" do
  it "exports each edit as JSONL without changing its reason or applying it to seeds" do
    player = create(:player, first_name: "Jalen", last_name: "Brunson", entity_code: "AA:PLAYER:BRUNSON")
    edit = Admin::EditCatalog.call(record: player, actor: create(:ace, :admin), attributes: { "nicknames" => "JB\nBig Body" },
      version: Admin::EditCatalog.version(player), request_key: SecureRandom.uuid)
    edit.supply_reason!(actor: edit.actor, reason: "Roster lists both nicknames.\nConfirmed by the team.")
    Rails.application.load_tasks unless Rake::Task.task_defined?("catalog_edits:export")
    output, errors = StringIO.new, StringIO.new
    original_output, original_errors = $stdout, $stderr
    begin
      $stdout, $stderr = output, errors
      Rake::Task["catalog_edits:export"].reenable
      Rake::Task["catalog_edits:export"].invoke
    ensure
      $stdout, $stderr = original_output, original_errors
    end
    rows = output.string.lines.map { |line| JSON.parse(line) }
    expect(rows.length).to eq(1)
    expect(rows.first).to include("id" => edit.id, "reason" => edit.reason, "after" => { "nicknames" => [ "JB", "Big Body" ] })
    expect(rows.first["record"]["entity_code"]).to eq("AA:PLAYER:BRUNSON")
    expect(errors.string).to include("Exported 1 catalog edits", "does not mark corrections as incorporated")
    expect(CatalogEdit.sole.reload.reason).to eq(edit.reason)
  end
end
