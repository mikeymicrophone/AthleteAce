class GoalsController < ApplicationController
  before_action :authenticate_ace!
  before_action :set_goal, only: [:show, :update, :destroy]
  before_action :set_quest, only: [:create]

  # GET /goals
  def index
    @goals = current_ace.goals.includes(:quest)
  end

  # GET /goals/:id
  def show
  end

  # POST /quests/:quest_id/goals
  def create
    @goal = current_ace.adopt_quest(@quest)

    respond_to do |format|
      if @goal.persisted?
        format.html { redirect_to @goal.quest, notice: "You've successfully adopted this quest!" }
        format.json { render :show, status: :created, location: @goal }
      else
        format.html { redirect_to @quest, alert: "Unable to adopt this quest: #{@goal.errors.full_messages.join(', ')}" }
        format.json { render json: @goal.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /goals/:id
  def update
    respond_to do |format|
      if @goal.update(goal_params)
        format.html { redirect_to @goal, notice: "Goal was successfully updated." }
        format.json { render :show, status: :ok, location: @goal }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @goal.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /goals/:id
  def destroy
    quest = @goal.quest
    @goal.destroy

    respond_to do |format|
      format.html { redirect_to quests_path, notice: "You've abandoned the quest." }
      format.json { head :no_content }
    end
  end

  private
    def set_goal
      @goal = current_ace.goals.find(params[:id])
    end

    def set_quest
      @quest = Quest.find(params[:quest_id])
    end

    def goal_params
      params.require(:goal).permit(:status, :progress)
    end
end
