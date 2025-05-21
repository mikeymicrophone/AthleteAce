class Player < ApplicationRecord
  belongs_to :birth_city, optional: true
  belongs_to :birth_country, class_name: 'Country', optional: true
  belongs_to :team
  delegate :sport, to: :team
  delegate :league, to: :team
  
  has_many :roles, dependent: :destroy
  has_many :positions, through: :roles
  has_many :ratings, as: :target, dependent: :destroy
  
  # Ransack configuration
  # Define searchable attributes and associations
  ransacker :full_name do
    Arel.sql("CONCAT(players.first_name, ' ', players.last_name)")
  end
  
  # Allow searching and sorting by team name
  ransacker :team_name do
    Arel.sql("teams.mascot")
  end
  
  # Allow searching and sorting by team territory
  ransacker :team_territory do
    Arel.sql("teams.territory")
  end
  
  # Allow searching and sorting by league name
  ransacker :league_name do
    Arel.sql("leagues.name")
  end
  
  # Allow searching and sorting by sport name
  ransacker :sport_name do
    Arel.sql("sports.name")
  end
  
  # Allow searching and sorting by position name
  ransacker :position_name do
    Arel.sql("positions.name")
  end
  
  # Define which attributes can be searched via Ransack
  def self.ransackable_attributes(auth_object = nil)
    ["active", "bio", "birth_city_id", "birth_country_id", "birthdate", "created_at", "current_position", "debut_year", "draft_year", "first_name", "full_name", "id", "last_name", "league_name", "nicknames", "photo_urls", "position_name", "sport_name", "team_id", "team_name", "team_territory", "updated_at"]
  end
  
  # Define which associations can be searched via Ransack
  def self.ransackable_associations(auth_object = nil)
    ["birth_city", "birth_country", "positions", "ratings", "roles", "team"]
  end
  
  # DB-level sampling scope – avoids pulling full result sets into memory
  scope :sampled, ->(n = 50) { order(Arel.sql('RANDOM()')).limit(n) }
  
  def name
    "#{first_name} #{last_name}"
  end
  alias_method :full_name, :name
  
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
