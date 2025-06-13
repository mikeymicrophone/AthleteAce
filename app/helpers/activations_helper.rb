module ActivationsHelper
  def activation_name_display(activation)
    tag.div class: "activation-name" do
      content = []
      content << display_name_with_lazy_logo(activation.player, name_attribute: :full_name, logo_attribute: :image_url)
      content << " with "
      content << display_name_with_lazy_logo(activation.team)
      content << " in "
      content << "#{activation.campaign.season.year}"
      safe_join(content)
    end
  end

  def activation_metadata_display(activation)
    tag.div class: "activation-metadata" do
      content = []
      content << link_to_name(activation.campaign.season.league) if activation.campaign.season.league
      content << " | " if activation.campaign.season.league && activation.campaign.season.league.sport
      content << link_to_name(activation.campaign.season.league.sport) if activation.campaign.season.league&.sport
      content << " | " if content.any? && (activation.start_date || activation.end_date)
      content << activation_date_range_display(activation) if activation.start_date || activation.end_date
      safe_join(content)
    end
  end

  def activation_contract_display(activation)
    tag.span class: "activation-contract-tag" do
      link_to "Contract ##{activation.contract.id}", contract_path(activation.contract)
    end
  end

  def activation_date_range_display(activation)
    start_date = activation.start_date&.strftime("%m/%d/%Y") || "Start TBD"
    end_date = activation.end_date&.strftime("%m/%d/%Y") || "End TBD"
    "#{start_date} - #{end_date}"
  end

  def activation_info_display(activation)
    content = activation_name_display(activation) +
              activation_metadata_display(activation)
    
    contract_display = activation_contract_display(activation)
    content += contract_display if contract_display
    
    content
  end

  def activation_stats_display(activation)
    tag.div class: "activation-stats" do
      content = []
      
      if activation.contract.total_dollar_value
        content << tag.span(number_to_currency(activation.contract.total_dollar_value, precision: 0), class: "activation-stat-item")
      end
      
      content << tag.span("Season #{activation.campaign.season.year}", class: "activation-stat-item")
      
      if activation.start_date && activation.end_date
        duration = (activation.end_date - activation.start_date).to_i
        content << tag.span("#{pluralize(duration, 'day')} duration", class: "activation-stat-item")
      end
      
      if activation.player.position
        content << tag.span(activation.player.position.name, class: "activation-stat-item")
      end
      
      safe_join(content, " | ")
    end
  end

  def activation_show_display(activation)
    tag.div class: "activation-show" do
      activation_show_header(activation) +
      activation_show_content(activation) +
      activation_show_actions(activation)
    end
  end

  private

  def activation_show_header(activation)
    tag.div class: "activation-show-header" do
      tag.h1 "Activation ##{activation.id}", class: "activation-show-title"
    end
  end

  def activation_show_content(activation)
    tag.div class: "activation-show-content" do
      activation_basic_info_section(activation) +
      activation_context_section(activation) +
      activation_details_section(activation)
    end
  end

  def activation_basic_info_section(activation)
    tag.div class: "activation-basic-info" do
      tag.h2("Activation Information", class: "activation-section-title") +
      tag.div(class: "activation-info-grid") do
        content = []
        content << activation_info_item("Contract", link_to("Contract ##{activation.contract.id}", contract_path(activation.contract)))
        content << activation_info_item("Player", link_to(activation.player.name, player_path(activation.player)))
        content << activation_info_item("Team", link_to(activation.team.name, team_path(activation.team)))
        content << activation_info_item("Campaign", link_to("#{activation.campaign.team.name} - #{activation.campaign.season.year}", campaign_path(activation.campaign)))
        content << activation_info_item("Start Date", activation.start_date&.strftime("%B %d, %Y") || "Not specified")
        content << activation_info_item("End Date", activation.end_date&.strftime("%B %d, %Y") || "Not specified")
        safe_join(content)
      end
    end
  end

  def activation_context_section(activation)
    tag.div class: "activation-context" do
      tag.h2("Context Information", class: "activation-section-title") +
      tag.div(class: "activation-context-grid") do
        content = []
        content << activation_info_item("Season", link_to(activation.campaign.season.year, season_path(activation.campaign.season)))
        content << activation_info_item("League", link_to(activation.campaign.season.league.name, league_path(activation.campaign.season.league)))
        content << activation_info_item("Sport", link_to(activation.campaign.season.league.sport.name, sport_path(activation.campaign.season.league.sport)))
        
        if activation.contract.total_dollar_value
          content << activation_info_item("Contract Value", number_to_currency(activation.contract.total_dollar_value, precision: 0))
        end
        
        safe_join(content)
      end
    end
  end

  def activation_details_section(activation)
    return "".html_safe unless activation.details.present?
    
    tag.div class: "activation-details-section" do
      tag.h2("Additional Details", class: "activation-section-title") +
      tag.div(class: "activation-details-content") do
        tag.pre JSON.pretty_generate(activation.details), class: "activation-details-json"
      end
    end
  end

  def activation_show_actions(activation)
    tag.div class: "activation-show-actions" do
      link_to "Back to Activations", activations_path, class: "activation-back-link"
    end
  end

  def activation_info_item(label, value)
    tag.div class: "activation-info-item" do
      tag.span(label + ":", class: "activation-info-label") +
      tag.span(value, class: "activation-info-value")
    end
  end
end