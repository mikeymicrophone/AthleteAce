module ContractsHelper
  def contract_name_display(contract)
    tag.div class: "contract-name" do
      display_name_with_lazy_logo(contract.player, name_attribute: :full_name, logo_attribute: :image_url) +
      " with ".html_safe +
      display_name_with_lazy_logo(contract.team)
    end
  end

  def contract_metadata_display(contract)
    tag.div class: "contract-metadata" do
      link_to_name(contract.team.league) +
      link_to_name(contract.team.league.sport) +
      contract_date_range_display(contract)
    end
  end

  def contract_value_display(contract)
    return "" unless contract.total_dollar_value.present?
    
    tag.span class: "contract-value-tag" do
      number_to_currency(contract.total_dollar_value, precision: 0)
    end
  end

  def contract_date_range_display(contract)
    start_date = contract.start_date&.strftime("%m/%d/%Y") || "Start TBD"
    end_date = contract.end_date&.strftime("%m/%d/%Y") || "End TBD"
    "#{start_date} - #{end_date}"
  end

  def contract_info_display(contract)
    contract_name_display(contract) +
    contract_metadata_display(contract) +
    contract_value_display(contract)
  end

  def contract_stats_display(contract)
    tag.div class: "contract-stats" do
      tag.span("#{pluralize(contract.activations.count, 'activation')}", class: "contract-stat-item") +
      tag.span("#{pluralize(contract.duration, 'day')} duration", class: "contract-stat-item")
    end
  end

  def contract_show_display(contract)
    tag.div class: "contract-show" do
      contract_show_header(contract) +
      contract_show_content(contract) +
      contract_show_actions(contract)
    end
  end

  def contract_show_header(contract)
    tag.div class: "contract-show-header" do
      tag.h1 "Contract ##{contract.id}", class: "contract-show-title"
    end
  end

  def contract_show_content(contract)
    tag.div class: "contract-show-content" do
      contract_basic_info_section(contract) +
      contract_activations_section(contract) +
      contract_details_section(contract)
    end
  end

  def contract_basic_info_section(contract)
    tag.div class: "contract-basic-info" do
      tag.h2("Contract Information", class: "contract-section-title") +
      tag.div(class: "contract-info-grid") do
        contract_info_item("Player", link_to(contract.player.name, player_path(contract.player))) +
        contract_info_item("Team", link_to(contract.team.name, team_path(contract.team))) +
        contract_info_item("Start Date", contract.start_date&.strftime("%B %d, %Y") || "Not specified") +
        contract_info_item("End Date", contract.end_date&.strftime("%B %d, %Y") || "Not specified") +
        contract_dollar_value(contract)
      end
    end
  end

  def contract_dollar_value contract
    if contract.total_dollar_value
      contract_info_item("Total Value", number_to_currency(contract.total_dollar_value, precision: 0))
    else
      contract_info_item("Total Value", "Not specified")
    end
  end

  def contract_activations_section(contract)
    tag.div class: "contract-activations" do
      tag.h2("Activations", class: "contract-section-title") +
      if contract.activations.any?
        tag.div(class: "contract-activations-list") do
          safe_join(contract.activations.includes(:campaign).map do |activation|
            tag.div(class: "contract-activation-item") do
              link_to(activation_path(activation), class: "contract-activation-link") do
                "Campaign: #{activation.campaign.team.name} - #{activation.campaign.season.year}"
              end +
              if activation.start_date || activation.end_date
                tag.div(class: "contract-activation-dates") do
                  "#{activation.start_date&.strftime('%m/%d/%Y') || '?'} - #{activation.end_date&.strftime('%m/%d/%Y') || '?'}"
                end
              else
                "".html_safe
              end
            end
          end)
        end
      else
        tag.p("No activations for this contract.", class: "contract-no-activations")
      end
    end
  end

  def contract_details_section(contract)
    return "".html_safe unless contract.details.present?
    
    tag.div class: "contract-details-section" do
      tag.h2("Additional Details", class: "contract-section-title") +
      tag.div(class: "contract-details-content") do
        tag.pre JSON.pretty_generate(contract.details), class: "contract-details-json"
      end
    end
  end

  def contract_show_actions(contract)
    tag.div class: "contract-show-actions" do
      link_to "Back to Contracts", contracts_path, class: "contract-back-link"
    end
  end

  def contract_info_item(label, value)
    tag.div class: "contract-info-item" do
      tag.span(label + ":", class: "contract-info-label") +
      tag.span(value, class: "contract-info-value")
    end
  end
end