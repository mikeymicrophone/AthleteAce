require Rails.root.join("lib/micharisma_seeders/lib/micharisma_seeders").to_s

module Seeds
  class LibraryImporter
    class Error < StandardError; end
    class MissingReference < Error; end

    MODELS = {
      "Sport" => Sport, "Country" => Country, "State" => State, "City" => City,
      "Stadium" => Stadium, "League" => League, "Conference" => Conference,
      "Division" => Division, "Team" => Team, "Year" => Year, "Season" => Season,
      "Campaign" => Campaign, "Player" => Player, "Activation" => Activation,
      "Contract" => Contract
    }.freeze
    SCOPE_ASSOCIATIONS = {
      "State" => %w[country], "City" => %w[state], "Stadium" => %w[city],
      "League" => %w[sport], "Conference" => %w[league], "Division" => %w[conference],
      "Team" => %w[league], "Season" => %w[league year], "Player" => %w[sport],
      "Contract" => %w[player team], "Campaign" => %w[team], "Activation" => %w[player]
    }.freeze
    PROTECTED_ATTRIBUTES = %w[id entity_code created_at updated_at seed_version last_seeded_at].freeze

    attr_reader :report

    def initialize(namespace: "MIC", catalog: "ALA", registry: nil)
      @namespace, @catalog, @registry = namespace, catalog, registry
      @report = { created: [], unchanged: [], conflicts: [], aliases_added: [] }
    end

    def read(paths)
      reader = MICharismaSeeders::Reader.new
      paths.flat_map { |path| reader.read(path) }
    end

    # A read-only preflight: validates the envelope, model attributes, and selected
    # sequences. Model/database constraints are also checked during atomic import.
    def validate(paths)
      records = read(paths)
      validate_records!(records)
      declared = {}
      records.each do |record|
        ([record.code] + record.aliases).each do |code|
          prior = declared[code]
          if prior && prior.type != record.type
            raise Error, "#{record.location}: #{code} is declared for both #{prior.type} and #{record.type}"
          end
          declared[code] ||= record
        end
      end
      { records: records.length, codes: declared.length, files: paths.length }
    end

    def call(paths)
      @report = { created: [], unchanged: [], conflicts: [], aliases_added: [] }
      records = read(paths)
      validate_records!(records)
      ApplicationRecord.transaction do
        pending = records
        until pending.empty?
          deferred = []
          reasons = []
          pending.each do |record|
            begin
              import_record(record)
            rescue MissingReference => e
              deferred << record
              reasons << e.message
            end
          end
          if deferred.length == pending.length
            raise Error, "Unresolved seed dependencies:\n#{reasons.uniq.join("\n")}"
          end
          pending = deferred
        end
      end
      report
    rescue StandardError
      @report = { created: [], unchanged: [], conflicts: [], aliases_added: [] }
      raise
    end

    def resolve_code(type, code)
      model = MODELS.fetch(type) { raise Error, "Unsupported entity type #{type}" }
      binding = EntityCode.find_by(namespace: @namespace, catalog: @catalog, code: local_code(code))
      if binding
        raise Error, "#{code} identifies #{binding.record_type}, not #{type}" unless binding.record_type == type
        target = binding.resolved_record || model.find_by(entity_code: binding.canonical_code)
        return target if target
      end
      model.find_by(entity_code: local_code(code))
    end

    private

    def validate_records!(records)
      declared = {}
      parents = {}
      root = lambda do |code|
        parents[code] ||= code
        parents[code] = root.call(parents[code]) unless parents[code] == code
        parents[code]
      end
      records.each do |record|
        validate_record!(record)
        ([record.code] + record.aliases).each do |code|
          if declared[code] && declared[code].type != record.type
            raise Error, "#{record.location}: #{code} identifies multiple types"
          end
          declared[code] ||= record
          parents[root.call(code)] = root.call(record.code)
        end
      end
      records.group_by { |record| root.call(record.code) }.each_value do |definitions|
        merged_attributes = {}
        merged_references = {}
        definitions.each do |record|
          cast_attributes(MODELS.fetch(record.type), record.attributes).each do |key, value|
            if merged_attributes.key?(key) && merged_attributes[key] != value
              raise Error, "#{record.location}: contradictory #{record.code} attribute #{key} across seed definitions"
            end
            merged_attributes[key] = value
          end
          inferred_keys = case record.type
                          when "Campaign" then %w[league year season stadium city conference division]
                          when "Activation" then %w[team league year season]
                          when "League" then %w[country]
                          else []
                          end
          keys = (SCOPE_ASSOCIATIONS.fetch(record.type, []) + inferred_keys + record.references.keys).uniq
          keys.each do |key|
            next unless record.references.key?(key) || record.scope.key?(key)
            ref = record.references.key?(key) ? record.references[key] : record.scope[key]
            ref = local_code(ref) if ref.is_a?(String)
            ref = root.call(ref) if ref.is_a?(String) && parents.key?(ref)
            if merged_references.key?(key) && merged_references[key] != ref
              raise Error, "#{record.location}: contradictory #{record.code} reference #{key} across seed definitions"
            end
            merged_references[key] = ref
          end
        end
      end
    end

    def validate_record!(record)
      unless record.namespace == @namespace && record.catalog == @catalog
        raise Error, "#{record.location}: unexpected namespace/catalog #{record.namespace}/#{record.catalog}"
      end
      model = MODELS.fetch(record.type) { raise Error, "#{record.location}: unsupported type #{record.type}" }
      ([record.code] + record.aliases).each do |code|
        unless code.is_a?(String) && code.match?(/\A[A-Z0-9]+(?:[-_][A-Z0-9]+)*\z/) && code == local_code(code)
          raise Error, "#{record.location}: invalid local entity code #{code.inspect}"
        end
      end
      record.attributes.each_key do |key|
        if PROTECTED_ATTRIBUTES.include?(key) || key.end_with?("_id") || !model.column_names.include?(key)
          raise Error, "#{record.location}: unsupported #{record.type} attribute #{key}; associations use references"
        end
      end
      record.references.each_key do |key|
        association = model.reflect_on_association(key.to_sym)
        unless association&.macro == :belongs_to
          raise Error, "#{record.location}: unsupported #{record.type} reference #{key}"
        end
      end
      sequences = [record.entity_sequence] + record.references.values.filter_map { |reference| reference["entity_sequence"] if reference.is_a?(Hash) }
      sequences.compact.uniq.each do |sequence|
        raise Error, "Sequence registry is required for selected #{sequence}" unless @registry
        @registry.fetch(sequence)
      end
    end

    def import_record(record)
      model = MODELS.fetch(record.type)
      desired = cast_attributes(model, record.attributes)
      desired.merge!(associations_for(record))
      codes = ([record.code] + record.aliases).uniq
      bindings = EntityCode.where(namespace: @namespace, catalog: @catalog, code: codes).lock.to_a
      bindings.each do |binding|
        raise Error, "#{binding.code} already identifies #{binding.record_type}" unless binding.record_type == record.type
      end
      targets = codes.filter_map { |code| resolve_code(record.type, code) }.uniq(&:id)
      raise Error, "#{record.location}: aliases identify different #{record.type} records" if targets.length > 1
      target = targets.first || natural_target(model, desired)
      canonical_code = target&.entity_code.presence || bindings.first&.canonical_code || record.code
      codes |= [canonical_code]
      if target.nil?
        target = model.create!(desired.merge(entity_code: canonical_code))
        report[:created] << canonical_code
      else
        differences = desired.each_with_object({}) do |(key, value), result|
          current = association_attribute?(model, key) ? target.public_send(key)&.id : target.public_send(key)
          incoming = association_attribute?(model, key) ? value&.id : value
          result[key] = { existing: current, incoming: incoming } unless current == incoming
        end
        # Adoption via a strong natural key does not change catalog fields.
        target.update!(entity_code: canonical_code) if target.entity_code.blank?
        if differences.empty?
          report[:unchanged] << canonical_code
        else
          report[:conflicts] << { code: canonical_code, differences: differences, source: record.source }
        end
      end
      codes.each do |code|
        binding = EntityCode.find_or_initialize_by(namespace: @namespace, catalog: @catalog, code: code)
        if binding.persisted? && binding.canonical_code != canonical_code
          raise Error, "#{code} is permanently bound to #{binding.canonical_code}"
        end
        report[:aliases_added] << code if binding.new_record? && code != canonical_code
        binding.assign_attributes(canonical_code: canonical_code, record: target)
        binding.save! if binding.new_record? || binding.changed?
      end
    end

    def cast_attributes(model, attributes)
      attributes.to_h do |key, value|
        column = model.columns_hash.fetch(key)
        if column.array && !value.nil? && !value.is_a?(Array)
          raise Error, "#{model.name}.#{key} requires an array"
        end
        if column.type == :date && !value.nil?
          value = Date.iso8601(value.to_s)
        elsif column.type == :integer && !value.nil? && !value.to_s.match?(/\A-?\d+\z/)
          raise Error, "#{model.name}.#{key} requires an integer"
        end
        [key, model.type_for_attribute(key).cast(value)]
      end
    rescue ArgumentError => e
      raise Error, "Invalid attribute for #{model.name}: #{e.message}"
    end

    def associations_for(record)
      model = MODELS.fetch(record.type)
      values = {}
      SCOPE_ASSOCIATIONS.fetch(record.type, []).each do |key|
        reference = record.references[key] || record.scope[key]
        values[key] = resolve_reference(model, key, reference, record) if reference
      end
      record.references.each do |key, reference|
        values[key] = reference.nil? ? nil : resolve_reference(model, key, reference, record)
      end
      if record.type == "League" && !values.key?("jurisdiction") && record.scope["country"]
        values["jurisdiction"] = required_code("Country", record.scope["country"], record)
      end
      if record.type == "Campaign"
        values["season"] ||= scoped_season(record)
        %w[stadium city conference division].each do |key|
          reference = record.references[key] || record.scope[key]
          values[key] = resolve_reference(model, key, reference, record) if reference
        end
      elsif record.type == "Activation" && !values.key?("campaign")
        team = scoped_entity("Team", "team", record)
        season = scoped_season(record)
        campaign = Campaign.find_by(team: team, season: season)
        raise MissingReference, "#{record.location}: missing campaign for #{team.entity_code}/#{season.entity_code}" unless campaign
        values["campaign"] = campaign
      end
      values
    end

    def resolve_reference(model, key, reference, record)
      association = model.reflect_on_association(key.to_sym)
      type = association.polymorphic? ? "Country" : association.klass.name
      if reference.is_a?(Hash)
        if (reference["namespace"] && reference["namespace"] != @namespace) || (reference["catalog"] && reference["catalog"] != @catalog)
          raise Error, "#{record.location}: foreign references need an adapter for their catalog"
        end
        code = reference.fetch("code")
        sequence = reference["entity_sequence"] || record.entity_sequence
        scope = record.scope.merge(reference.fetch("scope", {}))
        if sequence
          raise Error, "Sequence registry is required for selected #{sequence}" unless @registry
          parser = MICharismaEntityParser.select_entity_sequence(sequence, registry: @registry,
            namespace: @namespace, catalog: @catalog,
            adapter: EntitySequenceResolver.new(self, scope: scope))
          target = parser.resolve(code, scope: scope)
          raise Error, "#{code} resolves to #{target.class.name}, not #{type}" unless target.is_a?(MODELS.fetch(type))
          return target
        end
        reference = code
      end
      if record.entity_sequence && @registry.fetch(record.entity_sequence).slots.last == type.downcase
        target = resolve_code(type, reference)
        return target if target
        parser = MICharismaEntityParser.select_entity_sequence(record.entity_sequence, registry: @registry,
          namespace: @namespace, catalog: @catalog, adapter: EntitySequenceResolver.new(self))
        return parser.resolve(reference, scope: record.scope)
      end
      required_code(type, reference, record)
    end

    def scoped_entity(type, key, record)
      code = record.scope[key]
      raise MissingReference, "#{record.location}: missing #{key} scope" unless code
      required_code(type, code, record)
    end

    def scoped_season(record)
      return required_code("Season", record.scope["season"], record) if record.scope["season"]
      league = scoped_entity("League", "league", record)
      year = scoped_entity("Year", "year", record)
      season = Season.find_by(league: league, year: year)
      raise MissingReference, "#{record.location}: missing season for #{league.entity_code}/#{year.entity_code}" unless season
      season
    end

    def required_code(type, code, record)
      resolve_code(type, code) || raise(MissingReference, "#{record.location}: missing #{type} #{code}")
    end

    def natural_target(model, desired)
      keys = { Year => %w[number], Season => %w[year league], Campaign => %w[team season], Activation => %w[player campaign] }[model]
      return unless keys && keys.all? { |key| desired[key].present? }
      model.find_by(desired.slice(*keys))
    end

    def association_attribute?(model, key)
      model.reflect_on_association(key.to_sym)&.macro == :belongs_to
    end

    def local_code(code)
      prefix = "#{@namespace}-#{@catalog}-"
      code.to_s.start_with?(prefix) ? code.to_s.delete_prefix(prefix) : code.to_s
    end
  end
end
