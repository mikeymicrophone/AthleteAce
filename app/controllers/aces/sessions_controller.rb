class Aces::SessionsController < Devise::SessionsController
  before_action :confirm_local_account, only: :create

  def create
    super { |ace| SignInEvent.record!(ace, request, outcome: "success") }
  end

  private

  def confirm_local_account
    return unless Rails.env.development? && request.host.end_with?(".test")

    account = Ace.find_for_database_authentication(email: sign_in_params[:email])
    return unless account && !account.suspended? && !account.confirmed? && account.valid_password?(sign_in_params[:password])

    account.skip_confirmation!
    account.save!
  end
end
