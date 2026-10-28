module Admin
  class ContentDirectory
    TYPES = { "Quest" => Quest, "Achievement" => Achievement, "Spectrum" => Spectrum }.freeze
    SORTS = { "updated" => "Recently updated", "name" => "Name" }.freeze
    attr_reader :query, :type, :status, :creator_id, :sort

    def initialize(params)
      %i[q item_type status creator_id sort].each do |key|
        raise ArgumentError, "Invalid content filter." unless params[key].nil? || params[key].is_a?(String)
      end
      @query = params[:q].to_s.strip.first(80)
      @type, @status, @creator_id = params.values_at(:item_type, :status, :creator_id).map(&:presence)
      @sort = params[:sort].presence || "updated"
      raise ArgumentError, "Choose a content type." if type && !TYPES.key?(type)
      raise ArgumentError, "Choose a content status." if status && !Moderation::Queue::STATUSES.include?(status)
      raise ArgumentError, "Choose a content creator." if creator_id && creator_id != "unattributed" && !creator_id.match?(/\A[1-9]\d{0,17}\z/)
      raise ArgumentError, "Choose a content sort." unless SORTS.key?(sort)
    end

    def records
      sources = TYPES.filter_map do |name, model|
        next if type && type != name

        scope = model.all
        if query.present?
          scope = scope.where("CONCAT_WS(' ', name, description) ILIKE ?", "%#{model.sanitize_sql_like(query)}%")
        end
        scope = scope.where(moderation_status: status) if status
        scope = scope.where(created_by_id: creator_id == "unattributed" ? nil : creator_id) if creator_id
        scope.select(:id, :name, :updated_at, Arel::Nodes.build_quoted(name).as("item_type")).arel
      end
      union = sources.reduce { |left, right| Arel::Nodes::UnionAll.new(left, right) }
      table = Arel::Table.new("content_records", klass: Quest)
      source = Arel::Nodes::TableAlias.new(Arel::Nodes::Grouping.new(union), table.name)
      order = sort == "name" ? Arel::Nodes::NamedFunction.new("LOWER", [ table[:name] ]) : table[:updated_at].desc
      Quest.unscoped.from(source).select(table[Arel.star]).order(order, table[:item_type], table[:id])
    end

    def load_records(rows)
      keys = rows.map { |row| [ row.item_type, row.id ] }
      loaded = keys.group_by(&:first).flat_map do |name, entries|
        scope = TYPES.fetch(name).where(id: entries.map(&:last)).includes(:created_by)
        scope = scope.includes(:target) if name == "Achievement"
        scope.map { |record| [ [ name, record.id ], record ] }
      end.to_h
      keys.map { |key| loaded.fetch(key) }
    end

    def creators
      TYPES.values.map { |model| Ace.where(id: model.select(:created_by_id)) }
        .reduce { |left, right| left.or(right) }.order(:username, :id)
    end
  end
end
