class StatesController < ApplicationController
  include Filterable
  before_action :set_state, only: %i[ show ]

  def index
    @states = apply_filter :states
  end

  def show
  end

  private
    def set_state
      @state = State.find(params.expect(:id))
    end
end
