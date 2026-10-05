class EntityCode < ApplicationRecord
  belongs_to :record, polymorphic: true, optional: true

  validates :namespace, :catalog, :code, :canonical_code, presence: true
  validates :code, uniqueness: { scope: [:namespace, :catalog] }

  def record
    return if canonical_code.blank? || record_type.blank? || record_id.nil?

    record_class = association(:record).klass
    return unless record_class.column_names.include?("entity_code")

    record_class.find_by id: record_id, entity_code: canonical_code
  end
  alias_method :resolved_record, :record
end
