class SpectrumsController < ApplicationController
  before_action :authenticate_ace!, except: [:index, :show]
  before_action :require_admin!, only: [:edit, :update, :destroy]
  before_action :set_spectrum, only: [:show, :edit, :update, :destroy]

  # GET /spectrums
  def index
    @spectrums = Spectrum.all.order(:name)
  end

  # GET /spectrums/1
  def show
  end

  # GET /spectrums/new
  def new
    @spectrum = Spectrum.new
  end

  # GET /spectrums/1/edit
  def edit
  end

  # POST /spectrums
  def create
    @spectrum = Spectrum.new(spectrum_params)

    if @spectrum.save
      redirect_to @spectrum, notice: 'Spectrum was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /spectrums/1
  def update
    if @spectrum.update(spectrum_params)
      redirect_to @spectrum, notice: 'Spectrum was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /spectrums/1
  def destroy
    @spectrum.destroy
    redirect_to spectrums_url, notice: 'Spectrum was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_spectrum
      @spectrum = Spectrum.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def spectrum_params
      params.require(:spectrum).permit(:name, :description, :low_label, :high_label)
    end
end
