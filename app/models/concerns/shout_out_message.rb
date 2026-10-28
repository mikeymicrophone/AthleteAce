module ShoutOutMessage
  extend ActiveSupport::Concern

  included do
    normalizes :message, with: ->(value) { value.to_s.gsub(/\A\p{White_Space}+|\p{White_Space}+\z/, "") }
    validates :message, presence: true, length: { maximum: 200 }
    validate :message_without_links
  end

  private

  def message_without_links
    if message.to_s.match?(%r{https?://|www\.|[\p{L}\p{N}][\p{L}\p{N}-]*(?:\.[\p{L}\p{N}-]+)*\.[\p{L}]{2,}(?:\b|/)}i)
      errors.add(:message, "cannot include links or web addresses")
    end
  end
end
