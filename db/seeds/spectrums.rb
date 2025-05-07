# Create default spectrums
puts "Creating default spectrums..."

default_spectrums = [
  { 
    name: 'Familiarity', 
    description: 'How familiar you are with this entity', 
    low_label: 'Unfamiliar', 
    high_label: 'Very Familiar' 
  },
  { 
    name: 'Skill', 
    description: 'How skilled you think this entity is', 
    low_label: 'Unskilled', 
    high_label: 'Highly Skilled' 
  },
  { 
    name: 'Grit', 
    description: 'How much determination and perseverance this entity shows', 
    low_label: 'Low Grit', 
    high_label: 'High Grit' 
  },
  { 
    name: 'Attractiveness', 
    description: 'How attractive you find this entity', 
    low_label: 'Unattractive', 
    high_label: 'Very Attractive' 
  },
  { 
    name: 'Humor', 
    description: 'How funny you find this entity', 
    low_label: 'Not Funny', 
    high_label: 'Very Funny' 
  },
  { 
    name: 'Wisdom', 
    description: 'How wise you find this entity', 
    low_label: 'Unwise', 
    high_label: 'Very Wise' 
  }
]

default_spectrums.each do |attributes|
  spectrum = Spectrum.find_or_initialize_by(name: attributes[:name])
  spectrum.assign_attributes(attributes)
  spectrum.save!
  puts "  Created spectrum: #{spectrum.name}"
end

puts "Created #{Spectrum.count} spectrums"
