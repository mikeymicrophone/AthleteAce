require 'rails_helper'

RSpec.describe QuestsController, type: :controller do
  let(:ace) { create(:ace) }
  
  describe "GET #random" do
    context "when user is not signed in" do
      it "redirects to the sign in page" do
        get :random
        expect(response).to redirect_to(new_ace_session_path)
      end
    end
    
    context "when user is signed in" do
      before do
        sign_in ace
      end
      
      context "when there are available quests" do
        before do
          create_list(:quest, 5)
        end
        
        it "assigns a random quest" do
          get :random
          expect(assigns(:quest)).to be_a(Quest)
          expect(assigns(:random_mode)).to be true
        end
        
        it "renders the show template" do
          get :random
          expect(response).to render_template(:show)
        end
        
        context "when user has already started some quests" do
          before do
            quests = Quest.all.to_a
            # Start 3 of the 5 quests
            quests.take(3).each do |quest|
              ace.adopt_quest(quest)
            end
          end
          
          it "assigns a random quest the user hasn't started yet" do
            get :random
            expect(assigns(:quest)).to be_a(Quest)
            expect(ace.quests).not_to include(assigns(:quest))
          end
        end
      end
      
      context "when there are no quests available" do
        it "redirects to the quests index with an alert" do
          get :random
          expect(response).to redirect_to(quests_path)
          expect(flash[:alert]).to eq("No quests available.")
        end
      end
      
      context "when the user has started all available quests" do
        before do
          quests = create_list(:quest, 3)
          quests.each do |quest|
            ace.adopt_quest(quest)
          end
        end
        
        it "assigns a random quest from the ones the user has already started" do
          get :random
          expect(assigns(:quest)).to be_a(Quest)
          expect(ace.quests).to include(assigns(:quest))
        end
      end
    end
  end
end
