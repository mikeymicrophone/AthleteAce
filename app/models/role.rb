class Role < ApplicationRecord
  belongs_to :player
  belongs_to :position
  
  validates :player_id, uniqueness: { scope: :position_id, message: "already has this position" }
  validates :primary, inclusion: { in: [true, false] }
  
  # Ensure only one primary position per player
  validate :only_one_primary_per_player, if: -> { primary? }
  
  # Ensure position belongs to the same sport as the player's team
  validate :position_matches_player_sport
  
  private
  
  def only_one_primary_per_player
    if player.roles.where(primary: true).where.not(id: id).exists?
      errors.add(:primary, "position already exists for this player")
    end
  end
  
  def position_matches_player_sport
    return unless player && position
    
    unless player.sport == position.sport
      errors.add(:position, "must belong to the same sport as the player's team")
    end
  end
end
