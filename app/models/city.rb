class City < ApplicationRecord
  belongs_to :state
  has_many :players, foreign_key: :birth_city_id
  has_many :stadiums
  has_many :teams, through: :stadiums

  delegate :country, to: :state
end
