class Spectrum < ApplicationRecord
  has_many :ratings, dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
  validates :low_label, presence: true
  validates :high_label, presence: true
  
  # Find or create default spectrums
  def self.defaults
    [
      { name: 'Familiarity', description: 'How familiar you are with this entity', low_label: 'Unfamiliar', high_label: 'Very Familiar' },
      { name: 'Skill', description: 'How skilled you think this entity is', low_label: 'Unskilled', high_label: 'Highly Skilled' },
      { name: 'Grit', description: 'How much determination and perseverance this entity shows', low_label: 'Low Grit', high_label: 'High Grit' },
      { name: 'Attractiveness', description: 'How attractive you find this entity', low_label: 'Unattractive', high_label: 'Very Attractive' },
      { name: 'Humor', description: 'How funny you find this entity', low_label: 'Not Funny', high_label: 'Very Funny' },
      { name: 'Wisdom', description: 'How wise you find this entity', low_label: 'Unwise', high_label: 'Very Wise' },
      { name: 'Affinity', description: 'How much you like this entity', low_label: 'Dislike', high_label: 'Love' }
    ].each do |attributes|
      find_or_create_by(name: attributes[:name]) do |spectrum|
        spectrum.assign_attributes(attributes)
      end
    end
  end
end
