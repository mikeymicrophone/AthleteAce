class ShoutOutRevenue
  RANGES = [ 7, 30, 90, 365 ].freeze
  KINDS = %w[purchase capture release refund].freeze
  attr_reader :days, :from, :through, :daily, :totals, :as_of

  def initialize(days: "30", now: Time.current)
    raise ArgumentError, "Choose 7, 30, 90 or 365 days." unless RANGES.map(&:to_s).include?(days.to_s)
    @days = days.to_i
    @as_of = now.utc
    @through = @as_of.to_date
    @from = @through - @days + 1
    start = Time.utc(@from.year, @from.month, @from.day)
    @entries = CreditEntry.where(created_at: start..@as_of)
    flows = @entries.where(kind: KINDS).group(Arel.sql("DATE(created_at)"), :kind)
      .pluck(Arel.sql("DATE(created_at)"), :kind, Arel.sql("SUM(available_delta)"), Arel.sql("SUM(reserved_delta)"))
    @daily = (@from..@through).to_h { |date| [ date, KINDS.index_with { 0 } ] }
    flows.each { |date, kind, available, reserved| @daily.fetch(date)[kind] = kind == "capture" ? -reserved.to_i : available.to_i }
    @totals = KINDS.index_with { |kind| @daily.values.sum { |row| row.fetch(kind) } }
  end

  def balances
    CreditAccount.pick(Arel.sql("COALESCE(SUM(available_cents), 0)"), Arel.sql("COALESCE(SUM(reserved_cents), 0)")).map(&:to_i)
  end

  def paying_aces
    StripePurchase.where(id: @entries.where(kind: "purchase", source_type: "StripePurchase").select(:source_id)).distinct.count(:ace_id)
  end

  def top_targets
    ShoutOut.joins("INNER JOIN credit_entries ON credit_entries.source_type = 'ShoutOut' AND credit_entries.source_id = shout_outs.id")
      .merge(@entries.where(kind: "capture"))
      .group(:target_type, :target_id, :target_name)
      .order(Arel.sql("SUM(-credit_entries.reserved_delta) DESC"), :target_type, :target_name, :target_id)
      .limit(10).pluck(:target_name, Arel.sql("COUNT(*)"), Arel.sql("SUM(-credit_entries.reserved_delta)"))
  end
end
