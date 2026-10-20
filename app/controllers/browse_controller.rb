class BrowseController < ApplicationController
  GROUPS = {
    "sports" => [ "Sports data", %w[sports leagues conferences divisions teams players stadiums organizations federations organization_affiliations memberships contracts activations] ],
    "places" => [ "Places", %w[countries states cities] ],
    "content" => [ "Quests and ratings", %w[quests goals achievements spectrums ratings] ],
    "time" => [ "Time", %w[years seasons campaigns contests] ]
  }.freeze

  def index
    @groups = params[:section].presence_in(GROUPS.keys) ? GROUPS.slice(params[:section]) : GROUPS
  end
end
