module FilterLoader
  extend ActiveSupport::Concern
  
  # Load current filters from params based on filterable associations
  # Sets instance variables for each filter and returns a hash of filter objects
  def load_current_filters
    result = {}
    
    filterable_associations.each do |association|
      param_key = "#{association}_id"
      next unless params[param_key].present?
      
      # Get the model class and load the object
      model_class = association.to_s.singularize.classify.constantize
      filter_object = model_class.find_by id: params[param_key]
      
      if filter_object
        # Set instance variable (e.g., @sport = Sport.find(...))
        instance_variable_set "@#{association}", filter_object
        result[association] = filter_object
      end
    end
    
    @current_filters = result
  end
  
  # Load filter options for selectors
  def load_filter_options
    @filter_options = {}
    filterable_associations.each do |association|
      @filter_options[association] = association.to_s.classify.constantize.all
    end

    @filter_options
  end
  
  # Build a breadcrumb trail based on current filters and the viewed resource
  # @param resource [ActiveRecord::Base] The current resource being viewed
  # @param filters [Hash] Hash of current filters
  # @return [Array] Array of breadcrumb items with labels and paths
  def build_filtered_breadcrumb(resource, filters = {})
    return [] if filters.empty? && !resource
    
    breadcrumbs = []
    resource_name = resource.class.name.underscore

    # Add each filter to the breadcrumb trail, linking to that filter's own page
    sort_filters_by_hierarchy(filters).each do |filter_key, filter_obj|
      breadcrumbs << {
        label: filter_obj.name,
        path: polymorphic_path(filter_obj),
        type: filter_key.to_s.humanize
      }
    end

    # Add the current resource as the final breadcrumb
    breadcrumbs << {
      label: resource.name,
      path: request.path,
      type: resource_name.humanize,
      current: true
    }
    
    breadcrumbs
  end
  
  private
  
  # Sort filters by a predefined hierarchy
  # This ensures we present filters in a logical order (e.g., sport -> league -> team)
  def sort_filters_by_hierarchy(filters)
    return [] if filters.empty?
    
    # Define the hierarchy of resources
    hierarchy = [
      :sport,
      :league,
      :conference,
      :division,
      :team,
      :country,
      :state,
      :city,
      :stadium,
      :player
    ]
    
    # Convert filters to array and sort by hierarchy position
    filters.to_a.sort do |(key_a, _), (key_b, _)|
      pos_a = hierarchy.index(key_a.to_sym) || 999
      pos_b = hierarchy.index(key_b.to_sym) || 999
      pos_a <=> pos_b
    end
  end
end
