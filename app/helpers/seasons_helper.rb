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
      tag.header(class: "page-header") do
        tag.h1("Seasons", class: "page-title")
      end +
      tag.main(class: "seasons-grid") do
        @seasons.map { |season| season_item(season) }.join.html_safe
      end +
      (pagy_nav(@pagy) if @pagy.pages > 1).to_s.html_safe
    end
  end
  
  def season_item(season)
    tag.article class: "season-item" do
      tag.header(class: "season-header") do
        link_to(season, class: "season-link") do
          tag.h3(season_full_name(season), class: "season-name")
        end +
        tag.p(season_display_name(season), class: "season-year")
      end +
      tag.div(class: "season-details") do
        tag.div(class: "season-meta") do
          tag.span("League: ", class: "meta-label") +
          tag.span(season.league.name, class: "meta-value")
        end +
        tag.div(class: "season-meta") do
          tag.span("Status: ", class: "meta-label") +
          tag.span(season.status.humanize, class: "meta-value")
        end +
        if season.start_date
          tag.div(class: "season-dates") do
            date_text = "Season: #{season.start_date.strftime('%b %d, %Y')}"
            date_text += " - #{season.end_date.strftime('%b %d, %Y')}" if season.end_date
            date_text
          end
        end.to_s.html_safe
      end +
      tag.footer(class: "season-actions") do
        link_to("View Details", season, class: "btn btn-outline")
      end
    end
  end
  
  def season_show_page(season)
    tag.div class: "season-show-page" do
      tag.div(class: "season-show-header") do
        link_to("← Back to Seasons", seasons_path, class: "back-link") +
        tag.h1(season_full_name(season), class: "season-title") +
        tag.p(season_display_name(season), class: "season-subtitle")
      end +
      tag.div(class: "season-content") do
        season_info_section(season) +
        season_dates_section(season)
      end +
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
      tag.h2("Season Information", class: "section-title") +
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
      tag.h2("Important Dates", class: "section-title") +
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