class ContractsController < ApplicationController
  include Filterable
  include FilterLoader
  before_action :set_contract, only: %i[show edit update destroy]

  def index
    # Load current filters and set related instance variables
    @current_filters = load_current_filters

    # Build the base query using the filters
    base_query = apply_filter :contracts

    # Add includes for efficient queries
    base_query = base_query.includes(:player, :team, :activations, 
                                   player: :team, 
                                   team: [:league, league: :sport])

    # Apply ordering - contracts sorted by start date descending by default
    @contracts = base_query.order(start_date: :desc, created_at: :desc)

    # Load filter options for selector UI
    @filter_options = load_filter_options

    # Paginate the results
    @pagy, @contracts = pagy(@contracts, items: params[:per_page] || 20)
  end

  def show
    # Load any filters that were applied when navigating to this show page
    load_current_filters

    # Set up filter options for navigation to related resources
    load_filter_options

    # Create a filtered breadcrumb for this contract
    @filtered_breadcrumb = build_filtered_breadcrumb @contract, @current_filters
  end

  def new
    @contract = Contract.new
  end

  def edit
  end

  def create
    @contract = Contract.new(contract_params)

    respond_to do |format|
      if @contract.save
        format.html { redirect_to @contract, notice: "Contract was successfully created." }
        format.json { render :show, status: :created, location: @contract }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @contract.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @contract.update(contract_params)
        format.html { redirect_to @contract, notice: "Contract was successfully updated." }
        format.json { render :show, status: :ok, location: @contract }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @contract.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @contract.destroy!

    respond_to do |format|
      format.html { redirect_to contracts_path, status: :see_other, notice: "Contract was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_contract
    @contract = Contract.find(params.expect(:id))
  end

  def contract_params
    params.expect(contract: [:player_id, :team_id, :start_date, :end_date, :total_dollar_value, :details])
  end
end