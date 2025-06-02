module FilterableHelper
  # Generate a link to a filtered resource index
  # 
  # @param text [String] The link text
  # @param resource [Symbol] The resource to link to (e.g., :players, :teams)
  # @param filter_by [Hash] A hash of filters to apply (e.g., { sport: @sport, league: @league })
  # @param options [Hash] Additional options for link_to helper
  # @return [String] HTML link
  def filtered_link_to(text, resource, filter_by = {}, options = {})
    path = build_filtered_path resource, filter_by
    
    # Apply any HTML classes from options
    html_options = options.delete(:html) || {}
    link_to text, path, html_options
  end
  
  # Build a path to a filtered resource
  #
  # @param resource [Symbol] The resource to link to (e.g., :players, :teams)
  # @param filter_by [Hash] A hash of filters to apply (e.g., { sport: @sport, league: @league })
  # @return [String] The path
  def filtered_path(resource, filter_by = {})
    build_filtered_path resource, filter_by
  end
  
  # Generate breadcrumbs for the current filterable path
  #
  # @param resource [Symbol] The current resource type (e.g., :players)
  # @param filters [Hash] Hash of current filters with objects (e.g., { sport: @sport })
  # @param options [Hash] Options for styling the breadcrumbs
  # @return [String] HTML breadcrumbs
  def filterable_breadcrumbs(resource, filters = {}, options = {})
    return '' if filters.empty?
    
    container_class = options[:container_class] || 'flex items-center space-x-2 py-2 px-4 bg-gray-50 rounded-md text-sm mb-4'
    separator_class = options[:separator_class] || 'text-gray-400'
    link_class = options[:link_class] || 'text-blue-600 hover:text-blue-800'
    current_class = options[:current_class] || 'font-medium text-gray-800'
    
    content_tag :nav, class: container_class, aria: { label: 'Breadcrumb' } do
      items = []
      accumulated_filters = {}
      
      # Add home/base link
      items << link_to(resource.to_s.humanize, send("#{resource}_path"), class: link_class)
      
      # Add filter links in order
      ordered_filters = sort_filters_by_hierarchy filters
      
      ordered_filters.each_with_index do |(filter_key, filter_obj), index|
        accumulated_filters[filter_key] = filter_obj
        is_last = index == ordered_filters.size - 1
        
        if is_last
          items << content_tag(:span, filter_obj.name, class: current_class)
        else
          # Remove all filters after this one for the link
          link_filters = accumulated_filters.slice(*accumulated_filters.keys.take(index + 1))
          items << link_to(filter_obj.name, build_filtered_path(resource, link_filters), class: link_class)
        end
      end
      
      # Join with separators
      safe_join items.zip(Array.new(items.size - 1) { content_tag(:span, '/', class: separator_class) }).flatten.compact
    end
  end
  
  # Generate filter chips to show active filters with remove option
  #
  # @param resource [Symbol] The current resource type (e.g., :players)
  # @param filters [Hash] Hash of current filters with objects (e.g., { sport: @sport })
  # @return [String] HTML filter chips
  def filter_chips(resource, filters = {})
    return '' if filters.empty?
    
    content_tag :div, class: 'flex flex-wrap gap-2 mb-4' do
      chips = filters.map do |filter_key, filter_obj|
        # Create a new hash without this filter
        remaining_filters = filters.except(filter_key)
        
        content_tag :span, class: 'inline-flex items-center px-3 py-1 rounded-full text-sm bg-blue-100 text-blue-800' do
          label = content_tag(:span, "#{filter_key.to_s.humanize}: #{filter_obj.name}")
          remove_btn = link_to '×', filtered_path(resource, remaining_filters), 
                               class: 'ml-2 text-blue-600 hover:text-blue-800 font-bold'
          safe_join [label, remove_btn]
        end
      end
      
      # Add a clear all button if multiple filters
      if filters.size > 1
        chips << link_to('Clear All', send("#{resource}_path"), 
                        class: 'inline-flex items-center px-3 py-1 rounded-full text-sm bg-red-100 text-red-700 hover:bg-red-200')
      end
      
      safe_join chips
    end
  end
  
  private
  
  def build_filtered_path(resource, filter_by)
    # Start with the base resource path
    path_segments = []
    
    # Add filter segments
    filter_by.each do |association, object|
      next unless object
      
      # Skip if the object doesn't have an ID
      next unless object.respond_to?(:id)
      
      path_segments.unshift "#{association.to_s.pluralize}/#{object.id}"
    end
    
    # Add the base resource at the end
    path_segments << resource.to_s
    
    # Join with slashes and return
    '/' + path_segments.join('/')
  end
  
  # Sort filters based on a logical hierarchy (e.g., country → state → city)
  def sort_filters_by_hierarchy(filters)
    hierarchy_order = {
      sport: 1,
      country: 2,
      league: 3,
      state: 4,
      conference: 5,
      division: 6,
      city: 7,
      stadium: 8,
      team: 9
    }
    
    filters.sort_by { |key, _| hierarchy_order[key] || 999 }
  end
end
