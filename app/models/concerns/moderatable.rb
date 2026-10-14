module Moderatable
  extend ActiveSupport::Concern
  attr_accessor :moderation_editor

  CONTENT_FIELDS = %w[name description low_label high_label target_type target_id quest_id achievement_id position required].freeze

  included do
    belongs_to :created_by, class_name: "Ace", optional: true
    has_many :moderation_decisions, as: :subject
    has_many :decision_evaluations, as: :subject
    validates :moderation_status, inclusion: { in: %w[pending approved rejected hidden] }
    before_validation :set_submission_status, on: :create
    before_update :resubmit_changed_content
    after_create :record_submission
    after_update :record_resubmission
    scope :approved, -> { where(moderation_status: "approved") }
    scope :visible_to, ->(ace) {
      if ace&.can_moderate?
        all
      elsif ace
        approved.or(where(created_by: ace, moderation_status: %w[pending rejected]))
      else
        approved
      end
    }
  end

  def moderation_snapshot
    attributes.slice(*CONTENT_FIELDS).merge("type" => self.class.name, "id" => id)
  end

  def approved?
    moderation_status == "approved"
  end

  private

  def set_submission_status
    self.moderation_status = "pending" if moderation_status == "approved" && created_by && !created_by.admin?
  end

  def resubmit_changed_content
    @resubmitted_from = nil
    return unless (changes.keys & CONTENT_FIELDS).any?

    @resubmitted_from = moderation_status
    self.moderation_revision += 1
    self.moderation_status = "pending" if created_by
  end

  def record_submission
    action = moderation_status == "pending" ? "submitted" : moderation_status
    moderation_decisions.create!(actor: created_by, action: action,
      to_status: moderation_status, revision: moderation_revision, snapshot: moderation_snapshot,
      reason: approved? ? "Trusted creation" : nil)
  end

  def record_resubmission
    return unless @resubmitted_from

    action = moderation_status == "pending" ? "submitted" : moderation_status
    moderation_decisions.create!(actor: moderation_editor, action: action, from_status: @resubmitted_from,
      to_status: moderation_status, revision: moderation_revision, snapshot: moderation_snapshot, reason: "Content changed")
  end
end
