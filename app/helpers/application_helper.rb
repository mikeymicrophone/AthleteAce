module ApplicationHelper
  include Pagy::Frontend
  


  def link_to_name(record, **options)
    link_to record.name, record, **options rescue ''
  end

  
  # UNUSED
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
      class: "lazy-logo-container", # Keep semantic class name
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
      logo_placeholder = content_tag(:span, "", class: "logo-placeholder", data: { lazy_logo_target: "image" })
      
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
