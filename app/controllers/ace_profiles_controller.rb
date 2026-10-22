class AceProfilesController < ApplicationController
  before_action :authenticate_ace!

  def show
    return head :forbidden unless current_ace.can_moderate?

    @ace = Ace.find params[:id]
    @submissions = Moderation::Queue::TYPES.values.flat_map do |model|
      model.where(created_by: @ace).order(created_at: :desc, id: :desc).limit(10).to_a
    end.sort_by { |record| [ record.created_at, record.id ] }.reverse.first(10)
  end
end
