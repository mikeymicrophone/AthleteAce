require 'rails_helper'

RSpec.describe "/goals", type: :request do
  let(:ace) { create(:ace) }
  let(:quest) { create(:quest) }
  let(:valid_attributes) { { ace: ace, quest: quest, status: 'in_progress', progress: 1 } }

  before do
    sign_in ace
  end

  describe "GET /index" do
    it "renders a successful response" do
      Goal.create! valid_attributes
      get goals_url
      expect(response).to be_successful
      expect(response.body).to include("My Goals")
    end

    it "displays goals grouped by status" do
      goal1 = Goal.create!(valid_attributes.merge(status: 'in_progress'))
      goal2 = Goal.create!(valid_attributes.merge(quest: create(:quest), status: 'completed'))
      
      get goals_url
      expect(response).to be_successful
      expect(response.body).to include("In Progress Goals")
      expect(response.body).to include("Completed Goals")
    end

    it "shows empty state when no goals exist" do
      get goals_url
      expect(response).to be_successful
      expect(response.body).to include("No goals yet")
      expect(response.body).to include("Browse Quests")
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      goal = Goal.create! valid_attributes
      get goal_url(goal)
      expect(response).to be_successful
      expect(response.body).to include(goal.quest.name)
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested goal" do
      goal = Goal.create! valid_attributes
      expect {
        delete goal_url(goal)
      }.to change(Goal, :count).by(-1)
    end

    it "redirects to the quests list" do
      goal = Goal.create! valid_attributes
      delete goal_url(goal)
      expect(response).to redirect_to(quests_path)
    end
  end
end