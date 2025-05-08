module IconHelper
  # Returns the appropriate Font Awesome icon class for a given resource
  def icon_for_resource(resource_name)
    icon_mappings = {
      # Entities
      sports: "fa-solid fa-basketball",
      leagues: "fa-solid fa-trophy",
      conferences: "fa-solid fa-sitemap",
      divisions: "fa-solid fa-diagram-project",
      teams: "fa-solid fa-users-line",
      players: "fa-solid fa-person-running",
      stadiums: "fa-solid fa-landmark",
      
      # Locations
      countries: "fa-solid fa-earth-americas",
      states: "fa-solid fa-map",
      cities: "fa-solid fa-city",
      
      # Quests & Ratings
      quests: "fa-solid fa-scroll",
      goals: "fa-solid fa-bullseye",
      highlights: "fa-solid fa-star",
      achievements: "fa-solid fa-medal",
      strength: "fa-solid fa-dumbbell",
      ratings: "fa-solid fa-ranking-star",
      spectrums: "fa-solid fa-gauge-high",
      memberships: "fa-solid fa-id-card"
    }
    
    icon_mappings[resource_name.to_sym] || "fa-solid fa-circle-info"
  end
end
