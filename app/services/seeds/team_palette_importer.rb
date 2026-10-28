module Seeds
  # The older JSON catalog owns palette metadata. Only enrich coded teams already
  # imported from YAML; never create teams or match identities by name alone.
  class TeamPaletteImporter
    SOURCES = {
      "basketball/USA/NBA/teams.json" => "BKT-NBA",
      "football/USA/NFL/teams.json" => "FTB-NFL",
      "hockey/USA/NHL/teams.json" => "HCK-NHL"
    }.freeze

    def initialize(root: Rails.root.join("db/seeds/athlete_ace_data/sports"), resolver: LibraryImporter.new)
      @root = Pathname.new(root)
      @resolver = resolver
    end

    def call
      report = { updated: [], unchanged: [], skipped: [] }
      Team.transaction do
        SOURCES.each do |relative_path, prefix|
          path = @root.join(relative_path)
          next unless path.file?

          JSON.parse(path.read).fetch("teams").each do |entry|
            code = "#{prefix}-TEAM-#{entry.fetch('abbreviation')}"
            team = @resolver.resolve_code("Team", code)
            primary, secondary = entry.values_at("primary_color", "secondary_color")
            unless team && TeamPalette.valid_color?(primary) && (secondary.nil? || TeamPalette.valid_color?(secondary))
              report[:skipped] << code
              next
            end

            team.assign_attributes(primary_color: primary.upcase, secondary_color: secondary&.upcase,
              text_color: TeamPalette.text_color(primary))
            if team.changed?
              team.save!
              report[:updated] << code
            else
              report[:unchanged] << code
            end
          end
        end
      end
      report
    end
  end
end
