class Sport < ApplicationRecord
  has_many :leagues
  has_many :teams, through: :leagues
  has_many :players, through: :teams
end
