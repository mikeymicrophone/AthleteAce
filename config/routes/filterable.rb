# config/routes/filterable.rb
# This file contains dynamic routes for filterable resources

module ActionDispatch::Routing
  class Mapper
    # Define filterable routes for a resource
    # This method creates nested routes for filtered resources
    # E.g.: sports/:sport_id/players, leagues/:league_id/players, etc.
    def filterable_resources(resource, options = {})
      # Get filterable associations for this resource
      resource_name = resource.to_s.singularize
      controller_name = "#{resource_name.camelize.pluralize}Controller"
      filterable_associations = FilterableAssociations::ASSOCIATIONS[resource.to_sym] || []
      
      # Create nested routes for each filterable association
      filterable_associations.each do |association|
        # Create the route with the parent resource
        resources association.to_s.pluralize, only: [] do
          # Add the nested resource
          resources resource, options.dup
        end
      end
      
      # Create the standard resource routes as well
      resources resource, options.dup
    end
  end
end
