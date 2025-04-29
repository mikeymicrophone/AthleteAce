puts "Seeding hockey positions..."

# Find hockey sport
hockey = Sport.find_by(name: "Hockey")

if hockey
  # Define standard hockey positions
  hockey_positions = [
    # Forward Positions
    { 
      name: "Center", 
      abbreviation: "C", 
      description: "The forward who plays in the middle of the ice, responsible for faceoffs and playmaking. Centers typically have strong two-way play, helping on both offense and defense."
    },
    { 
      name: "Left Wing", 
      abbreviation: "LW", 
      description: "The forward who plays on the left side of the ice. Left wingers are typically responsible for scoring goals and forechecking in the offensive zone."
    },
    { 
      name: "Right Wing", 
      abbreviation: "RW", 
      description: "The forward who plays on the right side of the ice. Right wingers are typically responsible for scoring goals and forechecking in the offensive zone."
    },
    { 
      name: "Forward", 
      abbreviation: "F", 
      description: "A general position for players who can play any of the forward positions (center, left wing, or right wing)."
    },
    
    # Defensive Positions
    { 
      name: "Defenseman", 
      abbreviation: "D", 
      description: "Players who primarily focus on preventing the opposing team from scoring. They typically play behind the forwards and in front of the goaltender."
    },
    { 
      name: "Left Defenseman", 
      abbreviation: "LD", 
      description: "Defenseman who primarily plays on the left side of the ice."
    },
    { 
      name: "Right Defenseman", 
      abbreviation: "RD", 
      description: "Defenseman who primarily plays on the right side of the ice."
    },
    
    # Goaltender
    { 
      name: "Goaltender", 
      abbreviation: "G", 
      description: "The player responsible for directly preventing the opposing team from scoring by stopping shots on the goal. The last line of defense."
    },
    
    # Specialized Roles
    { 
      name: "Power Play Specialist", 
      abbreviation: "PPS", 
      description: "A player who excels in power play situations when their team has a numerical advantage due to opponent penalties."
    },
    { 
      name: "Penalty Kill Specialist", 
      abbreviation: "PKS", 
      description: "A player who excels in penalty kill situations when their team is at a numerical disadvantage due to penalties."
    },
    { 
      name: "Two-Way Forward", 
      abbreviation: "TWF", 
      description: "A forward who excels at both offensive and defensive aspects of the game."
    },
    { 
      name: "Enforcer", 
      abbreviation: "ENF", 
      description: "A player known for their physical play and fighting ability, often protecting star players on their team."
    },
    { 
      name: "Offensive Defenseman", 
      abbreviation: "OFD", 
      description: "A defenseman who contributes significantly to offensive play, often joining rushes and participating in power plays."
    },
    { 
      name: "Defensive Defenseman", 
      abbreviation: "DFD", 
      description: "A defenseman who focuses primarily on defensive responsibilities, shot blocking, and physical play in their own zone."
    }
  ]
  
  # Create positions
  hockey.create_standard_positions(hockey_positions)
  
  # Assign positions to existing players based on their current_position field
  Player.where.not(current_position: [nil, ""]).find_each do |player|
    # Skip if player's team sport is not hockey
    next unless player.sport == hockey
    
    # Find matching position based on current_position field
    position_name = player.current_position
    position = hockey.positions.find_by("name = ? OR abbreviation = ?", position_name, position_name)
    
    # If no exact match, try to find a partial match
    if position.nil?
      position_name_parts = position_name.split(/[\s\-\/]/)
      position_name_parts.each do |part|
        next if part.length < 2 # Skip very short parts
        position = hockey.positions.find_by("name LIKE ? OR abbreviation LIKE ?", "%#{part}%", "%#{part}%")
        break if position
      end
    end
    
    # If still no match, use a default position based on common terms
    if position.nil?
      case position_name.downcase
      when /center|centre/
        position = hockey.positions.find_by(name: "Center")
      when /wing/
        if position_name.downcase.include?("left")
          position = hockey.positions.find_by(name: "Left Wing")
        elsif position_name.downcase.include?("right")
          position = hockey.positions.find_by(name: "Right Wing")
        else
          position = hockey.positions.find_by(name: "Forward")
        end
      when /defense|defence|defenceman|defenseman/
        position = hockey.positions.find_by(name: "Defenseman")
      when /goalie|goaltender|goal/
        position = hockey.positions.find_by(name: "Goaltender")
      else
        position = hockey.positions.find_by(name: "Forward") # Default fallback
      end
    end
    
    # Create role with this position as primary
    if position
      player.roles.find_or_create_by(position: position) do |role|
        role.primary = true
      end
      puts "Assigned #{position.name} to #{player.name}"
    end
  end
  
  puts "Hockey positions seeded successfully!"
else
  puts "Hockey sport not found! Please seed sports first."
end
