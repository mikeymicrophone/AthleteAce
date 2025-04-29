class Player < ApplicationRecord
  belongs_to :birth_city, optional: true
  belongs_to :birth_country, optional: true
  belongs_to :team
  delegate :sport, to: :team
  delegate :league, to: :team
  
  has_many :roles, dependent: :destroy
  has_many :positions, through: :roles
  
  def name
    "#{first_name} #{last_name}"
  end
  
  def primary_position
    roles.find_by(primary: true)&.position
  end
  
  def secondary_positions
    positions.where.not(id: primary_position&.id)
  end
  
  def add_position(position, primary: false)
    # If setting a new primary position, unset any existing primary position
    if primary
      roles.where(primary: true).update_all(primary: false)
    end
    
    # Create the new role
    roles.create(position: position, primary: primary)
  end
end
