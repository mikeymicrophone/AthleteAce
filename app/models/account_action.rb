class AccountAction < ApplicationRecord
  ACTIONS = %w[role suspend reactivate password_reset].freeze
  belongs_to :ace, optional: true
  belongs_to :actor, class_name: "Ace", optional: true
  validates :action, inclusion: { in: ACTIONS }
  validates :ace_name, :reason, :request_key, presence: true
  validates :reason, length: { maximum: 2000 }
  validates :request_key, length: { maximum: 128 }
  after_create_commit do
    AdminPasswordResetJob.perform_later(id) if action == "password_reset"
  end

  def readonly?
    persisted?
  end
end
