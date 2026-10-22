class ShoutOutDraftsController < ApplicationController
  before_action :remember_entry, only: :new
  before_action :authenticate_ace!
  before_action :private_response
  before_action :set_draft, only: [ :edit, :update, :destroy ]

  def index
    @pagy, @drafts = pagy(current_ace.shout_out_drafts.includes(:target).order(updated_at: :desc, id: :desc))
  end

  def new
    @draft = current_ace.shout_out_drafts.new(target: selected_target(params))
  end

  def edit
  end

  def create
    @draft = current_ace.shout_out_drafts.new(draft_attributes)
    if @draft.save
      redirect_to edit_shout_out_draft_path(@draft), status: :see_other, notice: "Draft saved. Only you can see it."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @draft.update(draft_attributes)
      redirect_to edit_shout_out_draft_path(@draft), status: :see_other, notice: "Draft saved. Only you can see it."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @draft.destroy!
    redirect_to shout_out_drafts_path, status: :see_other, notice: "Draft deleted."
  end

  def targets
    @search = ShellSearch.new(query: params[:q], side: "feed", ace: current_ace)
    @groups = @search.groups
  end

  private

  def remember_entry
    store_location_for :ace, new_shout_out_draft_path(params.permit(:target_type, :target_id)) unless current_ace
  end

  def private_response
    response.headers["Cache-Control"] = "private, no-store"
  end

  def set_draft
    @draft = current_ace.shout_out_drafts.find(params[:id])
  end

  def selected_target(attributes)
    type = { "Player" => Player, "Team" => Team }[attributes[:target_type]]
    type&.find_by(id: attributes[:target_id])
  end

  def draft_attributes
    attributes = params.require(:shout_out_draft).permit(:message, :target_type, :target_id, :lock_version)
    attributes.slice(:message, :lock_version).merge(target: selected_target(attributes))
  end
end
