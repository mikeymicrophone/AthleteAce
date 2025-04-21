class Country < ApplicationRecord
  has_many :states
  has_many :cities, through: :states
  has_many :players, foreign_key: :birth_country_id
end
