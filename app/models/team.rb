class Team < ApplicationRecord
  belongs_to :league
  belongs_to :stadium, optional: true
  has_many :players

  delegate :city, :state, :country, to: :stadium
end
