require "csv"

module Moderation
  class DecisionLog
    EXPORT_LIMIT = 10_000
    ACTIONS = %w[submitted approved rejected hidden reopened].freeze
    attr_reader :from, :through, :type, :actor_id, :action, :as_of

    def initialize(from: nil, through: nil, type: nil, actor_id: nil, action: nil, now: Time.current)
      @as_of = now.utc
      @through = date(through.presence || @as_of.to_date.iso8601)
      @from = date(from.presence || (@through - 29).iso8601)
      raise ArgumentError, "Choose dates in order, ending today or earlier." if @from > @through || @through > @as_of.to_date
      @type = type.presence
      @action = action.presence
      raise ArgumentError, "Choose a recorded content type." if @type && !Queue::TYPES.key?(@type)
      raise ArgumentError, "Choose a recorded action." if @action && !ACTIONS.include?(@action)
      @actor_id = actor_id.presence
      if @actor_id && @actor_id != "unattributed"
        raise ArgumentError, "Choose a recorded actor." unless @actor_id.to_s.match?(/\A[1-9]\d*\z/) && Ace.exists?(id: @actor_id)
        @actor_id = @actor_id.to_s
      end
      start = Time.utc(@from.year, @from.month, @from.day)
      finish = Time.utc(@through.year, @through.month, @through.day) + 1.day
      @scope = ModerationDecision.where(created_at: start...finish).where(created_at: ..@as_of)
      @scope = @scope.where(subject_type: @type) if @type
      @scope = @scope.where(action: @action) if @action
      @scope = @scope.where(actor_id: @actor_id == "unattributed" ? nil : @actor_id) if @actor_id
    end

    def records
      @scope.includes(:actor).order(created_at: :desc, id: :desc)
    end

    def counts
      @counts ||= @scope.group(:action).count
    end

    def filters
      { from: from.iso8601, through: through.iso8601, item_type: type, actor_id: actor_id, decision_action: action }
    end

    def csv
      rows = records.limit(EXPORT_LIMIT + 1).to_a
      raise ArgumentError, "Export exceeds #{EXPORT_LIMIT} events. Narrow the dates or filters." if rows.size > EXPORT_LIMIT

      CSV.generate do |csv|
        csv << %w[id recorded_at_utc subject_type subject_id action revision from_status to_status actor_id actor_handle recorded_name reason]
        rows.each do |record|
          values = [ record.id, record.created_at.utc.iso8601(6), record.subject_type, record.subject_id, record.action,
            record.revision, record.from_status, record.to_status, record.actor_id, record.actor&.handle,
            record.snapshot["name"] || record.snapshot["target_name"], record.reason ]
          csv << values.map { |value| value.is_a?(String) && value.match?(/\A(?:[\t\r\n]|[[:space:]\x00-\x1f]*[=+\-@])/) ? "'#{value}" : value }
        end
      end
    end

    private

    def date(value)
      raise ArgumentError, "Use dates in YYYY-MM-DD format." unless value.to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
      parsed = Date.iso8601(value)
      raise ArgumentError, "Use dates with a positive year." unless parsed.year.positive?
      parsed
    rescue Date::Error
      raise ArgumentError, "Choose a valid calendar date."
    end
  end
end
