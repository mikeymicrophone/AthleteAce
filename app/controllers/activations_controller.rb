class ActivationsController < ApplicationController
  include Filterable
  include FilterLoader
  before_action :set_activation, only: %i[show edit update destroy]

  def index
    # Load current filters and set related instance variables
    @current_filters = load_current_filters

    # Build the base query using the filters
    base_query = apply_filter :activations

    # Add includes for efficient queries
    base_query = base_query.includes(:contract, :campaign,
                                   contract: [:player, :team],
                                   campaign: [:season, season: :league])

    # Apply ordering - activations sorted by start date descending by default
    @activations = base_query.order(start_date: :desc, created_at: :desc)

    # Load filter options for selector UI
    @filter_options = load_filter_options

    # Paginate the results
    @pagy, @activations = pagy(@activations, items: params[:per_page] || 20)
  end

  def show
    # Load any filters that were applied when navigating to this show page
    load_current_filters

    # Set up filter options for navigation to related resources
    load_filter_options

    # Create a filtered breadcrumb for this activation
    @filtered_breadcrumb = build_filtered_breadcrumb @activation, @current_filters
  end

  def new
    @activation = Activation.new
  end

  def edit
  end

  def create
    @activation = Activation.new(activation_params)

    respond_to do |format|
      if @activation.save
        format.html { redirect_to @activation, notice: "Activation was successfully created." }
        format.json { render :show, status: :created, location: @activation }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @activation.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @activation.update(activation_params)
        format.html { redirect_to @activation, notice: "Activation was successfully updated." }
        format.json { render :show, status: :ok, location: @activation }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @activation.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @activation.destroy!

    respond_to do |format|
      format.html { redirect_to activations_path, status: :see_other, notice: "Activation was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_activation
    @activation = Activation.find(params.expect(:id))
  end

  def activation_params
    params.expect(activation: [:contract_id, :campaign_id, :start_date, :end_date, :details])
  end
end