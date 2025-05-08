require 'rails_helper'

RSpec.describe Quest, type: :model do
  # Associations
  describe 'associations' do
    it { should have_many(:highlights).dependent(:destroy) }
    it { should have_many(:achievements).through(:highlights) }
    it { should have_many(:goals).dependent(:destroy) }
    it { should have_many(:aces).through(:goals) }
  end

  # Validations
  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  # Factory
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:quest)).to be_valid
    end

    it 'has a valid factory with achievements' do
      quest = create(:quest, :with_achievements, achievements_count: 3, required_count: 2)
      expect(quest.highlights.count).to eq(3)
      expect(quest.highlights.required.count).to eq(2)
      expect(quest.highlights.optional.count).to eq(1)
    end

    it 'has a valid factory with participants' do
      quest = create(:quest, :with_participants, participants_count: 3)
      expect(quest.goals.count).to eq(3)
      expect(quest.aces.count).to eq(3)
    end
  end

  # Methods
  describe '#add_achievement' do
    let(:quest) { create(:quest) }
    let(:achievement) { create(:achievement) }

    it 'adds an achievement to the quest' do
      expect {
        quest.add_achievement(achievement, position: 1, required: true)
      }.to change { quest.highlights.count }.by(1)
      
      highlight = quest.highlights.last
      expect(highlight.achievement).to eq(achievement)
      expect(highlight.position).to eq(1)
      expect(highlight.required).to be true
    end

    it 'adds an optional achievement to the quest' do
      quest.add_achievement(achievement, position: 2, required: false)
      highlight = quest.highlights.last
      expect(highlight.required).to be false
    end
  end

  describe '#remove_achievement' do
    let(:quest) { create(:quest) }
    let(:achievement) { create(:achievement) }

    before do
      quest.add_achievement(achievement)
    end

    it 'removes an achievement from the quest' do
      expect {
        quest.remove_achievement(achievement)
      }.to change { quest.highlights.count }.by(-1)
      
      expect(quest.achievements).not_to include(achievement)
    end
  end

  # Participant count
  describe '#participant_count' do
    let(:quest) { create(:quest) }
    
    it 'returns the number of aces on the quest' do
      create_list(:goal, 3, quest: quest)
      expect(quest.goals.count).to eq(3)
    end
  end
end
