puts "Seeding football positions..."

# Find football sport
football = Sport.find_by(name: "Football")

if football
  # Define standard football positions
  football_positions = [
    # Offensive Positions
    { 
      name: "Quarterback", 
      abbreviation: "QB", 
      description: "The leader of the offense who receives the snap from the center, calls plays, and either passes the ball, hands it off, or runs with it."
    },
    { 
      name: "Running Back", 
      abbreviation: "RB", 
      description: "Lines up in the backfield and carries the ball on running plays, blocks on passing plays, and sometimes catches passes."
    },
    { 
      name: "Fullback", 
      abbreviation: "FB", 
      description: "A power running back who often serves as a lead blocker for the running back and occasionally carries the ball in short-yardage situations."
    },
    { 
      name: "Wide Receiver", 
      abbreviation: "WR", 
      description: "Lines up on the outside and runs routes to catch passes from the quarterback."
    },
    { 
      name: "Tight End", 
      abbreviation: "TE", 
      description: "A hybrid position that combines elements of an offensive lineman and a receiver, blocking on running plays and running routes on passing plays."
    },
    { 
      name: "Offensive Tackle", 
      abbreviation: "OT", 
      description: "Offensive linemen positioned on the ends of the line who protect the quarterback and create running lanes."
    },
    { 
      name: "Offensive Guard", 
      abbreviation: "OG", 
      description: "Offensive linemen positioned between the center and tackles who block for both passing and running plays."
    },
    { 
      name: "Center", 
      abbreviation: "C", 
      description: "The offensive lineman who snaps the ball to the quarterback and blocks defensive players."
    },
    { 
      name: "Left Tackle", 
      abbreviation: "LT", 
      description: "Offensive tackle on the left side of the line, often protecting the quarterback's blind side for right-handed quarterbacks."
    },
    { 
      name: "Right Tackle", 
      abbreviation: "RT", 
      description: "Offensive tackle on the right side of the line."
    },
    { 
      name: "Left Guard", 
      abbreviation: "LG", 
      description: "Offensive guard positioned between the center and left tackle."
    },
    { 
      name: "Right Guard", 
      abbreviation: "RG", 
      description: "Offensive guard positioned between the center and right tackle."
    },
    { 
      name: "Slot Receiver", 
      abbreviation: "SR", 
      description: "A wide receiver who lines up between the offensive line and an outside receiver."
    },
    
    # Defensive Positions
    { 
      name: "Defensive End", 
      abbreviation: "DE", 
      description: "Defensive linemen positioned at the ends of the line who rush the passer and contain running plays."
    },
    { 
      name: "Defensive Tackle", 
      abbreviation: "DT", 
      description: "Interior defensive linemen who stop running plays and pressure the quarterback up the middle."
    },
    { 
      name: "Nose Tackle", 
      abbreviation: "NT", 
      description: "A defensive tackle who lines up directly across from the center in certain defensive formations."
    },
    { 
      name: "Linebacker", 
      abbreviation: "LB", 
      description: "Second-level defenders who stop running plays, rush the passer, and cover receivers depending on the play."
    },
    { 
      name: "Middle Linebacker", 
      abbreviation: "MLB", 
      description: "The central linebacker who often calls defensive plays and is responsible for covering the middle of the field."
    },
    { 
      name: "Outside Linebacker", 
      abbreviation: "OLB", 
      description: "Linebackers who line up on the outside edges of the defensive formation."
    },
    { 
      name: "Cornerback", 
      abbreviation: "CB", 
      description: "Defensive backs who primarily cover wide receivers and defend against passing plays."
    },
    { 
      name: "Safety", 
      abbreviation: "S", 
      description: "Defensive backs who line up deep in the secondary, providing the last line of defense against both running and passing plays."
    },
    { 
      name: "Free Safety", 
      abbreviation: "FS", 
      description: "A safety who typically has more coverage responsibilities and less run support duties."
    },
    { 
      name: "Strong Safety", 
      abbreviation: "SS", 
      description: "A safety who typically plays closer to the line of scrimmage and has more run support responsibilities."
    },
    { 
      name: "Nickelback", 
      abbreviation: "NB", 
      description: "An extra defensive back who replaces a linebacker in passing situations, often covering slot receivers."
    },
    
    # Special Teams Positions
    { 
      name: "Kicker", 
      abbreviation: "K", 
      description: "Specialist who handles kickoffs and field goal attempts."
    },
    { 
      name: "Punter", 
      abbreviation: "P", 
      description: "Specialist who punts the ball on fourth down to give the opposing team poor field position."
    },
    { 
      name: "Long Snapper", 
      abbreviation: "LS", 
      description: "Specialist who snaps the ball on punts, field goals, and extra points."
    },
    { 
      name: "Kick Returner", 
      abbreviation: "KR", 
      description: "Player who receives and returns kickoffs, typically a fast player with good vision and elusiveness."
    },
    { 
      name: "Punt Returner", 
      abbreviation: "PR", 
      description: "Player who receives and returns punts, typically a fast player with good vision and elusiveness."
    },
    { 
      name: "Gunner", 
      abbreviation: "G", 
      description: "Special teams player who runs downfield on punts and kickoffs to tackle the returner."
    }
  ]
  
  # Create positions
  football.create_standard_positions(football_positions)
  
  # Assign positions to existing players based on their current_position field
  Player.where.not(current_position: [nil, ""]).find_each do |player|
    # Skip if player's team sport is not football
    next unless player.sport == football
    
    # Find matching position based on current_position field
    position_name = player.current_position
    position = football.positions.find_by("name = ? OR abbreviation = ?", position_name, position_name)
    
    # If no exact match, try to find a partial match
    if position.nil?
      position_name_parts = position_name.split(/[\s\-\/]/)
      position_name_parts.each do |part|
        next if part.length < 2 # Skip very short parts
        position = football.positions.find_by("name LIKE ? OR abbreviation LIKE ?", "%#{part}%", "%#{part}%")
        break if position
      end
    end
    
    # If still no match, use a default position based on some common abbreviations
    if position.nil?
      case position_name
      when /QB/i
        position = football.positions.find_by(name: "Quarterback")
      when /RB|HB/i
        position = football.positions.find_by(name: "Running Back")
      when /WR|FL|SE/i
        position = football.positions.find_by(name: "Wide Receiver")
      when /TE/i
        position = football.positions.find_by(name: "Tight End")
      when /OL/i
        position = football.positions.find_by(name: "Offensive Tackle")
      when /DL/i
        position = football.positions.find_by(name: "Defensive End")
      when /LB/i
        position = football.positions.find_by(name: "Linebacker")
      when /DB|CB/i
        position = football.positions.find_by(name: "Cornerback")
      when /S|SAF/i
        position = football.positions.find_by(name: "Safety")
      when /K|PK/i
        position = football.positions.find_by(name: "Kicker")
      when /P/i
        position = football.positions.find_by(name: "Punter")
      else
        position = football.positions.find_by(name: "Wide Receiver") # Default fallback
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
  
  puts "Football positions seeded successfully!"
else
  puts "Football sport not found! Please seed sports first."
end
