class ShoutOutDraft < ApplicationRecord
  belongs_to :ace
  belongs_to :target, polymorphic: true, optional: true

  include ShoutOutMessage
  has_many :shout_outs, dependent: :nullify
  validate :recorded_target

  private

  def recorded_target
    errors.add(:target, "must be a recorded player or team") unless %w[Player Team].include?(target_type) && target
  end
end
