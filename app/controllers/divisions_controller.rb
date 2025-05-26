class DivisionsController < ApplicationController
  before_action :set_division, only: %i[ show edit update destroy ]

  # GET /divisions or /divisions.json
  def index
    @divisions = if params[:conference_id]
      Division.where(conference_id: params[:conference_id])
    else
      Division.all
    end
    
    @spectrums = Spectrum.all
    
    # Set current spectrum ID if provided in params
    set_current_spectrum_id params[:spectrum_id] if params[:spectrum_id].present?
  end

  # GET /divisions/1 or /divisions/1.json
  def show
    @teams = @division.teams
  end

  # GET /divisions/new
  def new
    @division = Division.new
    @conferences = Conference.all
  end

  # GET /divisions/1/edit
  def edit
    @conferences = Conference.all
  end

  # POST /divisions or /divisions.json
  def create
    @division = Division.new(division_params)

    respond_to do |format|
      if @division.save
        format.html { redirect_to division_url(@division), notice: "Division was successfully created." }
        format.json { render :show, status: :created, location: @division }
      else
        @conferences = Conference.all
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @division.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /divisions/1 or /divisions/1.json
  def update
    respond_to do |format|
      if @division.update(division_params)
        format.html { redirect_to division_url(@division), notice: "Division was successfully updated." }
        format.json { render :show, status: :ok, location: @division }
      else
        @conferences = Conference.all
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @division.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /divisions/1 or /divisions/1.json
  def destroy
    @division.destroy

    respond_to do |format|
      format.html { redirect_to divisions_url, notice: "Division was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_division
      @division = Division.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def division_params
      params.require(:division).permit(:name, :abbreviation, :logo_url, :conference_id)
    end
end
