class City < ApplicationRecord
  belongs_to :state
  has_many :players, foreign_key: :birth_city_id
  has_many :stadia
  has_many :teams, through: :stadia

  delegate :country, to: :state
end
