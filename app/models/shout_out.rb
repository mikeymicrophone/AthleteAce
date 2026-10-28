class ShoutOut < ApplicationRecord
  include Moderatable
  include ShoutOutMessage
  belongs_to :target, polymorphic: true, optional: true
  belongs_to :shout_out_draft, optional: true
  has_many :stripe_purchases, dependent: :restrict_with_error
  has_many :shout_out_reports, dependent: :restrict_with_error
  has_many :shout_out_reactions, dependent: :delete_all
  scope :live, -> { approved.where(funding_status: "spent") }
  after_update_commit :refresh_public_feed, if: -> { saved_change_to_moderation_status? && saved_change_to_moderation_status.include?("approved") }
  scope :matching_text, ->(query) {
    joins(:created_by).where("shout_outs.target_name ILIKE :term OR shout_outs.message ILIKE :term OR CONCAT_WS(' ', '@' || aces.username, aces.display_name) ILIKE :term",
      term: "%#{sanitize_sql_like(query)}%")
  }
  attr_readonly :message, :bid_cents, :target_type, :target_id, :target_name, :created_by_id, :payment_method
  validates :bid_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :payment_method, inclusion: { in: %w[credit stripe] }
  validates :moderation_status, inclusion: { in: [ "pending" ] }, on: :create
  validate(on: :create) { errors.add(:target, "must be a recorded player or team") unless %w[Player Team].include?(target_type) && target }

  def name
    "#{target_name} shout-out"
  end

  def reserve_credit!
    with_lock(requires_new: true) do
      return unless funding_status == "unfunded"
      CreditAccount.for(created_by).apply!(source: self, kind: "reserve", available_delta: -bid_cents, reserved_delta: bid_cents)
      update!(funding_status: "reserved")
      record_submission
    end
  end

  def settle_review!(action)
    if action == "reopen" || funding_status == "refunded"
      raise Moderation::Review::Conflict, "This post was credited back. Submit a new funded shout-out for another review."
    end
    if funding_status == "unfunded"
      raise Moderation::Review::Conflict, "Payment has not completed."
    end
    raise Moderation::Review::Conflict, "The target no longer exists. Reject this submission to release its credit." if action == "approve" && !target
    account = CreditAccount.for(created_by)
    case action
    when "approve"
      account.apply!(source: self, kind: "capture", available_delta: 0, reserved_delta: -bid_cents)
      update!(funding_status: "spent")
    when "reject"
      account.apply!(source: self, kind: "release", available_delta: bid_cents, reserved_delta: -bid_cents)
      update!(funding_status: "refunded")
    when "hide"
      account.apply!(source: self, kind: "refund", available_delta: bid_cents)
      update!(funding_status: "refunded")
    end
  end

  private

  def refresh_public_feed
    Turbo::StreamsChannel.broadcast_refresh_to "public_shout_outs", request_id: nil
  end

  def record_submission
    super unless funding_status == "unfunded"
  end
end
