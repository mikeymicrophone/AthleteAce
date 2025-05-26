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
      # Create a confirmed ace (user) for authentication
      let(:ace) { create(:ace) }
      
      # Create a quest with a team for testing
      let(:sport) { create(:sport) }
      let(:league) { create(:league, sport: sport) }
      let(:team) { create(:team, league: league) }
      let(:quest) { create(:quest) }
      
      before do
        # Set up achievement for the quest that references the team
        achievement = create(:achievement, target: team)
        quest.add_achievement(achievement)
        
        # Sign in the user and have them adopt the quest
        sign_in ace
        ace.adopt_quest(quest)
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
      
      describe 'filtering by conference' do
        let(:sport) { create(:sport) }
        let(:league) { create(:league, sport: sport) }
        let(:conference) { create(:conference, league: league) }
        let(:other_conference) { create(:conference, league: league) }
        
        let!(:conference_team1) { create(:team, conference: conference) }
        let!(:conference_team2) { create(:team, conference: conference) }
        let!(:other_conference_team) { create(:team, conference: other_conference) }
        
        let!(:player1) { create(:player, team: conference_team1) }
        let!(:player2) { create(:player, team: conference_team2) }
        let!(:other_player) { create(:player, team: other_conference_team) }
        
        it 'restricts players to the specified conference' do
          get :team_match, params: { conference_id: conference.id }
          
          # The current player should be from one of the conference teams
          expect(assigns(:current_player).team.conference_id).to eq(conference.id)
          
          # All team choices should be from the conference
          expect(assigns(:team_choices).map(&:conference_id).uniq).to eq([conference.id])
          
          # The correct team should be from the conference
          expect(assigns(:correct_team).conference_id).to eq(conference.id)
        end
      end
      
      describe 'filtering by league' do
        let(:sport) { create(:sport) }
        let(:league1) { create(:league, sport: sport) }
        let(:league2) { create(:league, sport: sport) }
        
        let!(:league1_team1) { create(:team, league: league1) }
        let!(:league1_team2) { create(:team, league: league1) }
        let!(:league2_team) { create(:team, league: league2) }
        
        let!(:player1) { create(:player, team: league1_team1) }
        let!(:player2) { create(:player, team: league1_team2) }
        let!(:other_player) { create(:player, team: league2_team) }
        
        it 'restricts players to the specified league' do
          get :team_match, params: { league_id: league1.id }
          
          # The current player should be from one of the league teams
          expect(assigns(:current_player).team.league_id).to eq(league1.id)
          
          # All team choices should be from the league
          expect(assigns(:team_choices).map(&:league_id).uniq).to eq([league1.id])
          
          # The correct team should be from the league
          expect(assigns(:correct_team).league_id).to eq(league1.id)
        end
      end
      
      describe 'filtering by team' do
        let(:team) { create(:team) }
        let!(:player) { create(:player, team: team) }
        
        it 'restricts players to the specified team' do
          get :team_match, params: { team_id: team.id }
          
          # The current player should be from the specified team
          expect(assigns(:current_player).team_id).to eq(team.id)
          
          # The correct team should be the specified team
          expect(assigns(:correct_team).id).to eq(team.id)
        end
      end
    end
  end
end
