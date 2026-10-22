class ShoutOutRevenuesController < ApplicationController
  before_action :authenticate_ace!
  before_action :require_admin!
  before_action { response.headers["Cache-Control"] = "private, no-store" }

  def show
    @revenue = ShoutOutRevenue.new(days: params[:days] || "30")
    respond_to do |format|
      format.html do
        @available, @reserved = @revenue.balances
        @paying_aces = @revenue.paying_aces
        @live_count = ShoutOut.approved.where(funding_status: "spent").count
        @targets = @revenue.top_targets
      end
      format.csv do
        require "csv"
        data = CSV.generate do |csv|
          csv << %w[date_utc purchases_cents credit_spent_cents reservations_released_cents credit_refunds_cents]
          @revenue.daily.each { |date, row| csv << [ date.iso8601, *ShoutOutRevenue::KINDS.map { |kind| row.fetch(kind) } ] }
        end
        send_data data, type: "text/csv", filename: "athleteace-revenue-#{@revenue.from}-#{@revenue.through}.csv"
      end
    end
  rescue ArgumentError => error
    render plain: error.message, status: :bad_request
  end
end
