class ShoutOutReportsController < ApplicationController
  before_action :authenticate_ace!
  before_action { response.headers["Cache-Control"] = "private, no-store" }
  before_action :set_post

  def new
    @report = @post.shout_out_reports.find_by(reporter: current_ace) || @post.shout_out_reports.new
  end

  def create
    @post.with_lock do
      raise ActiveRecord::RecordNotFound unless @post.approved? && @post.funding_status == "spent"
      @report = @post.shout_out_reports.find_by(reporter: current_ace)
      @report ||= @post.shout_out_reports.create!(params.expect(shout_out_report: [ :reason, :note ]).merge(reporter: current_ace))
    end
    redirect_to feed_path, status: :see_other, notice: "Report received. A reviewer will look at it."
  rescue ActiveRecord::RecordInvalid => error
    @report = error.record
    render :new, status: :unprocessable_content
  end

  private

  def set_post
    @post = ShoutOut.approved.where(funding_status: "spent").find(params[:shout_out_id])
  end
end
