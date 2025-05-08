require 'rails_helper'

RSpec.describe GoalsController, type: :controller do
  let(:ace) { create(:ace) }
  let(:quest) { create(:quest) }
  
  describe "POST #create" do
    context "when user is not signed in" do
      it "redirects to the sign in page" do
        post :create, params: { quest_id: quest.id }
        expect(response).to redirect_to(new_ace_session_path)
      end
    end
    
    context "when user is signed in" do
      before do
        sign_in ace
      end
      
      it "creates a new goal" do
        expect {
          post :create, params: { quest_id: quest.id }
        }.to change(Goal, :count).by(1)
      end
      
      it "associates the goal with the current ace and quest" do
        post :create, params: { quest_id: quest.id }
        goal = Goal.last
        expect(goal.ace).to eq(ace)
        expect(goal.quest).to eq(quest)
      end
      
      it "redirects to the quest page with a success notice" do
        post :create, params: { quest_id: quest.id }
        expect(response).to redirect_to(quest)
        expect(flash[:notice]).to eq("You've successfully adopted this quest!")
      end
      
      context "when the ace has already adopted the quest" do
        before do
          ace.adopt_quest(quest)
        end
        
        it "does not create a duplicate goal" do
          expect {
            post :create, params: { quest_id: quest.id }
          }.not_to change(Goal, :count)
        end
        
        it "still redirects to the quest page" do
          post :create, params: { quest_id: quest.id }
          expect(response).to redirect_to(quest)
        end
      end
    end
  end
  
  describe "DELETE #destroy" do
    let!(:goal) { create(:goal, ace: ace, quest: quest) }
    
    context "when user is not signed in" do
      it "redirects to the sign in page" do
        delete :destroy, params: { id: goal.id }
        expect(response).to redirect_to(new_ace_session_path)
      end
    end
    
    context "when user is signed in" do
      before do
        sign_in ace
      end
      
      it "destroys the goal" do
        expect {
          delete :destroy, params: { id: goal.id }
        }.to change(Goal, :count).by(-1)
      end
      
      it "redirects to the quests index with a notice" do
        delete :destroy, params: { id: goal.id }
        expect(response).to redirect_to(quests_path)
        expect(flash[:notice]).to eq("You've abandoned the quest.")
      end
      
      context "when trying to delete another ace's goal" do
        let(:other_ace) { create(:ace) }
        let!(:other_goal) { create(:goal, ace: other_ace, quest: quest) }
        
        it "does not destroy the goal" do
          expect {
            delete :destroy, params: { id: other_goal.id }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
