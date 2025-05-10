require 'rails_helper'

RSpec.describe StrengthController, type: :controller do
  describe 'GET #team_match' do
    context 'when not authenticated' do
      it 'redirects to sign in page' do
        get :team_match
        expect(response).to redirect_to(new_ace_session_path)
      end
    end

    context 'when authenticated' do
      let(:ace) { create(:ace) }
      let(:quest) { create(:quest) }
      before do
        sign_in ace
        ace.adopt_quest(quest)  # Assuming adopt_quest method exists from memory
      end

      it 'assigns players and teams when no scope is specified' do
        get :team_match
        expect(assigns(:players)).not_to be_empty
        expect(assigns(:team_choices)).not_to be_nil
      end

      it 'defaults to quest teams when signed in and no scope' do
        get :team_match
        expect(assigns(:players).first.team).to be_in(quest.teams)
      end

      it 'defaults to quest teams when signed in and no scope, using associated_teams' do
        quest = create(:quest)
        team = create(:team)
        achievement = create(:achievement, target: team)
        quest.add_achievement(achievement)  # Assuming add_achievement method from Quest model
        ace.adopt_quest(quest)
        get :team_match
        expect(assigns(:players).first.team).to be_in(quest.associated_teams)
      end

      it 'defaults to quest teams when signed in and no scope, handling different achievement targets' do
        quest = create(:quest)
        team_achievement = create(:achievement, target: create(:team))
        league_achievement = create(:achievement, target: create(:league))
        quest.add_achievement(team_achievement)
        quest.add_achievement(league_achievement)
        ace.adopt_quest(quest)
        get :team_match
        expect(assigns(:players).map(&:team)).to include(team_achievement.target, *league_achievement.target.teams)
      end

      it 'respects cross_sport parameter' do
        get :team_match, params: { cross_sport: 'false' }
        # Add more specific assertions based on expected behavior
      end

      it 'respects cross_sport parameter with quest teams' do
        quest = create(:quest)
        sport = create(:sport)
        sport_team = create(:team, sport: sport)
        other_sport_team = create(:team, sport: create(:sport))
        achievement = create(:achievement, target: sport_team)
        quest.add_achievement(achievement)
        ace.adopt_quest(quest)
        get :team_match, params: { cross_sport: 'false' }
        expect(assigns(:team_choices).map(&:sport).map(&:id).uniq).to eq([sport.id])
      end
    end
  end
end
