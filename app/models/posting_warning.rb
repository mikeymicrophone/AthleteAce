class PostingWarning < ApplicationRecord
  self.table_name = "warnings"
  belongs_to :ace
  belongs_to :moderator, class_name: "Ace", optional: true
  belongs_to :subject, polymorphic: true, optional: true
  validates :reason, presence: true, length: { maximum: 2000 }
  validates :request_key, presence: true, length: { maximum: 128 }

  def readonly?
    persisted?
  end
end
