class Team < ApplicationRecord
  belongs_to :league
  belongs_to :stadium
  has_many :players
end
