puts "Seeding basketball positions..."

# Find basketball sport
basketball = Sport.find_by(name: "Basketball")

if basketball
  # Define standard basketball positions
  basketball_positions = [
    { 
      name: "Point Guard", 
      abbreviation: "PG", 
      description: "The point guard is typically the team's best ball handler and passer, responsible for organizing the team's offense and setting up scoring opportunities for teammates."
    },
    { 
      name: "Shooting Guard", 
      abbreviation: "SG", 
      description: "The shooting guard is usually a good perimeter shooter and scorer, often serving as a secondary ball handler and perimeter defender."
    },
    { 
      name: "Small Forward", 
      abbreviation: "SF", 
      description: "The small forward is typically a versatile player who can score from inside and outside, rebound, and defend multiple positions."
    },
    { 
      name: "Power Forward", 
      abbreviation: "PF", 
      description: "The power forward typically plays near the basket, providing rebounding, interior defense, and scoring in the post, though modern power forwards often have perimeter skills as well."
    },
    { 
      name: "Center", 
      abbreviation: "C", 
      description: "The center is usually the tallest player on the team, providing rebounding, shot blocking, and interior scoring."
    },
    { 
      name: "Guard-Forward", 
      abbreviation: "G-F", 
      description: "A versatile player who can play both guard and forward positions, typically with good perimeter skills and size."
    },
    { 
      name: "Forward-Center", 
      abbreviation: "F-C", 
      description: "A player who can play both forward and center positions, typically with good size and a mix of perimeter and post skills."
    },
    { 
      name: "Forward", 
      abbreviation: "F", 
      description: "A general position for players who can play either small forward or power forward roles."
    },
    { 
      name: "Guard", 
      abbreviation: "G", 
      description: "A general position for players who can play either point guard or shooting guard roles."
    }
  ]
  
  # Create positions
  basketball.create_standard_positions(basketball_positions)
  
  # Assign positions to existing players based on their current_position field
  Player.where.not(current_position: [nil, ""]).find_each do |player|
    # Skip if player's team sport is not basketball
    next unless player.sport == basketball
    
    # Find matching position based on current_position field
    position_name = player.current_position
    position = basketball.positions.find_by("name = ? OR abbreviation = ?", position_name, position_name)
    
    # If no exact match, try to find a partial match
    if position.nil?
      position_name_parts = position_name.split('-')
      position_name_parts.each do |part|
        position = basketball.positions.find_by("name LIKE ? OR abbreviation LIKE ?", "%#{part}%", "%#{part}%")
        break if position
      end
    end
    
    # If still no match, use a default position
    position ||= basketball.positions.find_by(name: "Forward")
    
    # Create role with this position as primary
    if position
      player.roles.find_or_create_by(position: position) do |role|
        role.primary = true
      end
      puts "Assigned #{position.name} to #{player.name}"
    end
  end
  
  puts "Basketball positions seeded successfully!"
else
  puts "Basketball sport not found! Please seed sports first."
end
