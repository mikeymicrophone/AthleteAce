class CatalogEdit < ApplicationRecord
  belongs_to :actor, class_name: "Ace", optional: true
  attr_readonly :actor_id, :actor_name, :record_type, :record_id, :entity_code, :record_name,
    :before_values, :after_values, :submitted_values, :request_key, :created_at
  validates :actor_name, :record_name, :request_key, presence: true
  validates :record_type, inclusion: { in: %w[Player Team] }
  validates :request_key, length: { maximum: 128 }
  validates :reason, length: { maximum: 2000 }, allow_nil: true
  validate :preserve_supplied_reason, on: :update

  def supply_reason!(actor:, reason:)
    actor.with_lock do
      raise Admin::EditCatalog::Forbidden, "An active admin must explain catalog edits." unless actor.admin? && actor.active_for_authentication?
      with_lock do
        raise Admin::EditCatalog::Forbidden, "Only the admin who made this edit can explain it." unless actor_id == actor.id
        raise ArgumentError, "Give a reason of 1 to 2000 characters." unless reason.is_a?(String) && reason.strip.length.between?(1, 2000)
        reason = reason.strip
        return self if self.reason == reason
        raise Admin::EditCatalog::Conflict, "This edit already has a reason." if self.reason.present?
        update!(reason: reason, reason_supplied_at: Time.current)
      end
    end
    self
  end

  def export_entry
    { format: "athlete_ace/catalog_edits/v1", id: id, created_at: created_at.utc.iso8601(6),
      actor: { id: actor_id, name: actor_name }, record: { type: record_type, id: record_id, entity_code: entity_code, name: record_name },
      before: before_values, after: after_values, reason: reason, reason_supplied_at: reason_supplied_at&.utc&.iso8601(6) }
  end

  private

  def preserve_supplied_reason
    if reason_in_database.present? && (will_save_change_to_reason? || will_save_change_to_reason_supplied_at?)
      errors.add(:reason, "has already been supplied")
    end
  end
end
