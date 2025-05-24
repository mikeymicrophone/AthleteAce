module SeedHelper
  # Applies seed version tracking to both creation and updates
  # within the given block.
  #
  # Example:
  #   SEED_VERSION = "001.2025.05.23"
  #   SeedHelpers.with_seed_version(SEED_VERSION) do
  #     Sport.find_or_create_by(name: "Basketball")
  #     Team.find_or_initialize_by(name: "Chicago Bulls").tap do |team|
  #       team.city = "Chicago"
  #       team.save
  #     end
  #   end
  #
  def self.with_seed_meta(version:, date: Time.current, model: ApplicationRecord)
    # 1. Build a base relation from the *concrete* model
    base = model.unscoped

    # 2. Layer defaults for create / update
    meta_scope = base
                   .create_with(seed_version: version,
                                last_seeded_date: date)

    # 3. Run everything inside the scoping block
    meta_scope.scoping { yield }
  end

  def self.with_seed_version(version)
    seed_time = Time.current
    seed_attributes = { seed_version: version, last_seeded_at: seed_time }
    scope = Team.where(seed_attributes)
    scope.scoping do
      yield
    end
  end
    
    # # Store original methods for all seeded models
    # reference_models = [
    #   Sport, League, Conference, Division, Team, Player, Stadium,
    #   Country, State, City
    # ]
    
    # begin
    #   # Create patches for each model
    #   reference_models.each do |model|
    #     # Store original save method
    #     original_methods[model] = {
    #       save: model.instance_method(:save),
    #       update: model.instance_method(:update)
    #     }
        
    #     # Override save to include seed attributes
    #     model.define_method(:save) do |*args|
    #       self.seed_version = version
    #       self.last_seeded_at = seed_time
    #       original_methods[model][:save].bind_call(self, *args)
    #     end
        
    #     # Override update to include seed attributes
    #     model.define_method(:update) do |*args|
    #       args[0] = args[0].merge(seed_attributes) if args[0].is_a?(Hash)
    #       original_methods[model][:update].bind_call(self, *args)
    #     end
    #   end
      
    #   # For creation, use scoping with defaults
    #   scope = ApplicationRecord.unscoped.all
    #   scope.scoping(create: seed_attributes) do
    #     yield
    #   end
    # ensure
    #   # Restore original methods
    #   reference_models.each do |model|
    #     if original_methods[model]
    #       model.define_method(:save, original_methods[model][:save])
    #       model.define_method(:update, original_methods[model][:update])
    #     end
    #   end
    # end
  # end
end
