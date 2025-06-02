class Division < ApplicationRecord
  belongs_to :conference
  has_many :memberships, dependent: :destroy
  has_many :teams, through: :memberships
  has_many :ratings, as: :target, dependent: :destroy
  
  validates :name, presence: true
  
  def display_name
    if abbreviation.present?
      "#{name} (#{abbreviation})"
    else
      name
    end
  end
  
  # Rating methods
  
  # Get ratings for this division on a specific spectrum
  # @param spectrum [Spectrum] The spectrum to get ratings for
  # @return [ActiveRecord::Relation] Ratings for this division on the spectrum
  def ratings_on(spectrum)
    ratings.active.where(spectrum: spectrum)
  end
  
  # Allow all attributes to be searchable with Ransack
  def self.ransackable_attributes(auth_object = nil)
    column_names
  end
  
  # Allow all associations to be searchable with Ransack
  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s }
  end
  
  # Get the average rating for this division on a specific spectrum
  # @param spectrum [Spectrum] The spectrum to get the average rating for
  # @return [Float, nil] The average rating or nil if no ratings exist
  def average_rating_on(spectrum)
    ratings = ratings_on(spectrum)
    ratings.average(:value)&.to_f
  end
end
