module Admin
  class ModerationOversight
    MAX_DAYS = 366
    attr_reader :log

    def initialize(from: nil, through: nil, type: nil, now: Time.current)
      @log = Moderation::DecisionLog.new(from: from, through: through, type: type, reviews_only: "1", now: now)
      raise ArgumentError, "Choose up to #{MAX_DAYS} UTC days." if (@log.through - @log.from).to_i + 1 > MAX_DAYS
    end

    def counts
      @counts ||= events.group(:action).count
    end

    def daily
      @daily ||= begin
        recorded = events.group(Arel.sql("moderation_decisions.created_at::date")).count
        (log.from..log.through).to_h { |date| [ date, recorded.fetch(date, 0) ] }
      end
    end

    def by_type
      @by_type ||= events.group(:subject_type, :action).count
    end

    def pending_wait
      @pending_wait ||= begin
        pairs = events.where(action: %w[approved rejected]).joins(<<~SQL.squish)
          JOIN LATERAL (
            SELECT prior.action, prior.from_status, prior.to_status, prior.created_at
            FROM moderation_decisions prior
            WHERE prior.subject_type = moderation_decisions.subject_type
              AND prior.subject_id = moderation_decisions.subject_id
              AND prior.revision = moderation_decisions.revision
              AND (prior.created_at, prior.id) < (moderation_decisions.created_at, moderation_decisions.id)
            ORDER BY prior.created_at DESC, prior.id DESC
            LIMIT 1
          ) pending_entry ON TRUE
        SQL
        pairs = pairs.where(<<~SQL.squish)
          pending_entry.to_status = 'pending' AND (
            pending_entry.action = 'submitted' OR (
              pending_entry.action = 'reopened' AND pending_entry.from_status IN ('rejected', 'hidden')
            )
          )
        SQL
        matched, median = pairs.pick(Arel.sql("COUNT(*)"), Arel.sql(<<~SQL.squish))
          percentile_cont(0.5) WITHIN GROUP (
            ORDER BY EXTRACT(EPOCH FROM (moderation_decisions.created_at - pending_entry.created_at))
          )
        SQL
        { matched: matched, median_seconds: median, total: counts.fetch("approved", 0) + counts.fetch("rejected", 0) }
      end
    end

    private

    def events
      @events ||= log.records.except(:includes, :order)
    end
  end
end
