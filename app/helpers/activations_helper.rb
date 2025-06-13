module ActivationsHelper
  # Display activation name with player, team, and campaign info
  def activation_name_display(activation)
    tag.div class: "record-name" do
      player_display = activation.player ? 
        display_name_with_lazy_logo(activation.player, name_attribute: :full_name, logo_attribute: :image_url) : 
        "Unknown Player"
      team_display = activation.team ? 
        display_name_with_lazy_logo(activation.team) : 
        "Unknown Team"
      campaign_display = activation.campaign ? 
        "(#{activation.campaign.team.name} #{activation.campaign.season.name})" : 
        "(Unknown Campaign)"
      
      player_display + " - " + team_display + " " + campaign_display
    end
  end
  
  # Display activation metadata (campaign, league, sport, dates)
  def activation_metadata_display(activation)
    tag.div class: "record-metadata" do
      content = []
      
      content << "#{activation.campaign.team.name} #{activation.campaign.season.name}"
      content << " | "
      content << link_to_name(activation.team.league)
      content << " | "
      content << display_name_with_lazy_logo(activation.team.sport, logo_attribute: :icon_url)
      
      if activation.start_date || activation.end_date
        content << " | "
        content << activation_date_range_display(activation)
      end
      
      safe_join(content)
    end
  end
  
  # Display activation contract reference
  def activation_contract_display(activation)
    tag.div class: "record-tag" do
      link_to "Contract ##{activation.contract.id}", activation.contract, class: "text-blue-600 hover:underline"
    end
  end
  
  # Display activation date range
  def activation_date_range_display(activation)
    start_date = activation.start_date&.strftime("%m/%d/%Y") || "Start TBD"
    end_date = activation.end_date&.strftime("%m/%d/%Y") || "End TBD"
    "#{start_date} - #{end_date}"
  end
  
  # Display activation details if available
  def activation_details_display(activation)
    if activation.details.present?
      tag.div activation.details, class: "record-details"
    end
  end
  
  # Combine all activation info elements
  def activation_info_display(activation)
    content = activation_name_display(activation) +
              activation_metadata_display(activation) +
              activation_contract_display(activation)
    
    details_display = activation_details_display(activation)
    content += details_display if details_display
    
    content
  end
  
  # Display activation statistics
  def activation_stats_display(activation)
    tag.div class: "record-stats" do
      stats_content = []
      
      # Contract value if available
      if activation.contract.total_dollar_value.present?
        stats_content << tag.div(class: "record-stats-count") do
          tag.span "Contract Value: #{number_to_currency(activation.contract.total_dollar_value)}", 
                   class: "record-stats-count-value"
        end
      end
      
      # Campaign season info
      if activation.campaign.respond_to?(:season) && activation.campaign.season
        stats_content << tag.div(class: "record-stats-detail") do
          "Season: #{activation.campaign.season.name}"
        end
      end
      
      # Activation duration if dates are available
      if activation.start_date && activation.end_date
        duration_days = (activation.end_date - activation.start_date).to_i
        if duration_days > 0
          stats_content << tag.div(class: "record-stats-detail") do
            "Duration: #{pluralize(duration_days, 'day')}"
          end
        end
      end
      
      # Player position if available
      if activation.player.respond_to?(:primary_position) && activation.player.primary_position
        stats_content << tag.div(class: "record-stats-detail") do
          "Position: #{activation.player.primary_position.name}"
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