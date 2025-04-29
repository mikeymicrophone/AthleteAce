puts "Seeding baseball positions..."

# Find baseball sport
baseball = Sport.find_by(name: "Baseball")

if baseball
  # Define standard baseball positions
  baseball_positions = [
    { 
      name: "Pitcher", 
      abbreviation: "P", 
      description: "The player who throws the ball to the batter from the pitcher's mound. Responsible for getting batters out through strikeouts or inducing weak contact."
    },
    { 
      name: "Catcher", 
      abbreviation: "C", 
      description: "Positioned behind home plate, the catcher receives pitches, calls the game, and is responsible for defensive strategy and controlling the running game."
    },
    { 
      name: "First Baseman", 
      abbreviation: "1B", 
      description: "Defends first base and is often a power hitter with good fielding skills to receive throws from infielders."
    },
    { 
      name: "Second Baseman", 
      abbreviation: "2B", 
      description: "Defends second base, turns double plays with the shortstop, and typically has good range and quick hands."
    },
    { 
      name: "Third Baseman", 
      abbreviation: "3B", 
      description: "Defends third base, requires quick reflexes and a strong arm to throw across the diamond to first base."
    },
    { 
      name: "Shortstop", 
      abbreviation: "SS", 
      description: "Positioned between second and third base, usually the most athletic infielder with range, arm strength, and defensive skills."
    },
    { 
      name: "Left Fielder", 
      abbreviation: "LF", 
      description: "Defends the left portion of the outfield, typically with good speed and arm strength."
    },
    { 
      name: "Center Fielder", 
      abbreviation: "CF", 
      description: "Covers the middle portion of the outfield, usually the fastest outfielder with the best range and defensive skills."
    },
    { 
      name: "Right Fielder", 
      abbreviation: "RF", 
      description: "Defends the right portion of the outfield, typically with the strongest arm among outfielders."
    },
    { 
      name: "Designated Hitter", 
      abbreviation: "DH", 
      description: "In American League games, bats in place of the pitcher but does not play a defensive position."
    },
    { 
      name: "Relief Pitcher", 
      abbreviation: "RP", 
      description: "Specialized pitcher who enters the game after the starting pitcher, often with specific roles like setup or closer."
    },
    { 
      name: "Starting Pitcher", 
      abbreviation: "SP", 
      description: "Pitcher who begins the game and typically pitches for the majority of innings before relief pitchers take over."
    },
    { 
      name: "Closer", 
      abbreviation: "CL", 
      description: "Specialized relief pitcher who typically enters the game in the ninth inning to secure a win in close games."
    },
    { 
      name: "Utility Player", 
      abbreviation: "UTIL", 
      description: "A versatile player capable of playing multiple positions, providing flexibility for the team's lineup and defensive alignments."
    },
    { 
      name: "Pinch Hitter", 
      abbreviation: "PH", 
      description: "A substitute batter who enters the game to hit in place of another player, typically in strategic situations."
    },
    { 
      name: "Pinch Runner", 
      abbreviation: "PR", 
      description: "A substitute runner who enters the game to run the bases in place of another player, typically for speed advantages."
    }
  ]
  
  # Create positions
  baseball.create_standard_positions(baseball_positions)
  
  # Assign positions to existing players based on their current_position field
  Player.where.not(current_position: [nil, ""]).find_each do |player|
    # Skip if player's team sport is not baseball
    next unless player.sport == baseball
    
    # Find matching position based on current_position field
    position_name = player.current_position
    position = baseball.positions.find_by("name = ? OR abbreviation = ?", position_name, position_name)
    
    # If no exact match, try to find a partial match
    if position.nil?
      position_name_parts = position_name.split(/[\s\-\/]/)
      position_name_parts.each do |part|
        next if part.length < 2 # Skip very short parts
        position = baseball.positions.find_by("name LIKE ? OR abbreviation LIKE ?", "%#{part}%", "%#{part}%")
        break if position
      end
    end
    
    # If still no match, use a default position
    position ||= baseball.positions.find_by(name: "Utility Player")
    
    # Create role with this position as primary
    if position
      player.roles.find_or_create_by(position: position) do |role|
        role.primary = true
      end
      puts "Assigned #{position.name} to #{player.name}"
    end
  end
  
  puts "Baseball positions seeded successfully!"
else
  puts "Baseball sport not found! Please seed sports first."
end
