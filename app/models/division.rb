class Division < ApplicationRecord
  belongs_to :conference
  has_many :memberships, dependent: :destroy
  has_many :teams, through: :memberships
  
  validates :name, presence: true
  validates :abbreviation, presence: true
  
  def display_name
    "#{name} (#{abbreviation})"
  end
end
