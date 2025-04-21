class Team < ApplicationRecord
  belongs_to :league
  belongs_to :stadium
  has_many :players
  has_many :leagues, through: :players
  has_many :cities, through: :stadium
end
