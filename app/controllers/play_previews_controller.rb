class PlayPreviewsController < ApplicationController
  before_action :redirect_signed_in
  before_action :load_preview

  def show
  end

  def answer
    return redirect_to play_preview_path, status: :see_other unless @preview && params[:token] == @preview["token"]
    return redirect_to play_preview_path, status: :see_other if @preview.key?("correct")

    choice = @preview.fetch("question").fetch("choices").find { |item| item.fetch("id").to_s == params[:choice_id].to_s }
    if params[:choice_id].present? && !choice
      flash.now[:alert] = "Choose one of the answers shown."
      return render :show, status: :unprocessable_content
    end
    @preview["correct"] = choice&.fetch("id") == @preview.fetch("question").fetch("target_id")
    @preview["choice_id"] = choice&.fetch("id")
    session[:play_preview] = @preview
    redirect_to play_preview_path, status: :see_other
  end

  private

  def redirect_signed_in
    redirect_to strength_path if current_ace
  end

  def load_preview
    response.headers["Cache-Control"] = "no-store"
    @preview = session[:play_preview]
    return if @preview && @preview.fetch("expires_at") > Time.current.to_i

    setup = GameRoundSetup.new(params.permit(:team_id))
    setup = setup.season_suggestion if setup.valid? && setup.available_count.zero? && setup.season_suggestion
    question = setup.preview_question
    @preview = question && { "question" => question, "token" => SecureRandom.hex(12), "expires_at" => 30.minutes.from_now.to_i }
    session[:play_preview] = @preview
  end
end
