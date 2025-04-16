require "rails_helper"

RSpec.describe SportsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/sports").to route_to("sports#index")
    end

    it "routes to #new" do
      expect(get: "/sports/new").to route_to("sports#new")
    end

    it "routes to #show" do
      expect(get: "/sports/1").to route_to("sports#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/sports/1/edit").to route_to("sports#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/sports").to route_to("sports#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/sports/1").to route_to("sports#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/sports/1").to route_to("sports#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/sports/1").to route_to("sports#destroy", id: "1")
    end
  end
end
