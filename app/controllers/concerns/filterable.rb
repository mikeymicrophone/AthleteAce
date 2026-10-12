module Filterable
  extend ActiveSupport::Concern

  class_methods do
    def filterable_by(*associations)
      @filterable_associations = associations
    end
  end

  # Apply ONE filter based on params and return the filtered collection
  # This method sets aninstance variable for the scope (e.g., @sport, @team)
  def apply_filter result
    scope = nil
    filterable_associations.select do |association|
      params[association.to_s.foreign_key].present?
    end.each do |association|
      scope = instance_variable_set("@#{association}", association.to_s.classify.constantize.find(params[association.to_s.foreign_key]))
    end

    if scope.nil?
      result.to_s.classify.constantize.all
    else
      scope.send result
    end
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