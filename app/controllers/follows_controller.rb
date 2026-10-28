class FollowsController < ApplicationController
  before_action :authenticate_ace!

  def create
    type = { "Team" => Team, "Player" => Player }[params[:followable_type]]
    raise ActiveRecord::RecordNotFound unless type

    record = type.find(params[:followable_id])
    current_ace.follows.create_or_find_by!(followable: record)
    respond_with_button(record)
  end

  def destroy
    follow = current_ace.follows.find(params[:id])
    record = follow.followable
    follow.destroy!
    respond_with_button(record, removed: follow)
  end

  private

  def respond_with_button(record, removed: nil)
    respond_to do |format|
      format.html { redirect_to polymorphic_path(record), status: :see_other }
      format.turbo_stream do
        updates = [ turbo_stream.replace(helpers.dom_id(record, :follow),
          partial: "follows/button", locals: { record: record }) ]
        updates << turbo_stream.remove(helpers.dom_id(removed)) if removed
        render turbo_stream: updates
      end
    end
  end
end
