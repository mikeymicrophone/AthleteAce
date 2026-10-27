class GameRoundsController < ApplicationController
  before_action :authenticate_ace!, except: :new
  before_action :set_round, except: [ :new, :create ]
  rescue_from GameRound::InvalidAction, with: :invalid_action

  def new
    @setup = GameRoundSetup.new setup_params.merge(ace: current_ace)
    @sports = Sport.order(:name)
    store_location_for :ace, new_game_round_path(@setup.scope_params) if !ace_signed_in? && @setup.valid?
    @unfinished_rounds = current_ace ? current_ace.game_rounds.unfinished.limit(5) : []
  end

  def create
    @setup = GameRoundSetup.new setup_params.merge(ace: current_ace)
    @round = @setup.start! current_ace
    redirect_to game_round_path(@round), status: :see_other
  rescue ActiveModel::ValidationError
    @sports = Sport.order(:name)
    @unfinished_rounds = current_ace.game_rounds.unfinished.limit(5)
    render :new, status: :unprocessable_content
  end

  def show
    return redirect_to summary_game_round_path(@round) if @round.completed?

    @attempt = @round.current_attempt
    @miss_count = @round.miss_count_for(@attempt)
    @stats = @round.stats
    @subject = (@round.question.fetch("subject_type") == "Player" ? Player : Team).find_by id: @round.question.fetch("subject_id")
  end

  def answer
    @round.answer! at: params[:position], choice_id: params[:choice_id]
    redirect_to game_round_path(@round), status: :see_other
  rescue ActiveRecord::RecordInvalid
    redirect_to game_round_path(@round), status: :see_other,
      alert: "This question’s sports data is no longer available. Start a new round."
  end

  def advance
    @round.advance! at: params[:position]
    redirect_to @round.completed? ? summary_game_round_path(@round) : game_round_path(@round), status: :see_other
  end

  def pause
    @round.pause!
    redirect_to game_round_path(@round), status: :see_other
  end

  def resume
    @round.resume!
    redirect_to game_round_path(@round), status: :see_other
  end

  def summary
    return redirect_to game_round_path(@round) unless @round.completed?

    @results = @round.results
    @stats = @round.stats
    group_id = @round.scope["player_group_id"]
    @summary_group = PlayerGroup.find_by(id: group_id) if group_id
    @learning_entries = @round.quest_learning_entries
    if @summary_group && @learning_entries.empty?
      progress = PlayProgress.new(ace: current_ace, players: @summary_group.players)
      @group_overview = GroupPracticeOverview.new(groups: [ @summary_group ], progress: progress).rows.sole
    end
  end

  def drill
    drill = @round.drill_misses!
    redirect_to game_round_path(drill), status: :see_other
  end

  private

  def set_round
    @round = current_ace.game_rounds.find params[:id]
  end

  def setup_params
    params.permit(:practice_filter, :goal_achievement_id, :player_group_id, :game_type, :length, :sport_id, :league_id, :season_id, :conference_id, :division_id, :team_id,
      :city_id, :state_id, :include_inactive, :team_query, :fact_type, :player_id, :delay, team_ids: [], player_ids: [])
  end

  def invalid_action(error)
    redirect_to game_round_path(@round), alert: error.message, status: :see_other
  end
end
