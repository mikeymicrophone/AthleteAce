class SportsController < ApplicationController
  include Filterable
  before_action :set_sport, only: %i[ show edit update destroy ]
  filterable_by :country

  # GET /sports or /sports.json
  def index 
    @sports = apply_filter :sports
  end

  # GET /sports/1 or /sports/1.json
  def show
  end

  # GET /sports/new
  def new
    @sport = Sport.new
  end

  # GET /sports/1/edit
  def edit
  end

  # POST /sports or /sports.json
  def create
    @sport = Sport.new(sport_params)

    respond_to do |format|
      if @sport.save
        format.html { redirect_to @sport, notice: "Sport was successfully created." }
        format.json { render :show, status: :created, location: @sport }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @sport.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sports/1 or /sports/1.json
  def update
    respond_to do |format|
      if @sport.update(sport_params)
        format.html { redirect_to @sport, notice: "Sport was successfully updated." }
        format.json { render :show, status: :ok, location: @sport }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @sport.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sports/1 or /sports/1.json
  def destroy
    @sport.destroy!

    respond_to do |format|
      format.html { redirect_to sports_path, status: :see_other, notice: "Sport was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sport
      @sport = Sport.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def sport_params
      params.expect(sport: [ :name, :description ])
    end
end
