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

    it 'parses random sorts correctly' do
      service = HierarchicalSortService.new('team_name asc,random,shuffle')
      expect(service.sort_params).to eq([
        { attribute: 'team_name', direction: 'asc' },
        { attribute: 'random', direction: 'random' },
        { attribute: 'shuffle', direction: 'shuffle' }
      ])
    end
  end

  describe '#toggle_sort' do
    let(:service) { HierarchicalSortService.new }

    it 'adds new sort at end (refines existing)' do
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
      # Add third sort (should remove last item to make room)
      service = service.toggle_sort('first_name')
      
      expect(service.sort_params.length).to eq(2)
      expect(service.sort_params[0][:attribute]).to eq('team_name')  # First remains first
      expect(service.sort_params[1][:attribute]).to eq('first_name') # Last added replaces position_name
    end

    it 'maintains hierarchy order when toggling existing sorts' do
      service = HierarchicalSortService.new
      
      # Build a hierarchy: team -> position -> first_name
      service = service.toggle_sort('team_name')      # 1st level
      service = service.toggle_sort('position_name')  # 2nd level  
      service = service.toggle_sort('first_name')     # 3rd level
      
      # Toggle team direction (should stay in 1st position)
      service = service.toggle_sort('team_name')
      
      expect(service.sort_params).to eq([
        { attribute: 'team_name', direction: 'desc' },     # Still 1st, now desc
        { attribute: 'position_name', direction: 'asc' },  # Still 2nd
        { attribute: 'first_name', direction: 'asc' }      # Still 3rd
      ])
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

  describe '#to_sql_order' do
    it 'generates SQL with proper table references' do
      service = HierarchicalSortService.new('team_name asc,position_name desc')
      expect(service.to_sql_order).to eq('teams.mascot ASC, positions.name DESC')
    end

    it 'integrates random into hierarchy' do
      service = HierarchicalSortService.new('team_name asc,random,position_name desc')
      expect(service.to_sql_order).to eq('teams.mascot ASC, RANDOM(), positions.name DESC')
    end

    it 'handles shuffle in hierarchy' do
      service = HierarchicalSortService.new('team_name asc,shuffle')
      expect(service.to_sql_order).to eq('teams.mascot ASC, RANDOM()')
    end

    it 'maps player attributes correctly' do
      service = HierarchicalSortService.new('first_name asc,last_name desc')
      expect(service.to_sql_order).to eq('players.first_name ASC, players.last_name DESC')
    end

    it 'maps league and sport attributes correctly' do
      service = HierarchicalSortService.new('league_name asc,sport_name desc')
      expect(service.to_sql_order).to eq('leagues.name ASC, sports.name DESC')
    end

    it 'returns nil for empty sorts' do
      service = HierarchicalSortService.new
      expect(service.to_sql_order).to be_nil
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
      
      expect(service.priority_for('team_name')).to eq(1)      # First clicked = highest priority
      expect(service.priority_for('position_name')).to eq(2)  # Second clicked = refines first
      expect(service.priority_for('first_name')).to eq(3)     # Third clicked = refines second
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