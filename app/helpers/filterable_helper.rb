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
  
  # Generate a complete filter UI panel for a resource
  #
  # @param resource [Symbol] The resource type (e.g., :players, :teams)
  # @param current_filters [Hash] Hash of current filters (e.g., { sport: @sport, league: @league })
  # @param filter_options [Hash] Hash of filter options for each filterable association
  # @param options [Hash] Additional options for customizing the filter panel
  # @return [String] HTML filter panel
  def filter_panel(resource, current_filters = {}, filter_options = {}, options = {})
    # Set default options
    options = {
      container_class: 'filter-panel bg-white rounded-lg shadow mb-6',
      header_class: 'p-4 border-b border-gray-200',
      title_class: 'text-lg font-medium text-gray-900',
      body_class: 'p-4',
      title: 'Filters'
    }.merge(options)
    
    content_tag :div, class: options[:container_class] do
      content = []
      
      # Add header with title and active filters
      content << content_tag(:div, class: options[:header_class]) do
        header_content = []
        header_content << content_tag(:h2, options[:title], class: options[:title_class])
        
        # Add breadcrumbs and filter chips if we have active filters
        if current_filters.present? && current_filters.any?
          header_content << filterable_breadcrumbs(resource, current_filters)
          header_content << filter_chips(resource, current_filters)
        end
        
        safe_join header_content
      end
      
      # Add body with filter selectors
      content << content_tag(:div, class: options[:body_class]) do
        body_content = []
        
        # Add important filters section
        body_content << filter_important_section(resource, current_filters, filter_options)
        
        # Add advanced filters section
        body_content << filter_advanced_section(resource, current_filters, filter_options)
        
        safe_join body_content
      end
      
      safe_join content
    end
  end
  
  # Generate the important filters section
  #
  # @param resource [Symbol] The resource type
  # @param current_filters [Hash] Hash of current filters
  # @param filter_options [Hash] Hash of filter options
  # @param options [Hash] Additional options
  # @return [String] HTML for important filters
  def filter_important_section(resource, current_filters = {}, filter_options = {}, options = {})
    # Determine which filters to show as important
    important_filters = if filter_options.present? && current_filters.present?
                          [:sport, :league, :country, :team].select { |f| filter_options[f].present? && !current_filters[f] }
                        else
                          []
                        end
    
    return ''.html_safe if important_filters.empty?
    
    content_tag :div, class: 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4' do
      safe_join important_filters.map { |filter_key| filter_selector(resource, filter_key, filter_options[filter_key]) }
    end
  end
  
  # Generate the advanced filters section
  #
  # @param resource [Symbol] The resource type
  # @param current_filters [Hash] Hash of current filters
  # @param filter_options [Hash] Hash of filter options
  # @param options [Hash] Additional options
  # @return [String] HTML for advanced filters
  def filter_advanced_section(resource, current_filters = {}, filter_options = {}, options = {})
    # Determine which filters to show as advanced (all minus important and already applied)
    important_filters = [:sport, :league, :country, :team]
    remaining_filters = filter_options.keys - important_filters - current_filters.keys
    
    return ''.html_safe if remaining_filters.empty?
    
    content_tag :details, class: 'mt-4' do
      summary = content_tag :summary, 'Advanced Filters', 
                           class: 'text-sm text-blue-600 cursor-pointer'
      
      filters = content_tag :div, class: 'mt-2 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4' do
        safe_join remaining_filters.map { |filter_key| filter_selector(resource, filter_key, filter_options[filter_key]) }
      end
      
      safe_join [summary, filters]
    end
  end
  
  # Generate a single filter selector
  #
  # @param resource [Symbol] The resource type
  # @param filter_key [Symbol] The filter key (e.g., :sport, :league)
  # @param options [Array] Collection of options for the select
  # @param html_options [Hash] Additional HTML options
  # @return [String] HTML for a filter selector
  def filter_selector(resource, filter_key, options, html_options = {})
    return ''.html_safe unless options.present?
    
    content_tag :div, class: 'filter-group' do
      label = content_tag :h3, filter_key.to_s.humanize, class: 'text-sm font-medium text-gray-700 mb-1'
      
      selector = content_tag :div, class: 'relative' do
        select_tag "filter_#{filter_key}", 
                  options_from_collection_for_select(options, :id, :name),
                  include_blank: "-- Select #{filter_key.to_s.humanize} --",
                  class: 'block w-full py-2 px-3 border border-gray-300 bg-white rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm',
                  data: { 
                    action: 'change->filter#applyFilter',
                    filter_key: filter_key,
                    filter_resource: resource
                  }
      end
      
      safe_join [label, selector]
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
