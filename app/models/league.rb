class League < ApplicationRecord
  belongs_to :sport
  has_many :teams
end
