# Routes for location-based resources (countries, states, cities)
Rails.application.routes.draw do
  FilterableAssociations::ASSOCIATIONS.keys.each do |resource|
    filterable_resources resource
  end
end
