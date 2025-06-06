class AchievementsController < ApplicationController
  before_action :set_achievement, only: %i[ show edit update destroy ]

  # GET /achievements or /achievements.json
  def index
    @achievements = Achievement.all
  end

  # GET /achievements/1 or /achievements/1.json
  def show
  end

  # GET /achievements/new
  def new
    @achievement = Achievement.new
    @target_type = params[:target_type] || 'Team'
  end

  # GET /achievements/1/edit
  def edit
    @target_type = @achievement.target_type
  end

  # POST /achievements or /achievements.json
  def create
    @achievement = Achievement.new(achievement_params)
    quest_id = params[:achievement][:quest_id]

    respond_to do |format|
      if @achievement.save
        # Create a highlight if a quest was selected
        if quest_id.present?
          quest = Quest.find(quest_id)
          @achievement.add_to_quest(quest)
        end

        format.html { redirect_to @achievement, notice: "Achievement was successfully created." }
        format.json { render :show, status: :created, location: @achievement }
      else
        @target_type = @achievement.target_type || params[:achievement][:target_type] || 'Team'
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @achievement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /achievements/1 or /achievements/1.json
  def update
    respond_to do |format|
      if @achievement.update(achievement_params)
        format.html { redirect_to @achievement, notice: "Achievement was successfully updated." }
        format.json { render :show, status: :ok, location: @achievement }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @achievement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /achievements/1 or /achievements/1.json
  def destroy
    @achievement.destroy!

    respond_to do |format|
      format.html { redirect_to achievements_path, status: :see_other, notice: "Achievement was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # GET /achievements/target_options
  def target_options
    model = params[:type].safe_constantize
    if model && model.respond_to?(:all)
      options = model.all.map { |obj| { id: obj.id, name: obj.try(:name) || obj.try(:title) || obj.to_s } }
      render json: options
    else
      render json: []
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_achievement
      @achievement = Achievement.find(params.require(:id))
    end

    # Only allow a list of trusted parameters through.
    def achievement_params
      params.require(:achievement).permit(:name, :description, :target_id, :target_type)
    end
end
