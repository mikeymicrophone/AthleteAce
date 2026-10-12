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

      before { sign_in ace }

      def team_with_player(**attributes)
        create(:team, **attributes).tap { |team| create(:player, team: team) }
      end

      def adopt_quest_for(*targets)
        quest = create(:quest)
        targets.each { |target| quest.add_achievement(create(:achievement, target: target)) }
        ace.adopt_quest(quest)
        quest
      end

      it 'redirects when there are no players at all' do
        get :team_match
        expect(response).to redirect_to(strength_path)
      end

      it 'includes the correct team among the choices' do
        team_with_player
        get :team_match
        expect(assigns(:team_choices)).to include(assigns(:correct_team))
        expect(assigns(:correct_team)).to eq(assigns(:current_player).team)
      end

      it 'defaults to quest teams when signed in and no scope' do
        quest_team = team_with_player
        team_with_player
        quest = adopt_quest_for(quest_team)

        get :team_match
        expect(assigns(:current_player).team).to be_in(quest.associated_teams)
      end

      it 'includes teams from league achievements' do
        league = create(:league)
        league_team = team_with_player(league: league)
        team_with_player
        adopt_quest_for(league)

        get :team_match
        expect(assigns(:current_player).team).to eq(league_team)
      end

      it 'keeps quest teams to one sport unless cross_sport is set' do
        adopt_quest_for(team_with_player, team_with_player)

        get :team_match, params: { cross_sport: 'false' }
        expect(assigns(:team_choices).map { |team| team.sport.id }.uniq.size).to eq(1)
      end

      describe 'filtering by conference' do
        let(:conference) { create(:conference) }
        let(:division) { create(:division, conference: conference) }

        before do
          2.times { create(:membership, team: team_with_player(league: conference.league), division: division) }
          create(:membership, team: team_with_player, division: create(:division))
        end

        it 'restricts players and choices to the conference' do
          get :team_match, params: { conference_id: conference.id }

          expect(assigns(:current_player).team.conference).to eq(conference)
          expect(assigns(:team_choices).map(&:conference).uniq).to eq([conference])
        end
      end

      describe 'filtering by league' do
        let(:league) { create(:league) }

        before do
          2.times { team_with_player(league: league) }
          team_with_player
        end

        it 'restricts players and choices to the league' do
          get :team_match, params: { league_id: league.id }

          expect(assigns(:current_player).team.league).to eq(league)
          expect(assigns(:team_choices).map(&:league).uniq).to eq([league])
        end
      end

      describe 'filtering by team' do
        let(:team) { team_with_player }

        it 'restricts players to the specified team' do
          get :team_match, params: { team_id: team.id }

          expect(assigns(:current_player).team).to eq(team)
          expect(assigns(:correct_team)).to eq(team)
        end
      end
    end
  end
end
