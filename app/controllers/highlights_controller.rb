class HighlightsController < ApplicationController
  before_action :set_quest, except: [:new, :create]
  before_action :set_highlight, only: [:show, :edit, :update, :destroy]
  
  # GET /quests/:quest_id/highlights
  def index
    @highlights = @quest.highlights.includes(:achievement).order(position: :asc)
  end
  
  # GET /quests/:quest_id/highlights/:id
  def show
  end
  
  # GET /highlights/new
  # GET /quests/:quest_id/highlights/new
  def new
    if params[:achievement_id].present?
      # Coming from achievement index - select a quest
      @achievement = Achievement.find(params[:achievement_id])
      @highlight = Highlight.new(achievement: @achievement)
      @available_quests = Quest.where.not(id: @achievement.quest_ids)
      render :new_from_achievement
    else
      # Coming from quest show - select an achievement
      @quest = Quest.find(params[:quest_id])
      @highlight = @quest.highlights.new
      # Get achievements that aren't already part of this quest
      @available_achievements = Achievement.where.not(id: @quest.achievement_ids)
    end
  end
  
  # GET /quests/:quest_id/highlights/:id/edit
  def edit
  end
  
  # POST /highlights
  # POST /quests/:quest_id/highlights
  def create
    if params[:highlight][:achievement_id].present? && params[:highlight][:quest_id].present?
      # Coming from the standalone form (achievement to quest)
      @highlight = Highlight.new(highlight_params)
      quest = Quest.find(params[:highlight][:quest_id])
      
      respond_to do |format|
        if @highlight.save
          format.html { redirect_to quest_path(quest), notice: "Achievement was successfully added to quest." }
          format.json { render :show, status: :created, location: @highlight }
        else
          @achievement = Achievement.find(params[:highlight][:achievement_id])
          @available_quests = Quest.where.not(id: @achievement.quest_ids)
          format.html { render :new_from_achievement, status: :unprocessable_entity }
          format.json { render json: @highlight.errors, status: :unprocessable_entity }
        end
      end
    else
      # Coming from the nested form (quest to achievement)
      @quest = Quest.find(params[:quest_id])
      @highlight = @quest.highlights.new(highlight_params)
      
      respond_to do |format|
        if @highlight.save
          format.html { redirect_to quest_path(@quest), notice: "Achievement was successfully added to quest." }
          format.json { render :show, status: :created, location: @highlight }
        else
          @available_achievements = Achievement.where.not(id: @quest.achievement_ids)
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @highlight.errors, status: :unprocessable_entity }
        end
      end
    end
  end
  
  # PATCH/PUT /quests/:quest_id/highlights/:id
  def update
    respond_to do |format|
      if @highlight.update(highlight_params)
        format.html { redirect_to quest_path(@quest), notice: "Highlight was successfully updated." }
        format.json { render :show, status: :ok, location: @highlight }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @highlight.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # DELETE /quests/:quest_id/highlights/:id
  def destroy
    @highlight.destroy
    
    respond_to do |format|
      format.html { redirect_to quest_path(@quest), notice: "Achievement was successfully removed from quest." }
      format.json { head :no_content }
    end
  end
  
  private
  
  def set_quest
    @quest = Quest.find(params[:quest_id])
  end
  
  def set_highlight
    @highlight = @quest.highlights.find(params[:id])
  end
  
  def highlight_params
    params.require(:highlight).permit(:achievement_id, :quest_id, :position, :required)
  end
end
