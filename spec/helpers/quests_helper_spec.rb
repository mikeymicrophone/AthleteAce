require 'rails_helper'

RSpec.describe QuestsHelper, type: :helper do
  describe '#begin_quest_button' do
    let(:quest) { create(:quest, name: 'Test Quest') }
    let(:ace) { create(:ace) }
    
    before do
      allow(helper).to receive(:ace_signed_in?).and_return(true)
      allow(helper).to receive(:current_ace).and_return(ace)
    end
    
    context 'when ace has not started the quest' do
      it 'renders a Begin Quest button' do
        button = helper.begin_quest_button(quest)
        expect(button).to have_selector('button[type="submit"]')
        expect(button).to have_content('Begin Quest')
        expect(button).to have_selector('i.fa-solid.fa-flag')
      end
      
      it 'includes custom classes when provided' do
        button = helper.begin_quest_button(quest, class: 'custom-class')
        expect(button).to have_selector('button.custom-class')
      end
    end
    
    context 'when ace has already started the quest' do
      before do
        create(:goal, ace: ace, quest: quest)
      end
      
      it 'renders a Continue Quest link' do
        button = helper.begin_quest_button(quest)
        expect(button).to have_selector('a')
        expect(button).to have_content('Continue Quest')
        expect(button).to have_selector('i.fa-solid.fa-check')
      end
    end
    
    context 'when ace is not signed in' do
      before do
        allow(helper).to receive(:ace_signed_in?).and_return(false)
      end
      
      it 'returns nil' do
        expect(helper.begin_quest_button(quest)).to be_nil
      end
    end
  end
  
  describe '#quest_participants_count' do
    let(:quest) { create(:quest) }
    
    it 'returns 0 when no participants' do
      expect(helper.quest_participants_count(quest)).to eq(0)
    end
    
    it 'returns the correct count when there are participants' do
      create_list(:goal, 3, quest: quest)
      expect(helper.quest_participants_count(quest)).to eq(3)
    end
  end
  
  describe '#quest_participants_badge' do
    let(:quest) { create(:quest) }
    
    before do
      create_list(:goal, 2, quest: quest)
    end
    
    it 'renders a badge with the correct count' do
      badge = helper.quest_participants_badge(quest)
      expect(badge).to have_selector('span.inline-flex')
      expect(badge).to have_selector('i.fa-solid.fa-users')
      expect(badge).to have_content('2 participants')
    end
    
    it 'uses singular form for one participant' do
      quest.goals.first.destroy
      badge = helper.quest_participants_badge(quest)
      expect(badge).to have_content('1 participant')
    end
  end
end
