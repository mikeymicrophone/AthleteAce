class Player < ApplicationRecord
  include Ratable
  
  belongs_to :birth_city, optional: true
  belongs_to :birth_country, class_name: 'Country', optional: true
  belongs_to :team
  delegate :sport, to: :team
  delegate :league, to: :team
  
  has_many :roles, dependent: :destroy
  has_many :positions, through: :roles
  
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
  
  def self.ransackable_attributes(auth_object = nil)
    ["active", "bio", "birth_city_id", "birth_country_id", "birthdate", "created_at", "current_position", "debut_year", "draft_year", "first_name", "full_name", "id", "last_name", "league_name", "nicknames", "photo_urls", "position_name", "sport_name", "team_id", "team_name", "team_territory", "updated_at"]
  end
  
  def self.ransackable_associations(auth_object = nil)
    ["birth_city", "birth_country", "positions", "ratings", "roles", "team"]
  end
  
  scope :sampled, ->(n = 50) { order(Arel.sql('RANDOM()')).limit(n) }
  
  def name
    "#{first_name} #{last_name}"
  end
  alias_method :full_name, :name
  
  def photo_url
    photo_urls&.first
  end
  alias_method :logo_url, :photo_url

  def primary_position
    roles.find_by(primary: true)&.position
  end
  alias_method :position, :primary_position
  
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
  
  # def all_ratings
  #   ratings
  # end
  

  def calculate_attempt_stats(attempts)
    total_attempts = attempts.size
    correct_attempts = attempts.count(&:correct?)

    one_week_ago = 1.week.ago
    recent_attempts = attempts.where("created_at >= ?", one_week_ago)
    recent_total = recent_attempts.size
    recent_correct = recent_attempts.count(&:correct?)

    {
      total_attempts: total_attempts,
      correct_attempts: correct_attempts,
      accuracy: total_attempts > 0 ? (correct_attempts.to_f / total_attempts * 100).round : 0,
      recent_total: recent_total,
      recent_correct: recent_correct,
      recent_accuracy: recent_total > 0 ? (recent_correct.to_f / recent_total * 100).round : 0
    }
  end
end
