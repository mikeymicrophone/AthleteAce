class DecisionEvaluation < ApplicationRecord
  belongs_to :subject, polymorphic: true, optional: true
  validates :provider, inclusion: { in: %w[jev openai] }
  validates :status, inclusion: { in: %w[queued running completed failed unavailable] }
  validates :comparison_key, :model, :purpose, :policy_version, presence: true
  validates :comparison_key, length: { maximum: 128 }
  validates :input_tokens, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
