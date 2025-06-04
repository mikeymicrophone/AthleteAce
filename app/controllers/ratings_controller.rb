class RatingsController < ApplicationController
  before_action :authenticate_ace!
  before_action :set_rating, only: [:show, :edit, :update, :destroy]
  before_action :set_target, only: [:new, :create]
  before_action :authorize_rating, only: [:edit, :update, :destroy]

  # GET /ratings
  def index
    @ratings = if params[:spectrum_id].present?
      Spectrum.find(params[:spectrum_id]).ratings.active.includes(:target).order(created_at: :desc)
    else
      current_ace.ratings.active.includes(:spectrum, :target).order(created_at: :desc)
    end
  end

  # GET /ratings/1
  def show
  end

  # GET /ratings/new
  # GET /players/1/ratings/new
  # GET /teams/1/ratings/new
  def new
    # Find existing rating or initialize a new one
    @spectrum_id = params[:spectrum_id]
    
    if @spectrum_id.present?
      @spectrum = Spectrum.find(@spectrum_id)
      @rating = current_ace.ratings.active.find_or_initialize_by(target: @target, spectrum: @spectrum)
    else
      @rating = Rating.new(target: @target)
      @spectrums = Spectrum.all
    end
  end

  # GET /ratings/1/edit
  def edit
    @spectrum = @rating.spectrum
  end

  # POST /ratings
  # POST /players/1/ratings
  # POST /teams/1/ratings
  def create
    Rating.transaction do
      # Archive existing active rating if present
      existing = current_ace.ratings.find_by(
        spectrum_id: rating_params[:spectrum_id],
        target_type: rating_params[:target_type],
        target_id: rating_params[:target_id],
        archived: false
      )
      existing&.update!(archived: true) if existing

      # Create new rating
      @rating = current_ace.ratings.create!(rating_params)
    end

    respond_to do |format|
      format.html { redirect_to after_rating_path }
      format.json { render json: { success: true, rating: @rating }, status: :created }
      format.js { head :ok }
    end
  rescue StandardError => e
    Rails.logger.error "Rating creation failed: #{e.message}"
    respond_to do |format|
      format.html do
        @spectrum = Spectrum.find(rating_params[:spectrum_id]) if rating_params[:spectrum_id]
        @spectrums = @spectrum ? [@spectrum] : Spectrum.all
        @rating ||= Rating.new(rating_params)
        @rating.errors.add(:base, e.message)
        render :new, status: :unprocessable_entity
      end
      format.json { render json: { success: false, errors: [e.message] }, status: :unprocessable_entity }
      format.js { head :unprocessable_entity }
    end
  end

  # PATCH/PUT /ratings/1
  def update
    Rating.transaction do
      # Archive existing active rating if present
      existing = current_ace.ratings.find_by(
        spectrum_id: rating_params[:spectrum_id],
        target_type: rating_params[:target_type],
        target_id: rating_params[:target_id],
        archived: false
      )
      existing&.update!(archived: true) if existing

      # Create new rating
      @rating = current_ace.ratings.create!(rating_params)
    end

    redirect_to after_rating_path
  rescue StandardError => e
    Rails.logger.error "Rating update failed: #{e.message}"
    @spectrum = Spectrum.find(rating_params[:spectrum_id]) if rating_params[:spectrum_id]
    @rating ||= Rating.new(rating_params)
    @rating.errors.add(:base, e.message)
    render :edit, status: :unprocessable_entity
  end

  # DELETE /ratings/1
  def destroy
    @rating.destroy
    redirect_to ratings_url, notice: 'Rating was successfully removed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_rating
      @rating = Rating.find(params[:id])
    end
    
    # Set the target for the rating based on the ratable_models configuration
    def set_target
      # Look for any valid target ID parameter
      target_param = find_target_param
      
      if target_param
        model_name, id = target_param
        model_class = model_name.classify.constantize
        @target = model_class.find(id)
        @target_type = model_name.singularize
      else
        # No valid target type found
        redirect_to root_path, alert: 'Invalid target for rating.'
      end
    end
    
    # Find the first valid target parameter in the request
    def find_target_param
      Rails.application.config.ratable_models.each do |model_name|
        param_name = "#{model_name.underscore}_id"
        return [model_name.underscore, params[param_name]] if params[param_name].present?
      end
      nil
    end
    
    # Only allow a list of trusted parameters through.
    def rating_params
      params.require(:rating).permit(:spectrum_id, :value, :notes, :target_id, :target_type)
    end
    
    # Ensure the current ace can only modify their own ratings
    def authorize_rating
      unless @rating.ace == current_ace
        redirect_to ratings_path, alert: "You can only modify your own ratings."
      end
    end
    
    # Determine where to redirect after rating based on target type
    def after_rating_path
      if @target && @target_type && Rails.application.config.ratable_models_hash[@target_type.classify]
        # Dynamically generate the path helper name and call it
        send("#{@target_type}_path", @target)
      else
        ratings_path
      end
    end
end
