module Admin
  class EditCatalog
    class Forbidden < StandardError; end
    class Conflict < StandardError; end

    MODELS = { "players" => Player, "teams" => Team }.freeze
    FIELDS = {
      "Player" => %w[first_name last_name nicknames birthdate current_position debut_year draft_year active bio photo_urls],
      "Team" => %w[territory mascot abbreviation founded_year url logo_url primary_color secondary_color]
    }.freeze
    ARRAYS = %w[nicknames bio photo_urls].freeze
    YEARS = %w[debut_year draft_year founded_year].freeze

    def self.model_for(kind)
      MODELS.fetch(kind) { raise ActiveRecord::RecordNotFound }
    end

    def self.version(record)
      Digest::SHA256.hexdigest(record.attributes.to_json)
    end

    def self.call(record:, actor:, attributes:, version:, request_key:)
      submitted = normalize(record, attributes)
      raise ArgumentError, "Invalid edit request key." unless request_key.is_a?(String) && request_key.length.between?(1, 128)
      actor.with_lock do
        raise Forbidden, "An active admin must edit sports data." unless actor.admin? && actor.active_for_authentication?
        record.with_lock do
          existing = CatalogEdit.find_by(actor: actor, request_key: request_key)
          if existing
            unless existing.record_type == record.class.name && existing.record_id == record.id && existing.submitted_values == submitted
              raise Conflict, "This request key was already used for a different edit. Reload before saving."
            end
            return existing
          end
          raise Conflict, "This record changed while you were editing. Reload before saving." unless version == self.version(record)
          name = record.name
          record.assign_attributes(submitted)
          raise ArgumentError, "Supply at least one part of the name." if (record.is_a?(Player) ? [ record.first_name, record.last_name ] : [ record.territory, record.mascot ]).all?(&:blank?)
          return if record.changes.except("updated_at").empty?
          record.save!
          changes = record.saved_changes.except("updated_at")
          CatalogEdit.create!(actor: actor, actor_name: "#{actor.public_name} #{actor.handle}", record_type: record.class.name,
            record_id: record.id, entity_code: record.entity_code, record_name: name,
            before_values: changes.transform_values(&:first), after_values: changes.transform_values(&:last),
            submitted_values: submitted, request_key: request_key)
        end
      end
    end

    def self.create_player(actor:, attributes:, entity_code:, sport_id:, request_key:)
      submitted = normalize(Player.new, attributes)
      raise ArgumentError, "Invalid edit request key." unless request_key.is_a?(String) && request_key.length.between?(1, 128)
      raise ArgumentError, "Supply a local entity code of up to 120 letters, digits, underscores and hyphen-separated parts." unless entity_code.is_a?(String) && entity_code.strip.length.between?(1, 120) && entity_code.strip.match?(/\A[A-Za-z0-9_]+(?:-[A-Za-z0-9_]+)*\z/)
      code = entity_code.strip
      raise ArgumentError, "Use a local code without the MIC-ALA- prefix." if code.start_with?("MIC-ALA-")
      raise ArgumentError, "Choose a sport." unless sport_id.nil? || (sport_id.is_a?(String) && (sport_id.blank? || sport_id.match?(/\A[1-9]\d{0,17}\z/)))
      sport = sport_id.present? ? Sport.find_by(id: sport_id) : nil
      raise ArgumentError, "Choose an existing sport." if sport_id.present? && !sport
      submitted = { "operation" => "create_player", "attributes" => submitted, "entity_code" => code, "sport_id" => sport&.id }
      actor.with_lock do
        raise Forbidden, "An active admin must edit sports data." unless actor.admin? && actor.active_for_authentication?
        existing = CatalogEdit.find_by(actor: actor, request_key: request_key)
        if existing
          raise Conflict, "This request key was already used for a different edit. Reload before saving." unless existing.submitted_values == submitted
          return existing
        end
        player = Player.new(submitted.fetch("attributes").merge(entity_code: code, sport: sport))
        raise ArgumentError, "Supply at least one part of the name." if [ player.first_name, player.last_name ].all?(&:blank?)
        player.save!
        EntityCode.create!(namespace: "MIC", catalog: "ALA", code: code, canonical_code: code, record: player)
        CatalogEdit.create!(actor: actor, actor_name: "#{actor.public_name} #{actor.handle}", record_type: "Player",
          record_id: player.id, entity_code: code, record_name: player.name, before_values: {},
          after_values: player.attributes.slice(*FIELDS.fetch("Player"), "entity_code", "sport_id"),
          submitted_values: submitted, request_key: request_key)
      end
    rescue ActiveRecord::RecordNotUnique
      raise Conflict, "This entity code is already in use. Choose another code."
    end

    def self.normalize(record, attributes)
      allowed = FIELDS.fetch(record.class.name)
      raise ArgumentError, "Unsupported catalog fields." if attributes.empty? || (attributes.keys - allowed).any?
      attributes.to_h.each_with_object({}) do |(field, raw), values|
        raise ArgumentError, "#{field.humanize} must be text." unless raw.is_a?(String)
        value = raw.strip
        values[field] = if ARRAYS.include?(field)
          entries = value.lines.map(&:strip).reject(&:blank?)
          max_length = field == "bio" ? 4000 : field == "photo_urls" ? 2048 : 100
          raise ArgumentError, "#{field.humanize} allows at most 30 lines of #{max_length} characters." if entries.length > 30 || entries.any? { |line| line.length > max_length }
          entries.each { |entry| validate_url!(entry) } if field == "photo_urls"
          entries
        elsif YEARS.include?(field)
          raise ArgumentError, "#{field.humanize} must be a four-digit year." if value.present? && !value.match?(/\A[1-9]\d{3}\z/)
          value.present? ? value.to_i : nil
        elsif field == "birthdate"
          raise Date::Error if value.present? && !value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
          date = value.present? ? Date.iso8601(value) : nil
          raise Date::Error if date && date.year.zero?
          date&.iso8601
        elsif field == "active"
          raise ArgumentError, "Choose Active, Inactive or Unknown." unless %w[true false unknown].include?(value)
          value == "unknown" ? nil : value == "true"
        elsif field.end_with?("_color")
          raise ArgumentError, "Use a six-digit hex color such as #00471B." if value.present? && !TeamPalette.valid_color?(value)
          value.presence&.upcase
        else
          limit = field.end_with?("url") ? 2048 : field == "abbreviation" ? 16 : 100
          raise ArgumentError, "#{field.humanize} must be at most #{limit} characters." if value.length > limit
          validate_url!(value) if field.end_with?("url") && value.present?
          value.presence
        end
      end
    rescue Date::Error
      raise ArgumentError, "Use a valid birthdate in YYYY-MM-DD format."
    end

    def self.validate_url!(value)
      uri = URI.parse(value)
      raise ArgumentError, "Use an http or https URL with a host." unless %w[http https].include?(uri.scheme) && uri.host.present?
    rescue URI::InvalidURIError
      raise ArgumentError, "Use an http or https URL with a host."
    end
    private_class_method :normalize, :validate_url!
  end
end
