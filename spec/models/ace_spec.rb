require 'rails_helper'

RSpec.describe Ace, type: :model do
  # Associations
  describe 'associations' do
    it { should have_many(:goals).dependent(:destroy) }
    it { should have_many(:quests).through(:goals) }
    it { should have_many(:ratings).dependent(:destroy) }
  end

  # Factory
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:ace)).to be_valid
    end

    it 'has a valid factory with goals' do
      ace = create(:ace, :with_goals, goals_count: 3)
      expect(ace.goals.count).to eq(3)
      expect(ace.quests.count).to eq(3)
    end
  end

  # Methods
  describe '#adopt_quest' do
    let(:ace) { create(:ace) }
    let(:quest) { create(:quest) }

    it 'creates a goal for the quest' do
      expect {
        ace.adopt_quest(quest)
      }.to change { ace.goals.count }.by(1)
      
      goal = ace.goals.last
      expect(goal.quest).to eq(quest)
    end

    it 'does not create duplicate goals for the same quest' do
      ace.adopt_quest(quest)
      
      expect {
        ace.adopt_quest(quest)
      }.not_to change { ace.goals.count }
    end

    it 'returns the goal' do
      goal = ace.adopt_quest(quest)
      expect(goal).to be_a(Goal)
      expect(goal.ace).to eq(ace)
      expect(goal.quest).to eq(quest)
    end
  end

  describe '#abandon_quest' do
    let(:ace) { create(:ace) }
    let(:quest) { create(:quest) }
    let!(:goal) { create(:goal, ace: ace, quest: quest) }

    it 'removes the goal for the quest' do
      expect {
        ace.abandon_quest(quest)
      }.to change { ace.goals.count }.by(-1)
      
      expect(ace.quests).not_to include(quest)
    end

    it 'does nothing if the ace is not on the quest' do
      other_quest = create(:quest)
      
      expect {
        ace.abandon_quest(other_quest)
      }.not_to change { ace.goals.count }
    end
  end
end
