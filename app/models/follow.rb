class Follow < ApplicationRecord
  belongs_to :ace
  belongs_to :followable, polymorphic: true

  validates :followable_type, inclusion: { in: %w[Team Player] }
end
