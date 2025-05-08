class League < ApplicationRecord
  belongs_to :sport
  belongs_to :jurisdiction, polymorphic: true
  has_many :teams
  has_many :players, through: :teams
  has_many :stadia, through: :teams
  has_many :conferences, dependent: :destroy
  has_many :divisions, through: :conferences
end
