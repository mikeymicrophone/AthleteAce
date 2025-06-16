class HierarchicalSortService
  # Manages hierarchical sorting with three states per attribute: asc, desc, inactive
  # Supports arbitrary depth and special handling for random/shuffle
  # Hierarchy: First sort clicked becomes primary, subsequent sorts refine beneath it
  
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
      
      # Handle special case where random/shuffle is both attribute and direction
      if %w[random shuffle].include?(attribute) && parts.length == 1
        direction = attribute  # 'random' becomes direction 'random'
      else
        direction = parts[1] || 'asc'
      end
      
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
        # Update direction in place (maintains hierarchy position)
        new_params[existing_index][:direction] = new_direction
      end
    else
      # New attribute, add to end of chain (refines existing sorts)
      # This maintains the hierarchy: first clicked stays primary, new sorts refine it
      if new_params.length >= max_levels
        # Remove last item to make room for new refinement
        new_params.pop
      end
      new_params.push({ attribute: attribute.to_s, direction: first_sort_state(attribute) })
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
  
  # Convert to Ransack-compatible sort array (excludes random sorts)
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

  # Get required joins for current sort parameters
  def required_joins(context = nil)
    # Determine context if not provided
    context ||= infer_table_context.to_sym
    
    sort_params
      .reject { |sort| sort[:direction] == 'inactive' || random_attribute?(sort[:attribute]) }
      .flat_map { |sort| 
        get_required_joins_for_attribute(sort[:attribute], context)
      }
      .uniq
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
  
  # Generate SQL ORDER BY clause that properly handles hierarchical random
  def to_sql_order
    clauses = []
    
    sort_params.each do |sort|
      next if sort[:direction] == 'inactive'
      
      if random_attribute?(sort[:attribute])
        case sort[:direction]
        when 'random'
          # Use a consistent hash-based seed for reproducible results within pagination
          table_id = primary_table_id
          clauses << "MD5(CONCAT(#{table_id}, '#{time_based_seed}'))"
        when 'shuffle'
          # Use a different seed for shuffle to differentiate from random
          table_id = primary_table_id
          clauses << "MD5(CONCAT(#{table_id}, '#{time_based_seed(1)}'))"
        end
      else
        direction = sort[:direction].upcase
        # Map sort attributes to actual database columns/table references
        column_reference = map_sort_attribute_to_column(sort[:attribute])
        clauses << "#{column_reference} #{direction}"
      end
    end
    
    clauses.empty? ? nil : clauses.join(', ')
  end
  
  # Map sort attributes to actual database column references
  def map_sort_attribute_to_column(attribute)
    context = infer_table_context.to_sym
    
    # Try to get from dynamic configuration first
    if defined?(HierarchicalSortConfigBuilder)
      dynamic_config = HierarchicalSortConfigBuilder.build_config
      if dynamic_config[context] && dynamic_config[context][:attributes]
        column_mapping = dynamic_config[context][:attributes][attribute.to_s]
        return column_mapping if column_mapping
      end
    end
    
    # Fallback to legacy mapping or default
    legacy_mapping(attribute) || default_column_mapping(attribute)
  end

  private

  # Get required joins for an attribute in the current context
  def get_required_joins_for_attribute(attribute, context)
    # Try dynamic configuration first
    if defined?(HierarchicalSortConfigBuilder)
      dynamic_config = HierarchicalSortConfigBuilder.build_config
      if dynamic_config[context] && dynamic_config[context][:joins]
        joins_config = dynamic_config[context][:joins][attribute.to_s]
        return joins_config if joins_config
      end
    end
    
    # Fallback to legacy configuration
    legacy_joins = legacy_joins_mapping[attribute.to_s]
    if legacy_joins.is_a?(Hash)
      legacy_joins[context] || []
    else
      legacy_joins || []
    end
  end

  # Legacy mapping for backward compatibility
  def legacy_mapping(attribute)
    all_legacy_mappings[attribute.to_s]
  end

  # Legacy joins mapping for backward compatibility
  def legacy_joins_mapping
    {
      'team_name' => { players: [:team], leagues: [] },
      'league_name' => { players: [team: :league], leagues: [] },
      'sport_name' => { players: [team: [league: :sport]], leagues: [:sport] },
      'position_name' => { players: [:positions], leagues: [] },
      'country_name' => { players: [], leagues: [:country] },
      'alphabetical' => { players: [], leagues: [] },
      'first_name' => { players: [], leagues: [] },
      'last_name' => { players: [], leagues: [] },
      'random' => { players: [], leagues: [] },
      'shuffle' => { players: [], leagues: [] }
    }
  end

  # Handle dynamic attributes with table prefixes
  def default_column_mapping(attribute)
    if attribute.match?(/^league_/)
      "leagues.#{attribute.sub(/^league_/, '')}"
    elsif attribute.match?(/^player_/)
      "players.#{attribute.sub(/^player_/, '')}"
    else
      # Default fallback
      "#{infer_table_context}.#{attribute}"
    end
  end

  # Infer the table context based on the sort parameters
  def infer_table_context
    league_keys = all_legacy_mappings.keys.select { |k| k.match?(/league|country|sport|alphabetical/) }
    player_keys = all_legacy_mappings.keys.select { |k| k.match?(/team|position|first_name|last_name/) }
    
    has_league_attrs = sort_params.any? { |p| league_keys.include?(p[:attribute]) }
    has_player_attrs = sort_params.any? { |p| player_keys.include?(p[:attribute]) }
    
    if has_league_attrs && !has_player_attrs
      'leagues'
    elsif has_player_attrs && !has_league_attrs  
      'players'
    else
      'leagues'
    end
  end

  # Return all legacy mappings as a hash
  def all_legacy_mappings
    {
      'team_name' => 'teams.mascot',
      'first_name' => 'players.first_name',
      'last_name' => 'players.last_name',
      'position_name' => 'positions.name',
      'league_name' => 'leagues.name',
      'alphabetical' => 'leagues.name',
      'country_name' => 'countries.name',
      'sport_name' => 'sports.name'
    }
  end
  
  # Debug representation
  def inspect
    "#<HierarchicalSortService sorts=#{sort_params} max_levels=#{max_levels}>"
  end
  
  # Detailed debug info
  def debug_info
    {
      sort_params: sort_params,
      max_levels: max_levels,
      param_count: sort_params.length,
      directions: sort_params.map { |p| "#{p[:attribute]}:#{p[:direction]}" },
      url_param: to_param,
      random_active: random_active?
    }
  end

  private

  # Generate a time-based seed for consistent random ordering within an hour
  def time_based_seed(offset = 0)
    seed = Time.current.yday * 24 + Time.current.hour + offset
    seed.to_f / 10000
  end

  def primary_table_id
    if infer_table_context == 'leagues'
      'leagues.id'
    else
      'players.id'
    end
  end
end