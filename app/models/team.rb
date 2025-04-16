class Team < ApplicationRecord
  belongs_to :league
  belongs_to :stadium
end
