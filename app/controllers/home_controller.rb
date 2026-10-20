class HomeController < ApplicationController
  def index
    redirect_to shell_landing_path
  end
end
