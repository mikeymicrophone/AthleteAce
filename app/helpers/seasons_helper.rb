module SeasonsHelper
  def season_display_name(season)
    case season.league.sport.name.downcase
    when 'baseball'
      # MLB uses single year for season name
      season.year.number.to_s
    when 'basketball'
      # NBA uses hyphenated format like "2023-24"
      "#{season.year.number}-#{(season.year.number + 1).to_s.last(2)}"
    when 'football'
      # NFL uses single year
      season.year.number.to_s
    when 'hockey'
      # NHL uses hyphenated format like "2023-24"
      "#{season.year.number}-#{(season.year.number + 1).to_s.last(2)}"
    when 'soccer'
      # MLS uses single year
      season.year.number.to_s
    else
      # Default to single year
      season.year.number.to_s
    end
  end
  
  def season_full_name(season)
    "#{season_display_name(season)} #{season.league.name}"
  end
  
  def seasons_index_page
    tag.div class: "seasons-index-page" do
      tag.header(class: "seasons-hero") do
        tag.p("Calendar of competition", class: "seasons-eyebrow") +
        tag.h1("Seasons", class: "seasons-page-title") +
        tag.p("Browse every year by league, with the year front and center and the competition highlighted at a glance.", class: "seasons-intro")
      end +
      tag.main(class: "seasons-grid") do
        @seasons.map { |season| season_item(season) }.join.html_safe
      end +
      (pagy_nav(@pagy) if @pagy.pages > 1).to_s.html_safe
    end
  end
  
  def season_item(season)
    tag.article class: "season-item" do
      link_to(season, class: "season-link") do
        tag.div(class: "season-card-topline") do
          tag.span(season.league.name, class: "season-league-badge") +
          tag.span(season.status.humanize, class: "season-status-badge")
        end +
        tag.div(class: "season-primary") do
          tag.p(season.year.number.to_s, class: "season-year") +
          tag.p(season_display_name(season), class: "season-format")
        end +
        tag.div(class: "season-details") do
          season_champion_badge(season) +
          tag.p(season.league.sport.name, class: "season-sport") +
          season_date_range(season)
        end +
        tag.footer(class: "season-actions") do
          tag.span("View season", class: "season-cta")
        end
      end
    end
  end

  def season_date_range(season)
    return "".html_safe unless season.start_date

    date_text = season.start_date.strftime("%b %d, %Y")
    date_text += " - #{season.end_date.strftime('%b %d, %Y')}" if season.end_date

    tag.p(date_text, class: "season-dates")
  end

  def season_champion_badge(season)
    champion = season_champion_for(season)
    return "".html_safe unless champion

    tag.div(class: "season-champion-bank") do
      tag.span("Champion", class: "season-champion-label") +
      link_to(champion, class: "season-champion-link") do
        display_name_with_lazy_logo(champion, link: false)
      end
    end
  end

  def season_champion_for(season)
    return season.champion if season.champion.present?

    contests = season.contests.select { |contest| contest.champion.present? }
    return nil if contests.empty?

    preferred_contest =
      contests.find { |contest| contest.context_type == "League" } ||
      contests.find { |contest| contest.context_type == "Conference" } ||
      contests.find { |contest| contest.name.to_s.match?(/final|championship|cup|super bowl|world series/i) } ||
      contests.first

    preferred_contest&.champion
  end
  
  def season_show_page(season)
    tag.div class: "season-show-page" do
      tag.div(class: "season-show-header") do
        link_to("← Back to Seasons", seasons_path, class: "season-back-link") +
        tag.h1(season_full_name(season), class: "season-title") +
        tag.p(season_display_name(season), class: "season-subtitle")
      end +
      tag.div(class: "season-content") do
        season_info_section(season) +
        season_dates_section(season)
      end +
      season_link_banks_section(season) +
      if season.comments.any?
        season_comments_section(season)
      end.to_s.html_safe +
      if season.seed_version.present?
        season_seed_info_section(season)
      end.to_s.html_safe
    end
  end
  
  def season_info_section(season)
    tag.div class: "season-info-section" do
      tag.h2("Season Information", class: "season-section-title") +
      tag.div(class: "info-grid") do
        tag.div(class: "info-item") do
          tag.dt("League") +
          tag.dd(season.league.name)
        end +
        tag.div(class: "info-item") do
          tag.dt("Year") +
          tag.dd(season.year.number.to_s)
        end +
        tag.div(class: "info-item") do
          tag.dt("Status") +
          tag.dd(season.status.humanize)
        end +
        if season.season_duration
          tag.div(class: "info-item secondary") do
            tag.dt("Season Duration") +
            tag.dd("#{season.season_duration} days")
          end
        end.to_s.html_safe
      end
    end
  end
  
  def season_dates_section(season)
    tag.div class: "season-info-section" do
      tag.h2("Important Dates", class: "season-section-title") +
      tag.div(class: "dates-list") do
        dates_content = ""
        
        if season.start_date
          dates_content += tag.div(class: "date-item") do
            tag.dt("Season Start") +
            tag.dd(season.start_date.strftime('%B %d, %Y'))
          end
        end
        
        if season.end_date
          dates_content += tag.div(class: "date-item") do
            tag.dt("Season End") +
            tag.dd(season.end_date.strftime('%B %d, %Y'))
          end
        end
        
        if season.playoff_start_date
          dates_content += tag.div(class: "date-item") do
            tag.dt("Playoffs Start") +
            tag.dd(season.playoff_start_date.strftime('%B %d, %Y'))
          end
        end
        
        if season.playoff_end_date
          dates_content += tag.div(class: "date-item") do
            tag.dt("Playoffs End") +
            tag.dd(season.playoff_end_date.strftime('%B %d, %Y'))
          end
        end
        
        dates_content.html_safe
      end
    end
  end

  def season_link_banks_section(season)
    ordered_campaigns = season.campaigns.sort_by { |campaign| campaign.team.name }
    ordered_teams = ordered_campaigns.map(&:team)

    tag.section class: "season-link-banks" do
      season_team_bank(ordered_teams) +
      season_campaign_bank(ordered_campaigns)
    end
  end

  def season_team_bank(teams)
    tag.div class: "season-link-bank" do
      tag.div(class: "season-link-bank-header") do
        tag.h2("Teams In This Season", class: "season-section-title") +
        tag.p(pluralize(teams.size, "team"), class: "season-link-bank-count")
      end +
      if teams.any?
        tag.div(class: "season-link-bank-grid") do
          teams.map do |team|
            link_to(team, class: "season-team-link-card") do
              display_name_with_lazy_logo(team, link: false)
            end
          end.join.html_safe
        end
      else
        tag.p("No teams linked to this season yet.", class: "season-link-bank-empty")
      end
    end
  end

  def season_campaign_bank(campaigns)
    tag.div class: "season-link-bank" do
      tag.div(class: "season-link-bank-header") do
        tag.h2("Campaigns In This Season", class: "season-section-title") +
        tag.p(pluralize(campaigns.size, "campaign"), class: "season-link-bank-count")
      end +
      if campaigns.any?
        tag.div(class: "season-link-bank-grid") do
          campaigns.map do |campaign|
            link_to(campaign, class: "season-campaign-link-card") do
              tag.span(campaign.team.name, class: "season-campaign-name") +
              tag.span("Campaign", class: "season-campaign-label")
            end
          end.join.html_safe
        end
      else
        tag.p("No campaigns linked to this season yet.", class: "season-link-bank-empty")
      end
    end
  end

  def season_comments_section(season)
    tag.div class: "comments-section" do
      tag.h3("Comments", class: "comments-title") +
      tag.ul(class: "comments-list") do
        season.comments.map do |comment|
          tag.li(comment, class: "comment-item")
        end.join.html_safe
      end
    end
  end
  
  def season_seed_info_section(season)
    tag.div class: "seed-info-section" do
      tag.h3("Seed Information", class: "seed-info-title") +
      tag.div(class: "seed-info-grid") do
        tag.div(class: "seed-info-item") do
          tag.dt("Seed Version") +
          tag.dd(season.seed_version)
        end +
        if season.last_seeded_at
          tag.div(class: "seed-info-item") do
            tag.dt("Last Seeded") +
            tag.dd(time_ago_in_words(season.last_seeded_at) + " ago")
          end
        end.to_s.html_safe
      end
    end
  end
end
