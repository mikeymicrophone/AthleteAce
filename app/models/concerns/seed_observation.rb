module SeedObservation
  extend ActiveSupport::Concern

  included do
    validate :observation_metadata_is_mapping
  end

  private

  def observation_metadata_is_mapping
    %w[source details].each do |attribute|
      errors.add attribute, "must be a mapping" unless public_send(attribute).is_a?(Hash)
    end
  end
end
