require "rails_helper"

RSpec.describe FederationsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/federations").to route_to("federations#index")
    end

    it "routes to #new" do
      expect(get: "/federations/new").to route_to("federations#new")
    end

    it "routes to #show" do
      expect(get: "/federations/1").to route_to("federations#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/federations/1/edit").to route_to("federations#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/federations").to route_to("federations#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/federations/1").to route_to("federations#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/federations/1").to route_to("federations#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/federations/1").to route_to("federations#destroy", id: "1")
    end
  end
end
