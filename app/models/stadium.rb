class Stadium < ApplicationRecord
  belongs_to :city
  has_many :teams
end
