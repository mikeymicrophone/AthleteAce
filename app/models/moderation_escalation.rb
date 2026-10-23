class ModerationEscalation < ApplicationRecord
  RESOLUTIONS = { "no_change" => "Close without changes", "approve" => "Approve", "reject" => "Reject",
    "hide" => "Hide", "reopen" => "Reopen for review" }.freeze
  belongs_to :subject, polymorphic: true, optional: true
  belongs_to :subject_ace, class_name: "Ace", optional: true
  belongs_to :requested_by, class_name: "Ace", optional: true
  belongs_to :resolved_by, class_name: "Ace", optional: true
  attr_readonly :subject_type, :subject_id, :subject_ace_id, :requested_by_id, :subject_name, :reason, :snapshot,
    :revision, :captured_status, :request_key
  validates :subject_type, inclusion: { in: [ *Moderation::Queue::TYPES.keys, "Ace" ] }
  validates :subject_name, :reason, :request_key, presence: true
  validates :reason, :resolution_reason, length: { maximum: 2000 }
  validates :request_key, length: { maximum: 128 }
  validates :resolution, inclusion: { in: RESOLUTIONS.keys }, if: :resolved_at?
  validates :resolution_reason, presence: true, if: :resolved_at?
  scope :open, -> { where(resolved_at: nil) }
  scope :visible_to, ->(ace) { where("subject_ace_id IS NULL OR subject_ace_id <> ?", ace.id) }

  def current_content?
    subject && subject_type != "Ace" && subject.moderation_revision == revision &&
      subject.moderation_status == captured_status && (!subject.is_a?(ShoutOut) || subject.funding_status == snapshot["funding_status"])
  end

  def readonly?
    persisted? && resolved_at_in_database.present?
  end
end
