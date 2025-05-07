class Player < ApplicationRecord
  belongs_to :birth_city, optional: true
  belongs_to :birth_country, optional: true
  belongs_to :team
  delegate :sport, to: :team
  delegate :league, to: :team
  
  has_many :roles, dependent: :destroy
  has_many :positions, through: :roles
  has_many :ratings, as: :target, dependent: :destroy
  
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
  
  # Rating methods
  
  # Get all ratings for this player
  # @return [ActiveRecord::Relation] All ratings for this player
  def all_ratings
    ratings
  end
  
  # Get ratings for this player on a specific spectrum
  # @param spectrum [Spectrum] The spectrum to get ratings for
  # @return [ActiveRecord::Relation] Ratings for this player on the spectrum
  def ratings_on(spectrum)
    ratings.where(spectrum: spectrum)
  end
  
  # Get the average rating value for this player on a spectrum
  # @param spectrum [Spectrum] The spectrum to get the average for
  # @return [Float, nil] The average rating or nil if no ratings
  def average_rating_on(spectrum)
    ratings = ratings_on(spectrum)
    return nil if ratings.empty?
    
    ratings.average(:value)&.to_f
  end
  
  # Get the normalized average rating (0-1) for this player on a spectrum
  # @param spectrum [Spectrum] The spectrum to get the average for
  # @return [Float, nil] The normalized average rating or nil if no ratings
  def normalized_average_rating_on(spectrum)
    avg = average_rating_on(spectrum)
    return nil if avg.nil?
    
    (avg + 10_000) / 20_000
  end
end
