module FilteredShowHelper
  # Generate a complete filtered show header with breadcrumbs and resource metadata
  #
  # @param resource [Object] The resource being displayed
  # @param filtered_breadcrumb [Array] Array of breadcrumb items
  # @param options [Hash] Additional options for customizing the header
  # @return [String] HTML for the filtered show header
  def filtered_show_header(resource, filtered_breadcrumb = nil, options = {})
    options = {
      container_class: 'show-header',
      breadcrumb_class: 'breadcrumb',
      metadata_class: 'metadata'
    }.merge options

    content_tag :div, class: options[:container_class] do
      content = []
      
      # Add the breadcrumb navigation if present
      content << filtered_breadcrumb_nav(filtered_breadcrumb, options) if filtered_breadcrumb.present?
      
      # Add the resource metadata section
      content << resource_metadata(resource, options)
      
      safe_join content
    end
  end
  
  # UNUSED
  # Generate breadcrumb navigation for filtered show pages
  #
  # @param breadcrumbs [Array] Array of breadcrumb items with keys :label, :path, :type, :current
  # @param options [Hash] Additional options for customizing the breadcrumbs
  # @return [String] HTML for the breadcrumb navigation
  def filtered_breadcrumb_nav(breadcrumbs, options = {})
    return ''.html_safe unless breadcrumbs.present?
    
    options = {
      nav_class: 'breadcrumb',
      list_class: 'breadcrumb-list',
      item_class: 'breadcrumb-item',
      separator_class: 'breadcrumb-separator',
      current_class: 'current',
      link_class: 'breadcrumb-link',
      type_class: 'breadcrumb-type'
    }.merge options
    
    content_tag :nav, class: options[:nav_class], aria: { label: 'Breadcrumb' } do
      content_tag :ol, class: options[:list_class] do
        safe_join breadcrumbs.each_with_index.map { |crumb, index|
          content_tag :li, class: options[:item_class] do
            item_content = []
            
            # Add separator for all but the first item
            if index > 0
              item_content << tag.span("/", class: options[:separator_class])
            end
            
            # Add the breadcrumb link or text
            if crumb[:current]
              item_content << tag.span(crumb[:label], class: options[:current_class])
            else
              item_content << link_to(crumb[:path], class: options[:link_class]) do
                link_content = []
                link_content << tag.span(crumb[:type], class: options[:type_class]) if crumb[:type].present?
                link_content << crumb[:label]
                safe_join link_content
              end
            end
            
            safe_join item_content
          end
        }
      end
    end
  end
  
  # UNUSED
  # Generate resource metadata display for the show header
  #
  # @param resource [Object] The resource being displayed
  # @param options [Hash] Additional options for customizing the metadata
  # @return [String] HTML for the resource metadata section
  def resource_metadata(resource, options = {})
    return ''.html_safe unless resource.present?
    
    options = {
      container_class: 'metadata',
      title_class: 'title',
      description_class: 'description'
    }.merge options
    
    content_tag :div, class: options[:container_class] do
      metadata_content = []
      
      # Add the resource title
      metadata_content << content_tag(:h1, resource.name, class: options[:title_class])
      
      # Add the resource description if available
      if resource.respond_to?(:description) && resource.description.present?
        metadata_content << content_tag(:p, resource.description, class: options[:description_class])
      end
      
      safe_join metadata_content
    end
  end
end
