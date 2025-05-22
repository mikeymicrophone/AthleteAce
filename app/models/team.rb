class Team < ApplicationRecord
  belongs_to :league
  belongs_to :stadium, optional: true
  has_many :players
  has_many :ratings, as: :target, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_one :active_membership, -> { where(active: true) }, class_name: 'Membership'
  has_one :division, through: :active_membership
  has_one :conference, through: :division
  
  delegate :sport, to: :league
  delegate :city, :state, :country, to: :stadium

  def name
    "#{territory} #{mascot}"
  end
  
  # Rating methods
  
  # Get all ratings for this team
  # @return [ActiveRecord::Relation] All ratings for this team
  def all_ratings
    ratings
  end
  
  # Get ratings for this team on a specific spectrum
  # @param spectrum [Spectrum] The spectrum to get ratings for
  # @return [ActiveRecord::Relation] Ratings for this team on the spectrum
  def ratings_on(spectrum)
    ratings.active.where(spectrum: spectrum)
  end
  
  # Get the average rating value for this team on a spectrum
  # @param spectrum [Spectrum] The spectrum to get the average for
  # @return [Float, nil] The average rating or nil if no ratings
  def average_rating_on(spectrum)
    ratings = ratings_on(spectrum)
    return nil if ratings.empty?
    
    ratings.average(:value)&.to_f
  end
  
  # Get the normalized average rating (0-1) for this team on a spectrum
  # @param spectrum [Spectrum] The spectrum to get the average for
  # @return [Float, nil] The normalized average rating or nil if no ratings
  def normalized_average_rating_on(spectrum)
    avg = average_rating_on(spectrum)
    return nil if avg.nil?
    
    (avg + 10_000) / 20_000
  end
  
  # Define which attributes can be searched via Ransack
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "league_id", "mascot", "stadium_id", "territory", "updated_at"]
  end
  
  # Define which associations can be searched via Ransack
  def self.ransackable_associations(auth_object = nil)
    ["active_membership", "conference", "division", "league", "memberships", "players", "ratings", "stadium"]
  end
end
