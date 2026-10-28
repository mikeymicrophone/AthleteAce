# frozen_string_literal: true

module Seeds
  # Export only the fields accepted by the live adapter. Required associations
  # stay semantic checks because they may arrive through inherited scope.
  class CatalogContract
    def self.document
      entities = LibraryImporter::MODELS.sort.to_h do |name, model|
        polymorphic_columns = model.reflect_on_all_associations(:belongs_to).filter_map do |association|
          association.foreign_type if association.polymorphic?
        end
        attributes = model.columns.sort_by(&:name).filter_map do |column|
          next if LibraryImporter::PROTECTED_ATTRIBUTES.include?(column.name) || column.name.end_with?("_id") || polymorphic_columns.include?(column.name)
          [column.name, column_schema(model, column)]
        end.to_h
        [name, { "attributes" => attributes, "references" => model.reflect_on_all_associations(:belongs_to).map { |association| association.name.to_s }.sort }]
      end
      { "namespace" => "MIC", "catalog" => "ALA", "entities" => entities }
    end

    def self.column_schema(model, column)
      enum = model.defined_enums[column.name]
      schema = if enum
                 { "type" => "string", "enum" => enum.keys }
               else
                 case column.type
                 when :integer, :bigint then { "type" => "integer" }
                 when :float, :decimal then { "type" => "number" }
                 when :boolean then { "type" => "boolean" }
                 when :date then { "type" => "string", "format" => "date" }
                 when :datetime, :timestamp then { "type" => "string", "format" => "date-time" }
                 when :json, :jsonb then {} # Models may impose a more specific semantic shape.
                 else { "type" => "string" }
                 end
               end
      schema = { "type" => "array", "items" => schema } if column.respond_to?(:array) && column.array
      column.null && !schema.empty? ? { "anyOf" => [schema, { "type" => "null" }] } : schema
    end
  end
end
