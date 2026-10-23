module Admin
  class PeopleDirectory
    attr_reader :query, :role, :status, :joined_from, :joined_to

    def initialize(params)
      %i[q role status joined_from joined_to].each do |key|
        raise ArgumentError, "Invalid people filter." unless params[key].nil? || params[key].is_a?(String)
      end
      @query = params[:q].to_s.strip.first(80)
      @role, @status = params[:role].presence, params[:status].presence
      raise ArgumentError, "Choose a role." if role && !%w[fan moderator admin].include?(role)
      raise ArgumentError, "Choose an account status." if status && !%w[active warned muted suspended].include?(status)
      @joined_from = Date.iso8601(params[:joined_from]) if params[:joined_from].present?
      @joined_to = Date.iso8601(params[:joined_to]) if params[:joined_to].present?
      raise ArgumentError, "The joined date range is reversed." if joined_from && joined_to && joined_from > joined_to
    end

    def records
      records = Ace.all
      if query.present?
        records = records.where("CONCAT_WS(' ', '@' || username, display_name, email) ILIKE ?", "%#{Ace.sanitize_sql_like(query)}%")
      end
      records = case role
      when "admin" then records.where(admin: true)
      when "moderator" then records.where(admin: false, moderator: true)
      when "fan" then records.where(admin: false, moderator: false)
      else records
      end
      active_mutes = Mute.active.select(:ace_id)
      warned = PostingWarning.select(:ace_id)
      records = case status
      when "suspended" then records.where.not(suspended_at: nil)
      when "muted" then records.where(suspended_at: nil, id: active_mutes)
      when "warned" then records.where(suspended_at: nil, id: warned).where.not(id: active_mutes)
      when "active" then records.where(suspended_at: nil).where.not(id: active_mutes).where.not(id: warned)
      else records
      end
      records = records.where(created_at: joined_from.in_time_zone..) if joined_from
      records = records.where(created_at: ..joined_to.in_time_zone.end_of_day) if joined_to
      records.select("aces.*", Arel.sql(<<~SQL.squish)).order(created_at: :desc, id: :desc)
        COALESCE((SELECT -SUM(credit_entries.available_delta + credit_entries.reserved_delta)
          FROM credit_entries JOIN credit_accounts ON credit_accounts.id = credit_entries.credit_account_id
          WHERE credit_accounts.ace_id = aces.id AND credit_entries.kind IN ('capture', 'refund')), 0) AS spent_cents
      SQL
    end
  end
end
