require "rails_helper"
require "tmpdir"

RSpec.describe "People and staff seed imports" do
  def import_records(records)
    Dir.mktmpdir("people-seeds") do |directory|
      path = File.join(directory, "people.yaml")
      File.write(path, YAML.dump({ "format" => "micharisma-seeds/v1", "namespace" => "MIC", "catalog" => "ALA", "records" => records }))
      Seeds::LibraryImporter.new.call([ path ])
    end
  end

  def definition(type, code, attributes, references = {})
    { "type" => type, "code" => code, "attributes" => attributes, "references" => references }
  end

  it "adopts an athlete's identity by profile reference and replays appointments and aliases" do
    player = create :player, first_name: "Jordan", last_name: "Reyes", entity_code: "PLAYER-REYES_JORDAN"
    person = player.person
    records = [
      definition("StaffTenure", "APPOINTMENT-REYES-BROADCAST-2025",
        { "role" => "broadcaster", "title" => "Color commentator", "start_date" => "2025", "ongoing" => true,
          "source" => { "title" => "Broadcast announcement", "url" => "https://example.com/announcements/reyes" } },
        { "person" => "PERSON-REYES_JORDAN", "organization" => "ORGANIZATION-HARBOR_MEDIA" }),
      definition("Person", "PERSON-REYES_JORDAN", { "name" => "Jordan Reyes" }, { "player" => player.entity_code }),
      definition("Organization", "ORGANIZATION-HARBOR_MEDIA", { "name" => "Harbor Sports Network" })
    ]
    report = import_records(records)
    expect(report[:conflicts]).to be_empty
    expect(Person.count).to eq(1)
    expect(StaffTenure.sole.person).to eq(person)
    expect(StaffTenure.sole.start_date).to eq("2025")
    expect(Seeds::LibraryImporter.new.resolve_code("Person", "PERSON-REYES_JORDAN")).to eq(person)
    original_ids = [ person.id, StaffTenure.sole.id ]
    replay = import_records(records.reverse)
    expect(replay[:created]).to be_empty
    expect(replay[:conflicts]).to be_empty
    expect([ Person.sole.id, StaffTenure.sole.id ]).to eq(original_ids)
    expect(EntityCode.find_by!(code: "PERSON-REYES_JORDAN").record).to eq(person)
  end

  it "keeps same-name staff separate and reports conflicting evidence without overwriting it" do
    records = [
      definition("Person", "PERSON-CALDERON_MARIA-COACH", { "name" => "María Calderón" }),
      definition("Person", "PERSON-CALDERON_MARIA-ANALYST", { "name" => "María Calderón" }),
      definition("Organization", "ORGANIZATION-HARBOR", { "name" => "Harbor Athletics" }),
      definition("StaffTenure", "APPOINTMENT-CALDERON-COACH-2024",
        { "role" => "coach", "title" => "Development coach", "start_date" => "2024-09",
          "source" => { "title" => "Staff directory" } },
        { "person" => "PERSON-CALDERON_MARIA-COACH", "organization" => "ORGANIZATION-HARBOR" })
    ]
    import_records(records)
    expect(Person.count).to eq(2)
    expect(Player.count).to eq(0)
    records.last["attributes"]["title"] = "Head coach"
    report = import_records(records)
    expect(report[:conflicts].sole[:differences]["title"]).to eq(existing: "Development coach", incoming: "Head coach")
    expect(StaffTenure.sole.title).to eq("Development coach")
  end
end
