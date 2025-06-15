class Year < ApplicationRecord
  has_many :seasons, dependent: :destroy
  
  validates :number, presence: true, uniqueness: true
  validates :number, numericality: { greater_than: 1799, less_than: 3000 }
  
  scope :recent, -> { order(number: :desc) }
  scope :chronological, -> { order(:number) }
  scope :seeded, -> { where.not(seed_version: nil) }
  
  def name
    number.to_s
  end
  
  def to_s
    number.to_s
  end
end
