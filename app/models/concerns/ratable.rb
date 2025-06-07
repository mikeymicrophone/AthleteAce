module Ratable
  extend ActiveSupport::Concern

  included do
    has_many :ratings, as: :target, dependent: :destroy
  end

  def ratings_on(spectrum)
    ratings.active.where(spectrum: spectrum)
  end

  def average_rating_on(spectrum)
    ratings = ratings_on(spectrum)
    return nil if ratings.empty?
    
    ratings.average(:value)&.to_f
  end

  def normalized_average_rating_on(spectrum)
    avg = average_rating_on(spectrum)
    return nil if avg.nil?
    
    (avg + 10_000) / 20_000
  end
end