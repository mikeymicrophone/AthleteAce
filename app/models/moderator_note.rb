class ModeratorNote < ApplicationRecord
  belongs_to :ace
  belongs_to :moderator, class_name: "Ace", optional: true
  validates :body, presence: true, length: { maximum: 2000 }
  validates :request_key, presence: true, length: { maximum: 128 }

  def readonly?
    persisted?
  end
end
