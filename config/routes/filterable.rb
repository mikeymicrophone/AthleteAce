# config/routes/filterable.rb
# This file contains dynamic routes for filterable resources

module ActionDispatch::Routing
  class Mapper
    # Define filterable routes for a resource
    # This method creates nested routes for filtered resources
    # E.g.: sports/:sport_id/players, leagues/:league_id/players, etc.
    def filterable_resources(resource, options = {})
      # resource_name = resource.to_s.singularize
      # controller_name = "#{resource_name.camelize.pluralize}Controller"
      filterable_associations = FilterableAssociations::ASSOCIATIONS[resource.to_sym] || []
      
      filterable_associations.each do |association|
        resources association.to_s.pluralize, only: [] do
          resources resource, options.dup
        end
      end
      
      # resources resource, options.dup
    end
  end
end
