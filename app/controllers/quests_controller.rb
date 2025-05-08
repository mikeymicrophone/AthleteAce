class QuestsController < ApplicationController
  before_action :set_quest, only: %i[ show edit update destroy ]
  before_action :authenticate_ace!, only: %i[ random ]

  # GET /quests or /quests.json
  def index
    @quests = Quest.all
  end

  # GET /quests/1 or /quests/1.json
  def show
  end

  # GET /quests/new
  def new
    @quest = Quest.new
  end

  # GET /quests/1/edit
  def edit
  end

  # POST /quests or /quests.json
  def create
    @quest = Quest.new(quest_params)

    respond_to do |format|
      if @quest.save
        format.html { redirect_to @quest, notice: "Quest was successfully created." }
        format.json { render :show, status: :created, location: @quest }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @quest.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /quests/1 or /quests/1.json
  def update
    respond_to do |format|
      if @quest.update(quest_params)
        format.html { redirect_to @quest, notice: "Quest was successfully updated." }
        format.json { render :show, status: :ok, location: @quest }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @quest.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /quests/1 or /quests/1.json
  def destroy
    @quest.destroy

    respond_to do |format|
      format.html { redirect_to quests_url, notice: "Quest was successfully destroyed." }
      format.json { head :no_content }
    end
  end
  
  # GET /quests/random
  def random
    # Find quests the current ace hasn't started yet
    current_ace_quest_ids = current_ace.goals.pluck(:quest_id)
    available_quests = Quest.where.not(id: current_ace_quest_ids)
    
    if available_quests.any?
      # Get a random quest
      @quest = available_quests.order("RANDOM()").first
      @random_mode = true
      render :show
    else
      # If the ace has started all quests, just show a random one
      @quest = Quest.order("RANDOM()").first
      @random_mode = true
      
      if @quest
        render :show
      else
        redirect_to quests_path, alert: "No quests available."
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_quest
      @quest = Quest.find(params.require(:id))
    end

    # Only allow a list of trusted parameters through.
    def quest_params
      params.require(:quest).permit(:name, :description)
    end
end
