require "rails_helper"

RSpec.describe "Read-only resource routes", type: :routing do
  it "does not route writes to players or teams" do
    expect(post: "/players").not_to be_routable
    expect(patch: "/players/1").not_to be_routable
    expect(delete: "/players/1").not_to be_routable
    expect(delete: "/teams/1").not_to be_routable
    expect(delete: "/divisions/1").not_to be_routable
  end

  it "does not route writes through filtered paths" do
    expect(post: "/teams/1/players").not_to be_routable
    expect(patch: "/teams/1/players/2").not_to be_routable
    expect(delete: "/teams/1/players/2").not_to be_routable
    expect(delete: "/sports/1/teams/2").not_to be_routable
    expect(get: "/teams/1/players/new").to route_to("players#show", team_id: "1", id: "new")
  end

  it "keeps filtered index and show routes" do
    expect(get: "/teams/1/players").to route_to("players#index", team_id: "1")
    expect(get: "/teams/1/players/2").to route_to("players#show", team_id: "1", id: "2")
  end

  it "keeps nested rating routes" do
    expect(post: "/players/1/ratings").to route_to("ratings#create", player_id: "1")
    expect(get: "/teams/1/ratings/for_spectrums").to route_to("ratings#for_spectrums", team_id: "1")
  end
end
