class Division < ApplicationRecord
  belongs_to :conference
  has_many :memberships, dependent: :destroy
  has_many :teams, through: :memberships
  has_many :ratings, as: :target, dependent: :destroy
  has_one :league, through: :conference
  
  validates :name, presence: true
  
  def display_name
    if abbreviation.present?
      "#{name} (#{abbreviation})"
    else
      name
    end
  end
  
  def ratings_on spectrum
    ratings.active.where spectrum: spectrum
  end
  
  def self.ransackable_attributes auth_object = nil
    column_names
  end
  
  def self.ransackable_associations auth_object = nil
    reflect_on_all_associations.map { |a| a.name.to_s }
  end
  
  def average_rating_on spectrum
    ratings = ratings_on spectrum
    ratings.average(:value)&.to_f
  end
end
