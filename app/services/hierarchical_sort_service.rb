class HierarchicalSortService
  # Manages hierarchical sorting with three states per attribute: asc, desc, inactive
  # Supports arbitrary depth and special handling for random/shuffle
  
  SORT_STATES = %w[asc desc inactive].freeze
  RANDOM_STATES = %w[random shuffle inactive].freeze
  
  attr_reader :sort_params, :max_levels
  
  def initialize(sort_params = [], max_levels = 3)
    @sort_params = parse_sort_params(sort_params)
    @max_levels = max_levels
  end
  
  # Parse sort parameters from various input formats
  def parse_sort_params(params)
    case params
    when String
      # Handle comma-separated string like "team_name asc,position_name desc,random"
      params.split(',').map { |p| parse_single_sort(p.strip) }.compact
    when Array
      # Handle array of sort objects or strings
      params.map { |p| parse_single_sort(p) }.compact
    when Hash
      # Handle hash format like { team_name: 'asc', position_name: 'desc' }
      params.map { |attr, dir| { attribute: attr.to_s, direction: dir.to_s } }
    else
      []
    end
  end
  
  # Parse a single sort parameter
  def parse_single_sort(param)
    case param
    when Hash
      { attribute: param[:attribute] || param['attribute'], direction: param[:direction] || param['direction'] }
    when String
      parts = param.split
      attribute = parts[0]
      direction = parts[1] || 'asc'
      { attribute: attribute, direction: direction } if attribute
    else
      nil
    end
  end
  
  # Toggle the sort state for a given attribute
  def toggle_sort(attribute)
    new_params = sort_params.dup
    existing_index = find_sort_index(attribute)
    
    if existing_index
      # Attribute exists, cycle to next state
      current_sort = new_params[existing_index]
      new_direction = next_sort_state(current_sort[:direction], attribute)
      
      if new_direction == 'inactive'
        # Remove from sort chain and compact
        new_params.delete_at(existing_index)
      else
        # Update direction
        new_params[existing_index][:direction] = new_direction
      end
    else
      # New attribute, add to front of chain (highest priority)
      if new_params.length >= max_levels
        # Remove last item to make room
        new_params.pop
      end
      new_params.unshift({ attribute: attribute.to_s, direction: first_sort_state(attribute) })
    end
    
    HierarchicalSortService.new(new_params, max_levels)
  end
  
  # Get the next sort state for an attribute
  def next_sort_state(current_direction, attribute)
    states = sort_states_for_attribute(attribute)
    current_index = states.index(current_direction) || -1
    states[(current_index + 1) % states.length]
  end
  
  # Get the first sort state for an attribute
  def first_sort_state(attribute)
    sort_states_for_attribute(attribute).first
  end
  
  # Get available sort states for an attribute
  def sort_states_for_attribute(attribute)
    if random_attribute?(attribute)
      RANDOM_STATES
    else
      SORT_STATES
    end
  end
  
  # Check if an attribute is a random-type attribute
  def random_attribute?(attribute)
    %w[random shuffle].include?(attribute.to_s)
  end
  
  # Find the index of a sort parameter by attribute
  def find_sort_index(attribute)
    sort_params.find_index { |p| p[:attribute] == attribute.to_s }
  end
  
  # Get the current direction for an attribute
  def direction_for(attribute)
    sort = sort_params.find { |p| p[:attribute] == attribute.to_s }
    sort ? sort[:direction] : 'inactive'
  end
  
  # Check if an attribute is currently being sorted
  def sorting?(attribute)
    direction_for(attribute) != 'inactive'
  end
  
  # Get the priority level (1-based) of an attribute in the sort chain
  def priority_for(attribute)
    index = find_sort_index(attribute)
    index ? index + 1 : nil
  end
  
  # Convert to Ransack-compatible sort array
  def to_ransack_sorts
    sort_params.filter_map do |sort|
      next if sort[:direction] == 'inactive'
      next if random_attribute?(sort[:attribute])
      
      "#{sort[:attribute]} #{sort[:direction]}"
    end
  end
  
  # Check if random sorting is active
  def random_active?
    sort_params.any? { |p| random_attribute?(p[:attribute]) && p[:direction] != 'inactive' }
  end
  
  # Get the current random mode
  def random_mode
    random_sort = sort_params.find { |p| random_attribute?(p[:attribute]) && p[:direction] != 'inactive' }
    random_sort ? random_sort[:direction] : nil
  end
  
  # Convert to URL parameter format
  def to_param
    return '' if sort_params.empty?
    
    sort_params.filter_map do |sort|
      next if sort[:direction] == 'inactive'
      "#{sort[:attribute]} #{sort[:direction]}"
    end.join(',')
  end
  
  # Create a new service with updated sort parameter
  def self.from_params(params, max_levels = 3)
    sort_string = params[:sort] || params['sort'] || ''
    new(sort_string, max_levels)
  end
  
  # Generate SQL ORDER BY clause for non-Ransack usage
  def to_sql_order
    clauses = []
    
    sort_params.each do |sort|
      next if sort[:direction] == 'inactive'
      
      if random_attribute?(sort[:attribute])
        case sort[:direction]
        when 'random'
          clauses << 'RANDOM()'
        when 'shuffle'
          # Different random seed for shuffle vs random
          clauses << 'RANDOM()'
        end
      else
        direction = sort[:direction].upcase
        clauses << "#{sort[:attribute]} #{direction}"
      end
    end
    
    clauses.empty? ? nil : clauses.join(', ')
  end
  
  # Debug representation
  def inspect
    "#<HierarchicalSortService sorts=#{sort_params} max_levels=#{max_levels}>"
  end
end