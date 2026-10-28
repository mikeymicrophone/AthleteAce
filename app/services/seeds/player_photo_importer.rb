module Seeds
  class PlayerPhotoImporter
    def initialize(source:, resolver: LibraryImporter.new)
      @source = Pathname.new(source)
      @resolver = resolver
    end

    def call
      report = { updated: [], unchanged: [], skipped: [] }
      return report unless @source.file?

      Player.transaction do
        JSON.parse(@source.read).fetch("players").each do |entry|
          code = entry.fetch("code")
          player = @resolver.resolve_code("Player", code)
          url = entry.fetch("photo_url")
          unless player && url == "https://cdn.nba.com/headshots/nba/latest/1040x760/#{entry.fetch('source_key')}.png" && entry.fetch("source_key").match?(/\A[0-9]+\z/)
            report[:skipped] << code
            next
          end
          player.with_lock do
            if player.photo_urls == [ url ]
              report[:unchanged] << code
            elsif player.photo_urls.blank?
              player.update!(photo_urls: [ url ])
              report[:updated] << code
            else
              report[:skipped] << code
            end
          end
        end
      end
      report
    end
  end
end
