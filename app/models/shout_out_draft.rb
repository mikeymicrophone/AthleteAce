class ShoutOutDraft < ApplicationRecord
  belongs_to :ace
  belongs_to :target, polymorphic: true, optional: true

  normalizes :message, with: ->(value) { value.to_s.gsub(/\A\p{White_Space}+|\p{White_Space}+\z/, "") }
  validates :message, presence: true, length: { maximum: 200 }
  validate :recorded_target
  validate :message_without_links

  private

  def recorded_target
    errors.add(:target, "must be a recorded player or team") unless %w[Player Team].include?(target_type) && target
  end

  def message_without_links
    if message.to_s.match?(%r{https?://|www\.|[\p{L}\p{N}][\p{L}\p{N}-]*(?:\.[\p{L}\p{N}-]+)*\.[\p{L}]{2,}(?:\b|/)}i)
      errors.add(:message, "cannot include links or web addresses")
    end
  end
end
