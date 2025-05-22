module ApplicationHelper
  include Pagy::Frontend
  
  # Renders a Tailwind CSS styled pagination component
  # @param pagy [Pagy] The Pagy object
  # @param nearby_pages [Integer] Number of pages to show on either side of the current page (default: 2)
  # @return [String] HTML for the pagination component
  def tailwind_pagination(pagy, nearby_pages = 2)
    return unless pagy.pages > 1
    
    tag.nav(class: "flex justify-center my-6", "aria-label": "Pagination") do
      tag.div(class: "relative z-0 inline-flex shadow-sm rounded-md") do
        # Previous page link
        if pagy.prev
          concat(link_to(pagy_url_for(pagy, pagy.prev), 
            class: "relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50",
            "aria-label": "Previous") do
              tag.span(class: "sr-only") { "Previous" } +
              tag.i(class: "fa-solid fa-chevron-left h-5 w-5")
          end)
        else
          concat(tag.span(
            class: "relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-gray-100 text-sm font-medium text-gray-400 cursor-not-allowed",
            "aria-disabled": "true") do
              tag.span(class: "sr-only") { "Previous" } +
              tag.i(class: "fa-solid fa-chevron-left h-5 w-5")
          end)
        end
        
        # Page links - simplified approach with configurable range
        from = [1, pagy.page - nearby_pages].max
        to = [pagy.pages, pagy.page + nearby_pages].min
        
        # First page if needed
        if from > 1
          concat(link_to(1, pagy_url_for(pagy, 1), 
            class: "relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"))
          
          # Gap indicator if needed
          if from > 2
            concat(tag.span("...", 
              class: "relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700"))
          end
        end
        
        # Main page numbers
        (from..to).each do |page|
          if page == pagy.page
            concat(tag.span(page, 
              class: "relative inline-flex items-center px-4 py-2 border border-gray-300 bg-indigo-50 text-sm font-medium text-indigo-600", 
              "aria-current": "page"))
          else
            concat(link_to(page, pagy_url_for(pagy, page), 
              class: "relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"))
          end
        end
        
        # Last page if needed
        if to < pagy.pages
          # Gap indicator if needed
          if to < pagy.pages - 1
            concat(tag.span("...", 
              class: "relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700"))
          end
          
          concat(link_to(pagy.pages, pagy_url_for(pagy, pagy.pages), 
            class: "relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"))
        end
        
        # Next page link
        if pagy.next
          concat(link_to(pagy_url_for(pagy, pagy.next), 
            class: "relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50",
            "aria-label": "Next") do
              tag.span(class: "sr-only") { "Next" } +
              tag.i(class: "fa-solid fa-chevron-right h-5 w-5")
          end)
        else
          concat(tag.span(
            class: "relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-gray-100 text-sm font-medium text-gray-400 cursor-not-allowed",
            "aria-disabled": "true") do
              tag.span(class: "sr-only") { "Next" } +
              tag.i(class: "fa-solid fa-chevron-right h-5 w-5")
          end)
        end
      end
    end
  end

  # Returns the active class for navigation links
  def active_class(link_path)
    current_page?(link_path) ? 'border-indigo-500 text-orange-400' : 'border-transparent text-white hover:border-gray-300 hover:text-orange-200'
  end

  def link_to_name(record, **options)
    default_options = { class: 'flex' }
    merged_options = default_options.merge(options)
    link_to record.name, record, **merged_options rescue ''
  end

  # Shared Tailwind classes for all index records
  def index_record_base_classes
    'flex items-center justify-between p-4 mb-2 bg-white rounded shadow hover:bg-orange-50 transition-colors duration-150'
  end
  
  # Generic index page header with title and optional parent link
  def index_header(title, parent_record = nil, parent_link_text = nil)
    content = tag.h1(title, class: "index-title")
    
    if parent_record.present?
      content += tag.div(class: "index-parent-link") do
        "#{parent_link_text || parent_record.class.name}: " + 
        link_to(parent_record.name, parent_record, class: "text-blue-600 hover:underline")
      end
    end
    
    tag.div(content, class: "index-header")
  end
  
  # Generic index collection container
  def index_collection(collection_id, &block)
    tag.div(id: collection_id, class: "index-collection", &block)
  end
  
  # Generic index record wrapper
  def index_record(record, record_classes = nil, &block)
    tag.div(
      id: dom_id(record), 
      class: [
        "index-record",
        record_classes
      ].compact.join(' '),
      &block
    )
  end
  
  # Generic record info section
  def record_info_section(&block)
    tag.div(class: "record-info", &block)
  end
  
  # Generic record stats section
  def record_stats_section(&block)
    tag.div(class: "record-stats", &block)
  end

  # Resource-specific example: Teams
  def team_index_record_classes
    'border-l-4 border-orange-400 hover:border-indigo-500'
  end

  def player_index_record_classes
    'border-l-4 border-blue-400 hover:border-indigo-500'
  end

  def league_index_record_classes
    'border-l-4 border-green-400 hover:border-indigo-500'
  end

  def country_index_record_classes
    'border-l-4 border-yellow-400 hover:border-indigo-500'
  end

  def state_index_record_classes
    'border-l-4 border-purple-400 hover:border-indigo-500'
  end

  def city_index_record_classes
    'border-l-4 border-pink-400 hover:border-indigo-500'
  end

  def stadium_index_record_classes
    'border-l-4 border-gray-400 hover:border-indigo-500'
  end

  def sport_index_record_classes
    'border-l-4 border-teal-400 hover:border-indigo-500'
  end

  def conference_index_record_classes
    'border-l-4 border-red-400 hover:border-indigo-500'
  end

  def division_index_record_classes
    'border-l-4 border-indigo-400 hover:border-indigo-500'
  end

  def membership_index_record_classes
    'border-l-4 border-cyan-400 hover:border-indigo-500'
  end

  # Renders a collection of records with their names and logos
  # 
  # @param collection [ActiveRecord::Relation] A collection of ActiveRecord objects
  # @param options [Hash] Additional options for customization
  # @option options [String] :title Custom title for the collection (defaults to humanized collection name)
  # @option options [Boolean] :link_to_collection Whether to link to the collection (default: false)
  # @option options [ActiveRecord::Base] :parent Parent record for nested routes
  # @option options [String] :css_class CSS class for the collection container (defaults to collection name)
  # @option options [String] :item_css_class CSS class for each item in the collection (defaults to singularized collection name)
  # @option options [Symbol] :logo_attribute The attribute to use for the logo URL (defaults to :logo_url)
  # @return [ActiveSupport::SafeBuffer] HTML for the collection
  def render_collection(collection, **options)
    return content_tag(:div, "No items", class: "empty-collection") if collection.empty? && !options[:show_empty]
    
    # Determine collection name and CSS classes
    collection_name = collection.model_name.plural
    item_name = collection.model_name.singular
    
    # Set up options with defaults
    title = options.fetch(:title, collection.model_name.human.pluralize)
    link_to_collection = options.fetch(:link_to_collection, false)
    parent = options.fetch(:parent, nil)
    css_class = options.fetch(:css_class, collection_name)
    item_css_class = options.fetch(:item_css_class, item_name)
    logo_attribute = options.fetch(:logo_attribute, :logo_url)
    
    content_tag :div, class: css_class do
      # Display the count/title, optionally as a link
      concat(
        if link_to_collection && parent
          link_to pluralize(collection.count, title), [parent, collection_name.to_sym]
        else
          pluralize(collection.count, title)
        end
      )
      
      # Display each item in the collection
      collection.each do |item|
        concat(
          content_tag(:div, id: dom_id(item), class: item_css_class) do
            display_name_with_lazy_logo(item, logo_attribute: logo_attribute)
          end
        )
      end
    end
  end
  
  # For backward compatibility - uses the generic render_collection helper
  def render_teams_collection(teams, **options)
    render_collection(teams, **options)
  end
  
  # For backward compatibility - uses the generic render_collection helper
  def render_players_collection(players, **options)
    # Remove sport_name from options as it's no longer needed
    options.delete(:sport_name)
    render_collection(players, **options)
  end

  # Displays a record's name with a placeholder for a lazy-loaded logo.
  # The Stimulus 'lazy-logo_controller.js' will handle loading the actual image.
  #
  # @param record [ActiveRecord::Base] The record object (e.g., Team, Player).
  # @param name_attribute [Symbol] The attribute on the record for its name (defaults to :name).
  # @param logo_attribute [Symbol] The attribute for the logo URL (defaults to :logo_url).
  # @param options [Hash] Additional HTML options for the container span.
  # @return [ActiveSupport::SafeBuffer] HTML string for the container with name and logo placeholder.
  def display_name_with_lazy_logo(record, name_attribute: :name, logo_attribute: :logo_url, **options)
    return '' unless record

    logo_url_value = record.respond_to?(logo_attribute) ? record.public_send(logo_attribute) : nil
    entity_name = record.respond_to?(name_attribute) ? record.public_send(name_attribute) : "N/A"

    default_options = {
      class: "lazy-logo-container inline-flex items-center", # Added inline-flex and items-center
      data: {
        controller: "lazy-logo",
        lazy_logo_entity_id_value: record.id,
        lazy_logo_entity_type_value: record.class.name.underscore, # Use underscore for consistency if fetching via API later
        lazy_logo_url_value: logo_url_value
      }
    }
    merged_options = default_options.deep_merge(options)

    content_tag(:span, **merged_options) do
      # Placeholder for the image (Stimulus target)
      # Pre-styling for consistent size before image loads to reduce layout shift
      logo_placeholder = content_tag(:span, "", class: "logo-placeholder mr-1 w-5 h-5 inline-block", data: { lazy_logo_target: "image" })
      
      # Name (Stimulus target, though not strictly necessary if only displaying name)
      name_span = content_tag(:span, entity_name, data: { lazy_logo_target: "name" })
      
      unless options[:link] == false
        name_span = link_to name_span, record
      end
      
      logo_placeholder + name_span
    end
  rescue => e
    Rails.logger.error "Error in display_name_with_lazy_logo for record #{record&.id}: #{e.message}"
    entity_name || "Error"
  end
end
