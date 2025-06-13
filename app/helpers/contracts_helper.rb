module ContractsHelper
  # Display contract name with player and team info
  def contract_name_display(contract)
    tag.div class: "record-name" do
      player_display = contract.player ? 
        display_name_with_lazy_logo(contract.player, name_attribute: :full_name, logo_attribute: :image_url) : 
        "Unknown Player"
      team_display = contract.team ? 
        display_name_with_lazy_logo(contract.team) : 
        "Unknown Team"
      
      player_display + " - " + team_display
    end
  end
  
  # Display contract metadata (league, sport, dates)
  def contract_metadata_display(contract)
    tag.div class: "record-metadata" do
      content = []
      
      content << link_to_name(contract.team.league)
      content << " | "
      content << display_name_with_lazy_logo(contract.team.sport, logo_attribute: :icon_url)
      
      if contract.start_date || contract.end_date
        content << " | "
        content << contract_date_range_display(contract)
      end
      
      safe_join(content)
    end
  end
  
  # Display contract value tag if available
  def contract_value_display(contract)
    if contract.total_dollar_value.present?
      tag.div number_to_currency(contract.total_dollar_value), class: "record-tag"
    end
  end
  
  # Display contract date range
  def contract_date_range_display(contract)
    start_date = contract.start_date&.strftime("%m/%d/%Y") || "Start TBD"
    end_date = contract.end_date&.strftime("%m/%d/%Y") || "End TBD"
    "#{start_date} - #{end_date}"
  end
  
  # Display contract details if available
  def contract_details_display(contract)
    if contract.details.present?
      tag.div contract.details, class: "record-details"
    end
  end
  
  # Combine all contract info elements
  def contract_info_display(contract)
    content = contract_name_display(contract) +
              contract_metadata_display(contract)
    
    value_display = contract_value_display(contract)
    content += value_display if value_display
    
    details_display = contract_details_display(contract)
    content += details_display if details_display
    
    content
  end
  
  # Display contract statistics
  def contract_stats_display(contract)
    tag.div class: "record-stats" do
      stats_content = []
      
      # Activations count
      activations_count = contract.activations.count
      if activations_count > 0
        stats_content << tag.div(class: "record-stats-count") do
          tag.span pluralize(activations_count, "activation"), class: "record-stats-count-value"
        end
      end
      
      # Campaigns through activations
      campaigns_count = contract.campaigns.distinct.count
      if campaigns_count > 0
        stats_content << tag.div(class: "record-stats-count") do
          tag.span pluralize(campaigns_count, "campaign"), class: "record-stats-count-value"
        end
      end
      
      # Contract duration if dates are available
      if contract.start_date && contract.end_date
        duration_days = (contract.end_date - contract.start_date).to_i
        if duration_days > 0
          stats_content << tag.div(class: "record-stats-detail") do
            "Duration: #{pluralize(duration_days, 'day')}"
          end
        end
      end
      
      # Display empty state if no stats
      if stats_content.empty?
        stats_content << tag.div("No statistics available", class: "record-stats-empty")
      end
      
      safe_join(stats_content)
    end
  end
end