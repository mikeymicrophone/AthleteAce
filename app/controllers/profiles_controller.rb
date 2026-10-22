class ProfilesController < ApplicationController
  skip_before_action :require_ace_identity
  before_action :authenticate_ace!

  def show
    redirect_to edit_profile_path if current_ace.username.blank?
  end

  def edit
    @ace = current_ace
  end

  def update
    @ace = current_ace
    saved = @ace.with_lock do
      @ace.assign_attributes profile_params
      @ace.save context: :profile
    end
    if saved
      redirect_to session.delete(:profile_return_to) || profile_path, status: :see_other, notice: "Profile saved."
    else
      render :edit, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique
    @ace.errors.add :username, :taken
    render :edit, status: :unprocessable_content
  end

  private

  def profile_params
    params.require(:ace).permit(:username, :display_name, :avatar_color, :time_zone)
  end
end
