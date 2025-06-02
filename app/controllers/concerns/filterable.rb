module Filterable
  extend ActiveSupport::Concern

  class_methods do
    def filterable_by(*associations)
      @filterable_associations = associations
    end
  end

  def apply_filter result
    scope = nil
    filterable_associations.select do |association|
      params[association.to_s.singularize + "_id"].present?
    end.each do |association|
      scope = instance_variable_set("@#{association}", association.to_s.singularize.classify.constantize.find(params[association.to_s.singularize + "_id"]))
    end

    scope.send result
  end

  def apply_filters(relation)
    return relation if filterable_associations.empty?

    filterable_associations.each do |association|
      param_key = "#{association}_id"
      next unless params[param_key].present?

      relation = relation.joins(association).where(association => { id: params[param_key] })
    end

    relation
  end

  private

  def filterable_associations
    self.class.instance_variable_get(:@filterable_associations) || []
  end
end 