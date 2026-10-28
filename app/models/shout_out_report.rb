class ShoutOutReport < ApplicationRecord
  REASONS = [ "Harassment", "Spam", "Off-topic", "Other" ].freeze
  belongs_to :shout_out
  belongs_to :reporter, class_name: "Ace", optional: true
  belongs_to :resolved_by, class_name: "Ace", optional: true
  attr_readonly :shout_out_id, :reporter_id, :reason, :note
  validates :reason, inclusion: { in: REASONS }
  validates :note, :decision_reason, length: { maximum: 2000 }
  scope :open, -> { where(resolved_at: nil) }
end
