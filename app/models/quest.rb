class Quest < ApplicationRecord
  has_many :achievements, dependent: :destroy
  has_many :goals, dependent: :destroy
  has_many :aces, through: :goals
  
  validates :name, presence: true
  validates :description, presence: true
end
