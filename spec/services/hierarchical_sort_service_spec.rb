require 'rails_helper'

RSpec.describe HierarchicalSortService do
  describe 'initialization' do
    it 'initializes with empty sort params' do
      service = HierarchicalSortService.new
      expect(service.sort_params).to eq([])
    end

    it 'parses string sort params' do
      service = HierarchicalSortService.new('team_name asc,position_name desc')
      expect(service.sort_params).to eq([
        { attribute: 'team_name', direction: 'asc' },
        { attribute: 'position_name', direction: 'desc' }
      ])
    end

    it 'parses array sort params' do
      service = HierarchicalSortService.new([
        { attribute: 'team_name', direction: 'asc' },
        'position_name desc'
      ])
      expect(service.sort_params).to eq([
        { attribute: 'team_name', direction: 'asc' },
        { attribute: 'position_name', direction: 'desc' }
      ])
    end
  end

  describe '#toggle_sort' do
    let(:service) { HierarchicalSortService.new }

    it 'adds new sort at beginning' do
      new_service = service.toggle_sort('team_name')
      expect(new_service.sort_params).to eq([
        { attribute: 'team_name', direction: 'asc' }
      ])
    end

    it 'cycles through sort states for regular attributes' do
      # Start with asc
      service1 = service.toggle_sort('team_name')
      expect(service1.direction_for('team_name')).to eq('asc')

      # Toggle to desc
      service2 = service1.toggle_sort('team_name')
      expect(service2.direction_for('team_name')).to eq('desc')

      # Toggle to inactive (removes from chain)
      service3 = service2.toggle_sort('team_name')
      expect(service3.direction_for('team_name')).to eq('inactive')
      expect(service3.sort_params).to eq([])
    end

    it 'cycles through random states for random attributes' do
      # Start with random
      service1 = service.toggle_sort('random')
      expect(service1.direction_for('random')).to eq('random')

      # Toggle to shuffle
      service2 = service1.toggle_sort('random')
      expect(service2.direction_for('random')).to eq('shuffle')

      # Toggle to inactive
      service3 = service2.toggle_sort('random')
      expect(service3.direction_for('random')).to eq('inactive')
    end

    it 'respects max_levels limit' do
      service = HierarchicalSortService.new([], 2)
      
      # Add first sort
      service = service.toggle_sort('team_name')
      # Add second sort
      service = service.toggle_sort('position_name')
      # Add third sort (should remove oldest)
      service = service.toggle_sort('first_name')
      
      expect(service.sort_params.length).to eq(2)
      expect(service.sort_params[0][:attribute]).to eq('first_name')
      expect(service.sort_params[1][:attribute]).to eq('position_name')
    end
  end

  describe '#to_ransack_sorts' do
    it 'converts to ransack format' do
      service = HierarchicalSortService.new('team_name asc,position_name desc')
      expect(service.to_ransack_sorts).to eq(['team_name asc', 'position_name desc'])
    end

    it 'excludes random sorts from ransack' do
      service = HierarchicalSortService.new('team_name asc,random,position_name desc')
      expect(service.to_ransack_sorts).to eq(['team_name asc', 'position_name desc'])
    end

    it 'excludes inactive sorts' do
      service = HierarchicalSortService.new([
        { attribute: 'team_name', direction: 'asc' },
        { attribute: 'position_name', direction: 'inactive' }
      ])
      expect(service.to_ransack_sorts).to eq(['team_name asc'])
    end
  end

  describe '#random_active?' do
    it 'returns true when random sort is active' do
      service = HierarchicalSortService.new('random')
      expect(service.random_active?).to be true
    end

    it 'returns true when shuffle sort is active' do
      service = HierarchicalSortService.new('shuffle')
      expect(service.random_active?).to be true
    end

    it 'returns false when no random sorts are active' do
      service = HierarchicalSortService.new('team_name asc')
      expect(service.random_active?).to be false
    end
  end

  describe '#priority_for' do
    it 'returns correct priority order' do
      service = HierarchicalSortService.new('team_name asc,position_name desc,first_name asc')
      
      expect(service.priority_for('team_name')).to eq(1)
      expect(service.priority_for('position_name')).to eq(2)
      expect(service.priority_for('first_name')).to eq(3)
      expect(service.priority_for('last_name')).to be_nil
    end
  end

  describe '#to_param' do
    it 'converts to URL parameter format' do
      service = HierarchicalSortService.new([
        { attribute: 'team_name', direction: 'asc' },
        { attribute: 'position_name', direction: 'desc' }
      ])
      expect(service.to_param).to eq('team_name asc,position_name desc')
    end

    it 'returns empty string when no active sorts' do
      service = HierarchicalSortService.new
      expect(service.to_param).to eq('')
    end
  end

  describe '.from_params' do
    it 'creates service from request params' do
      params = { sort: 'team_name asc,position_name desc' }
      service = HierarchicalSortService.from_params(params)
      
      expect(service.sort_params).to eq([
        { attribute: 'team_name', direction: 'asc' },
        { attribute: 'position_name', direction: 'desc' }
      ])
    end

    it 'handles missing sort param' do
      params = { other: 'value' }
      service = HierarchicalSortService.from_params(params)
      
      expect(service.sort_params).to eq([])
    end
  end
end