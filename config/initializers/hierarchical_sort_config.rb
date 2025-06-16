# Hierarchical Sort Configuration
# Dynamically builds sort configuration from model ransackable attributes and associations

# Define which models support hierarchical sorting
HIERARCHICAL_SORT_MODELS = {
  players: 'Player',
  leagues: 'League',
  divisions: 'Division'
}.freeze

# Helper class to build dynamic configuration
class HierarchicalSortConfigBuilder
  def self.build_config
    config = {}
    
    HIERARCHICAL_SORT_MODELS.each do |context, model_name|
      model_class = model_name.constantize
      config[context] = build_model_config(model_class)
    end
    
    config
  rescue NameError => e
    Rails.logger.warn "HierarchicalSortConfig: Could not load model - #{e.message}"
    {}
  end

  private

  def self.build_model_config(model_class)
    config = {
      attributes: {},
      joins: {}
    }

    # Get ransackable attributes for direct sorting
    if model_class.respond_to?(:ransackable_attributes)
      model_class.ransackable_attributes.each do |attr|
        config[:attributes][attr] = "#{model_class.table_name}.#{attr}"
      end
    end

    # Get ransackable associations for joined sorting
    if model_class.respond_to?(:ransackable_associations)
      model_class.ransackable_associations.each do |assoc_name|
        association = model_class.reflect_on_association(assoc_name.to_sym)
        next unless association

        associated_class = association.klass
        table_name = associated_class.table_name

        # Add association attributes for sorting
        if associated_class.respond_to?(:ransackable_attributes)
          associated_class.ransackable_attributes.each do |attr|
            sort_key = "#{assoc_name}_#{attr}"
            config[:attributes][sort_key] = "#{table_name}.#{attr}"
            
            # Build join path
            config[:joins][sort_key] = build_join_path(association)
          end
        end
      end
    end

    config
  end

  # Build the join path for nested associations
  def self.build_join_path(association)
    case association.macro
    when :belongs_to, :has_one
      [association.name.to_sym]
    when :has_many, :has_and_belongs_to_many
      [association.name.to_sym]
    else
      # Handle through associations
      if association.options[:through]
        through_assoc = association.options[:through]
        [through_assoc, association.name.to_sym]
      else
        [association.name.to_sym]
      end
    end
  end
end
