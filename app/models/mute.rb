class Mute < ApplicationRecord
  DURATIONS = { "24 hours" => 24, "7 days" => 168, "30 days" => 720 }.freeze
  belongs_to :ace
  belongs_to :moderator, class_name: "Ace", optional: true
  belongs_to :ended_by, class_name: "Ace", optional: true
  belongs_to :hidden_shout_out, class_name: "ShoutOut", optional: true
  attr_readonly :ace_id, :moderator_id, :reason, :note, :duration_hours, :starts_at, :ends_at, :hidden_shout_out_id, :request_key
  validates :reason, presence: true, length: { maximum: 2000 }
  validates :note, :end_reason, length: { maximum: 2000 }
  validates :end_reason, presence: true, if: :ended_at?
  validates :duration_hours, inclusion: { in: DURATIONS.values }
  validates :starts_at, :ends_at, presence: true
  validates :request_key, presence: true, length: { maximum: 128 }
  scope :active, -> { where(ended_at: nil).where("starts_at <= ? AND ends_at > ?", Time.current, Time.current) }

  def active?
    ended_at.nil? && starts_at <= Time.current && ends_at > Time.current
  end
end
