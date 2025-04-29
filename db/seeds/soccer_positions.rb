puts "Seeding soccer positions..."

# Find soccer sport
soccer = Sport.find_by(name: "Soccer")

if soccer
  # Define standard soccer positions
  soccer_positions = [
    # Goalkeeper
    { 
      name: "Goalkeeper", 
      abbreviation: "GK", 
      description: "The player who defends the team's goal, the only player allowed to use hands within their penalty area. Responsible for organizing the defense and preventing goals."
    },
    
    # Defenders
    { 
      name: "Center Back", 
      abbreviation: "CB", 
      description: "Central defender whose primary responsibility is to prevent the opposition from scoring. Typically strong in the air and in tackles."
    },
    { 
      name: "Left Back", 
      abbreviation: "LB", 
      description: "Defender who plays on the left side of the defense. Responsible for defending against opposition wingers and supporting attacks on the left flank."
    },
    { 
      name: "Right Back", 
      abbreviation: "RB", 
      description: "Defender who plays on the right side of the defense. Responsible for defending against opposition wingers and supporting attacks on the right flank."
    },
    { 
      name: "Sweeper", 
      abbreviation: "SW", 
      description: "Defender who plays behind the defensive line, sweeping up any balls that get past the main defenders. Less common in modern soccer."
    },
    { 
      name: "Wing Back", 
      abbreviation: "WB", 
      description: "A hybrid defender/midfielder who plays wide on either flank, with significant attacking responsibilities in addition to defensive duties."
    },
    { 
      name: "Left Wing Back", 
      abbreviation: "LWB", 
      description: "Wing back who plays on the left side, combining defensive responsibilities with attacking support on the left flank."
    },
    { 
      name: "Right Wing Back", 
      abbreviation: "RWB", 
      description: "Wing back who plays on the right side, combining defensive responsibilities with attacking support on the right flank."
    },
    
    # Midfielders
    { 
      name: "Defensive Midfielder", 
      abbreviation: "DM", 
      description: "Midfielder who plays in front of the defense, focusing on breaking up opposition attacks and distributing the ball to more attacking players."
    },
    { 
      name: "Central Midfielder", 
      abbreviation: "CM", 
      description: "Midfielder who plays centrally, balancing defensive and offensive responsibilities. Often involved in building attacks and controlling the tempo of the game."
    },
    { 
      name: "Attacking Midfielder", 
      abbreviation: "AM", 
      description: "Midfielder who focuses primarily on creating scoring opportunities for forwards and contributing goals. Typically plays behind the strikers."
    },
    { 
      name: "Left Midfielder", 
      abbreviation: "LM", 
      description: "Midfielder who plays on the left side, providing width to the team's attack and supporting the left back defensively."
    },
    { 
      name: "Right Midfielder", 
      abbreviation: "RM", 
      description: "Midfielder who plays on the right side, providing width to the team's attack and supporting the right back defensively."
    },
    { 
      name: "Box-to-Box Midfielder", 
      abbreviation: "BBM", 
      description: "Energetic midfielder who contributes both defensively and offensively, covering large areas of the pitch from one penalty box to the other."
    },
    
    # Forwards
    { 
      name: "Center Forward", 
      abbreviation: "CF", 
      description: "Forward who plays centrally, primarily responsible for scoring goals. Often the focal point of the team's attack."
    },
    { 
      name: "Striker", 
      abbreviation: "ST", 
      description: "Forward whose main responsibility is scoring goals. Typically plays as the most advanced attacking player."
    },
    { 
      name: "Second Striker", 
      abbreviation: "SS", 
      description: "Forward who plays just behind the main striker, linking midfield and attack. Combines goal-scoring with creative playmaking."
    },
    { 
      name: "Left Winger", 
      abbreviation: "LW", 
      description: "Attacking player who plays on the left wing, providing width to the attack and creating scoring opportunities through crosses and dribbles."
    },
    { 
      name: "Right Winger", 
      abbreviation: "RW", 
      description: "Attacking player who plays on the right wing, providing width to the attack and creating scoring opportunities through crosses and dribbles."
    },
    { 
      name: "False Nine", 
      abbreviation: "F9", 
      description: "A center forward who drops deep into midfield, creating space for wingers and midfielders to exploit. Combines playmaking with goal-scoring."
    },
    
    # Specialized Roles
    { 
      name: "Libero", 
      abbreviation: "LIB", 
      description: "A defender who has freedom to move up into midfield, combining defensive duties with playmaking responsibilities."
    },
    { 
      name: "Regista", 
      abbreviation: "REG", 
      description: "A deep-lying playmaker who dictates the tempo of the game with precise passing and vision from a position in front of the defense."
    },
    { 
      name: "Trequartista", 
      abbreviation: "TRQ", 
      description: "A creative attacking midfielder or second striker who operates in the 'hole' between midfield and attack, known for technical skill and creativity."
    },
    { 
      name: "Inverted Winger", 
      abbreviation: "IW", 
      description: "A winger who plays on the opposite flank to their stronger foot, cutting inside to shoot rather than crossing from the byline."
    }
  ]
  
  # Create positions
  soccer.create_standard_positions(soccer_positions)
  
  # Assign positions to existing players based on their current_position field
  Player.where.not(current_position: [nil, ""]).find_each do |player|
    # Skip if player's team sport is not soccer
    next unless player.sport == soccer
    
    # Find matching position based on current_position field
    position_name = player.current_position
    position = soccer.positions.find_by("name = ? OR abbreviation = ?", position_name, position_name)
    
    # If no exact match, try to find a partial match
    if position.nil?
      position_name_parts = position_name.split(/[\s\-\/]/)
      position_name_parts.each do |part|
        next if part.length < 2 # Skip very short parts
        position = soccer.positions.find_by("name LIKE ? OR abbreviation LIKE ?", "%#{part}%", "%#{part}%")
        break if position
      end
    end
    
    # If still no match, use a default position based on common terms
    if position.nil?
      case position_name.downcase
      when /goal|keeper|goalie/
        position = soccer.positions.find_by(name: "Goalkeeper")
      when /defend|back/
        if position_name.downcase.include?("left")
          position = soccer.positions.find_by(name: "Left Back")
        elsif position_name.downcase.include?("right")
          position = soccer.positions.find_by(name: "Right Back")
        elsif position_name.downcase.include?("center") || position_name.downcase.include?("centre")
          position = soccer.positions.find_by(name: "Center Back")
        else
          position = soccer.positions.find_by(name: "Center Back") # Default defensive position
        end
      when /mid/
        if position_name.downcase.include?("attack")
          position = soccer.positions.find_by(name: "Attacking Midfielder")
        elsif position_name.downcase.include?("defen")
          position = soccer.positions.find_by(name: "Defensive Midfielder")
        elsif position_name.downcase.include?("left")
          position = soccer.positions.find_by(name: "Left Midfielder")
        elsif position_name.downcase.include?("right")
          position = soccer.positions.find_by(name: "Right Midfielder")
        else
          position = soccer.positions.find_by(name: "Central Midfielder") # Default midfield position
        end
      when /forward|striker|attack/
        if position_name.downcase.include?("left")
          position = soccer.positions.find_by(name: "Left Winger")
        elsif position_name.downcase.include?("right")
          position = soccer.positions.find_by(name: "Right Winger")
        elsif position_name.downcase.include?("center") || position_name.downcase.include?("centre")
          position = soccer.positions.find_by(name: "Center Forward")
        else
          position = soccer.positions.find_by(name: "Striker") # Default forward position
        end
      when /wing/
        if position_name.downcase.include?("left")
          position = soccer.positions.find_by(name: "Left Winger")
        elsif position_name.downcase.include?("right")
          position = soccer.positions.find_by(name: "Right Winger")
        else
          position = soccer.positions.find_by(name: "Right Winger") # Default wing position
        end
      else
        position = soccer.positions.find_by(name: "Central Midfielder") # Default fallback
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
  
  puts "Soccer positions seeded successfully!"
else
  puts "Soccer sport not found! Please seed sports first."
end
