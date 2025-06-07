module ActionDispatch::Routing
  class Mapper
    def filterable_resources(resource, options = {})
      filterable_associations = FilterableAssociations::ASSOCIATIONS[resource.to_sym] || []
      
      filterable_associations.each do |association|
        resources association.to_s.pluralize, only: [] do
          resources resource, options.dup
        end
      end
    end
  end
end
