module Moderation
  class Queue
    TYPES = { "Quest" => Quest, "Achievement" => Achievement, "Highlight" => Highlight, "Spectrum" => Spectrum, "ShoutOut" => ShoutOut }.freeze
    STATUSES = %w[pending approved rejected hidden].freeze
    PAGE_SIZE = 25

    attr_reader :status, :type

    def initialize(reviewer:, status: nil, type: nil, page: nil)
      @reviewer = reviewer
      @status = status.presence_in(STATUSES) || "pending"
      @type = type.presence_in(TYPES.keys)
      @requested_page = page.to_i
    end

    def counts
      @counts ||= TYPES.to_h { |type, model| [ type, scope(model).count ] }
    end

    def total
      type ? counts.fetch(type) : counts.values.sum
    end

    def pages
      [ (total.to_f / PAGE_SIZE).ceil, 1 ].max
    end

    def page
      @requested_page.clamp(1, pages)
    end

    def offset
      (page - 1) * PAGE_SIZE
    end

    def items
      @items ||= records(offset: offset, limit: PAGE_SIZE)
    end

    def neighbors(record)
      index = items.index(record)
      return [ nil, items.first ] unless index

      position = offset + index
      previous = records(offset: position - 1, limit: 1).first if position.positive?
      following = records(offset: position + 1, limit: 1).first if position + 1 < total
      [ previous, following ]
    end

    private

    def scope(model)
      escalated_ids = ModerationEscalation.open.where(subject_type: model.name).select(:subject_id)
      model = model.where.not(funding_status: "unfunded") if model == ShoutOut
      model = model.where.not(id: escalated_ids)
      model.where(moderation_status: status).where.not(created_by_id: @reviewer.id).or(
        model.where(moderation_status: status, created_by_id: nil)
      )
    end

    def records(offset:, limit:)
      sources = TYPES.filter_map do |name, model|
        next if type && type != name
        scope(model).select(:id, :created_at, Arel::Nodes.build_quoted(name).as("item_type")).arel
      end
      union = sources.reduce { |left, right| Arel::Nodes::UnionAll.new(left, right) }
      submissions = Arel::Table.new("submissions", klass: Quest)
      source = Arel::Nodes::TableAlias.new(Arel::Nodes::Grouping.new(union), submissions.name)
      rows = Quest.unscoped.from(source).order(submissions[:created_at], submissions[:item_type], submissions[:id])
        .limit(limit).offset(offset).pluck(submissions[:id], submissions[:item_type])
      loaded = rows.group_by(&:last).flat_map do |name, entries|
        relation = TYPES.fetch(name).where(id: entries.map(&:first)).includes(:created_by)
        relation = relation.includes(:quest, :achievement) if name == "Highlight"
        relation.map { |item| [ [ name, item.id ], item ] }
      end.to_h
      rows.map { |id, name| loaded.fetch([ name, id ]) }
    end
  end
end
