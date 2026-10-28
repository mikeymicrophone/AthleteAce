module Seeds
  class HomeVenueImporter
    def initialize(source:, resolver: LibraryImporter.new)
      @source = Pathname.new(source)
      @resolver = resolver
    end

    def call
      report = { updated: [], unchanged: [], conflicts: [] }
      return report unless @source.file?

      ApplicationRecord.transaction do
        JSON.parse(@source.read).fetch("teams").each do |entry|
          team = resolve("Team", entry.fetch("team"))
          campaign = resolve("Campaign", entry.fetch("campaign"))
          season = resolve("Season", entry.fetch("season"))
          stadium = resolve("Stadium", entry.fetch("stadium"))
          city = resolve("City", entry.fetch("city"))
          unless campaign.team == team && campaign.season == season && stadium.city == city
            raise LibraryImporter::Error, "Home venue binding disagrees with its team, season, or city: #{entry.fetch('campaign')}"
          end

          enrich(team, { stadium: stadium }, report)
          enrich(campaign, { stadium: stadium, city: city }, report)
        end
      end
      report
    end

    private

    def resolve(type, code)
      @resolver.resolve_code(type, code) || raise(LibraryImporter::MissingReference, "Missing home venue #{type}: #{code}")
    end

    def enrich(record, associations, report)
      record.lock!
      conflicts = associations.filter_map do |name, incoming|
        current = record.public_send(name)
        [ name, { existing: current.entity_code, incoming: incoming.entity_code } ] if current && current != incoming
      end.to_h
      if conflicts.any?
        report[:conflicts] << { code: record.entity_code, differences: conflicts }
        return
      end

      record.assign_attributes(associations)
      if record.changed?
        record.save!
        report[:updated] << record.entity_code
      else
        report[:unchanged] << record.entity_code
      end
    end
  end
end
