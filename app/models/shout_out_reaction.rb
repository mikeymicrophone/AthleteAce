class ShoutOutReaction < ApplicationRecord
  KINDS = { "fire" => "Fire", "love" => "Love", "legend" => "Legend" }.freeze
  belongs_to :shout_out
  belongs_to :ace
  validates :kind, inclusion: { in: KINDS.keys }
end
