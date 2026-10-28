class ModerationDecision < ApplicationRecord
  belongs_to :subject, polymorphic: true, optional: true
  belongs_to :actor, class_name: "Ace", optional: true
  validates :action, inclusion: { in: %w[submitted approved rejected hidden reopened] }
  validates :to_status, inclusion: { in: %w[pending approved rejected hidden] }
  validates :revision, numericality: { only_integer: true, greater_than: 0 }
  validates :reason, length: { maximum: 2000 }

  scope :review_transitions, -> {
    where(action: "approved", from_status: "pending", to_status: "approved")
      .or(where(action: "rejected", from_status: "pending", to_status: "rejected"))
      .or(where(action: "hidden", from_status: "approved", to_status: "hidden"))
      .or(where(action: "reopened", from_status: %w[rejected hidden], to_status: "pending"))
  }

  def readonly?
    persisted?
  end
end
