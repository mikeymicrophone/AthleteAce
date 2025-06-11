class Year < ApplicationRecord
  validates :number, presence: true, uniqueness: true
  validates :number, numericality: { greater_than: 1799, less_than: 3000 }
  
  scope :recent, -> { order(number: :desc) }
  scope :chronological, -> { order(:number) }
  
  def name
    number.to_s
  end
  
  def to_s
    number.to_s
  end
end
