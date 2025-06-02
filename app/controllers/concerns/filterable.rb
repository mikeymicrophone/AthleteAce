module Filterable
  extend ActiveSupport::Concern

  class_methods do
    def filterable_by(*associations)
      @filterable_associations = associations
    end
  end

  # Apply filters based on params and return the filtered collection
  # This method sets instance variables for each filter (e.g., @sport, @team)
  # and builds a filtered query using the appropriate associations
  def apply_filter(result)
    # Get all applied filters from params
    applied_filters = {}
    
    # Process all filter params and set instance variables
    filterable_associations.each do |association|
      param_key = "#{association}_id"
      next unless params[param_key].present?
      
      # Set the instance variable for this filter
      model_class = association.to_s.singularize.classify.constantize
      filter_object = model_class.find_by id: params[param_key]
      
      if filter_object
        instance_variable_set "@#{association}", filter_object
        applied_filters[association] = filter_object
      end
    end
    
    # Return all records if no filters applied
    return result.to_s.singularize.classify.constantize.all if applied_filters.empty?
    
    # Build the query with all filters applied
    query = build_filtered_query result, applied_filters
    
    # Return the filtered collection
    query
  end

  # Apply multiple filters to a relation
  # This version supports applying multiple filters simultaneously
  # and uses optimal join paths for complex associations
  def apply_filters(relation)
    return relation if filterable_associations.empty?

    applied_filters = {}
    
    # Collect all filters to apply
    filterable_associations.each do |association|
      param_key = "#{association}_id"
      next unless params[param_key].present?
      
      applied_filters[association] = params[param_key]
    end
    
    # Return unchanged relation if no filters applied
    return relation if applied_filters.empty?
    
    # Apply each filter with the appropriate join strategy
    applied_filters.each do |association, filter_value|
      # Use custom join paths if defined in FilterableAssociations
      model_name = controller_name.singularize.to_sym
      join_path = FilterableAssociations.join_path_for model_name, association
      
      if join_path
        # Apply complex joins
        relation = relation.joins(*join_path)
        # The last join in the path determines the final association to filter on
        target_association = join_path.last
        relation = relation.where target_association => { id: filter_value }
      else
        # Simple direct association
        relation = relation.joins(association).where association => { id: filter_value }
      end
    end

    relation
  end
  
  # Build a filtered query based on the result type and applied filters
  # This is a more flexible approach than the original apply_filter method
  # that allows for multiple filters to be applied at once
  #
  # @param result [Symbol, String] The result collection name (e.g., :players)
  # @param filters [Hash] Hash of filter objects (e.g., { sport: @sport, team: @team })
  # @return [ActiveRecord::Relation] The filtered query
  def build_filtered_query(result, filters)
    # Convert result to a class if it's a symbol or string
    result_class = result.is_a?(Class) ? result : result.to_s.singularize.classify.constantize
    
    # Start with a base query
    query = result_class.all
    
    # Apply each filter with the best join strategy
    filters.each do |association, filter_object|
      # Skip nil filters
      next unless filter_object
      
      # Get the model name for finding join paths
      model_name = controller_name.singularize.to_sym
      
      # Try to find a join path for this association
      join_path = FilterableAssociations.join_path_for model_name, association
      
      if join_path
        # Apply complex joins if a join path is defined
        query = query.joins(*join_path)
        last_join = join_path.last
        query = query.where last_join => { id: filter_object.id }
      else
        # Try different approaches based on the associations
        if result_class.reflect_on_association(association)
          # Direct belongs_to association
          query = query.where association => filter_object
        elsif filter_object.respond_to?(result.to_s.pluralize)
          # Has_many association from the filter object
          # Let the filter object scope the query
          query = filter_object.send(result.to_s.pluralize)
        else
          # Try a join approach as a fallback
          begin
            query = query.joins(association).where association => { id: filter_object.id }
          rescue ActiveRecord::ConfigurationError => e
            # If joining fails, try to find a different association path
            Rails.logger.warn "Filter join error: #{e.message}. Trying alternative approach."
            # As a last resort, just return all records that match the filter ID
            query = query.where "#{association}_id" => filter_object.id
          end
        end
      end
    end
    
    query
  end

  # Helper method to build filtered paths for links
  def filtered_path(base_path, options = {})
    path = base_path
    
    filterable_associations.each do |association|
      param_key = "#{association}_id"
      if params[param_key].present? || options[association]
        value = options[association] || params[param_key]
        path = "#{association.to_s.pluralize}/#{value}/#{path}"
      end
    end
    
    path
  end

  private

  def filterable_associations
    # First check if controller has explicitly set associations
    explicit_associations = self.class.instance_variable_get(:@filterable_associations)
    return explicit_associations if explicit_associations.present?
    
    # Otherwise use the configuration file
    FilterableAssociations.for(self.class.name)
  end
end