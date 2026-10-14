class ModerationDecision < ApplicationRecord
  belongs_to :subject, polymorphic: true, optional: true
  belongs_to :actor, class_name: "Ace", optional: true
  validates :action, inclusion: { in: %w[submitted approved rejected hidden reopened] }
  validates :to_status, inclusion: { in: %w[pending approved rejected hidden] }
  validates :revision, numericality: { only_integer: true, greater_than: 0 }
  validates :reason, length: { maximum: 2000 }

  def readonly?
    persisted?
  end
end
