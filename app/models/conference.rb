class Conference < ApplicationRecord
  belongs_to :league
  has_many :divisions, dependent: :destroy
  has_many :teams, through: :divisions
  
  validates :name, presence: true
  validates :abbreviation, presence: true
  
  def display_name
    "#{name} (#{abbreviation})"
  end
end
