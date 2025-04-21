class City < ApplicationRecord
  belongs_to :state
  belongs_to :country
  has_many :players, foreign_key: :birth_city_id
  has_many :stadia
  has_many :teams, through: :stadia
end
