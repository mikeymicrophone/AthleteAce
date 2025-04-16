require "rails_helper"

RSpec.describe StadiaController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/stadia").to route_to("stadia#index")
    end

    it "routes to #new" do
      expect(get: "/stadia/new").to route_to("stadia#new")
    end

    it "routes to #show" do
      expect(get: "/stadia/1").to route_to("stadia#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/stadia/1/edit").to route_to("stadia#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/stadia").to route_to("stadia#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/stadia/1").to route_to("stadia#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/stadia/1").to route_to("stadia#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/stadia/1").to route_to("stadia#destroy", id: "1")
    end
  end
end
