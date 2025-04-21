class State < ApplicationRecord
  belongs_to :country
  has_many :cities
  has_many :players, through: :cities
  has_many :stadia, through: :cities
end
