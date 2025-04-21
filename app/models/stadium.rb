class Stadium < ApplicationRecord
  belongs_to :city
  has_many :teams
  has_many :players, through: :teams
  has_many :leagues, through: :teams
end
