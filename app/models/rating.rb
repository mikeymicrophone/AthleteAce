class Rating < ApplicationRecord
  belongs_to :ace
  belongs_to :spectrum
  belongs_to :target, polymorphic: true
  
  # Validations
  validates :value, presence: true, 
                   numericality: { 
                     only_integer: true, 
                     greater_than_or_equal_to: -10_000, 
                     less_than_or_equal_to: 10_000 
                   }
  validates :ace_id, uniqueness: { 
    scope: [:spectrum_id, :target_type, :target_id],
    message: "has already rated this target on this spectrum" 
  }
  
  # Scopes
  scope :by_ace, ->(ace) { where(ace: ace) }
  scope :by_spectrum, ->(spectrum) { where(spectrum: spectrum) }
  scope :for_target, ->(target) { where(target: target) }
  scope :positive, -> { where('value > 0') }
  scope :negative, -> { where('value < 0') }
  scope :neutral, -> { where(value: 0) }
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
  default_scope { active }
  
  # Methods
  def positive?
    value > 0
  end
  
  def negative?
    value < 0
  end
  
  def neutral?
    value == 0
  end
  
  # Normalized value between 0 and 1 for display purposes
  def normalized_value
    (value.to_f + 10_000) / 20_000
  end
  
  # Percentage value (0-100) for display purposes
  def percentage_value
    ((value.to_f + 10_000) / 20_000 * 100).round
  end
end
