module Admin
  class Overview
    attr_reader :as_of, :today, :cash_daily, :new_aces_today, :review_counts, :reviewers, :escalation_count, :escalations

    def initialize(admin:, now: Time.current)
      @as_of = now.utc
      @today = @as_of.to_date
      today_start = Time.utc(today.year, today.month, today.day)
      today_range = today_start..@as_of
      revenue = ShoutOutRevenue.new(days: "30", now: @as_of)
      @cash_daily = revenue.daily.to_a.last(14).to_h.transform_values { |row| row.fetch("purchase") }
      @new_aces_today = Ace.where(created_at: today_range).count
      @review_counts = ModerationDecision.where(created_at: today_range,
        action: %w[approved rejected hidden reopened], from_status: Moderation::Queue::STATUSES).group(:actor_id).count
      @reviewers = Ace.where(id: @review_counts.keys.compact).index_by(&:id)
      visible_cases = ModerationEscalation.visible_to(admin).open
      @escalation_count = visible_cases.count
      @escalations = visible_cases.order(:created_at, :id).limit(5)
    end

    def cash_today
      cash_daily.fetch(today)
    end

    def cash_total
      cash_daily.values.sum
    end

    def review_total
      review_counts.values.sum
    end
  end
end
