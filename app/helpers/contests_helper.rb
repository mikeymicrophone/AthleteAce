module ContestsHelper
  def contest_display_name(contest)
    contest.name.presence || "Contest ##{contest.id}"
  end
  
  def contests_index_page
    tag.div class: "contests-index-page" do
      browse_header(@catalog_title || "Contests") +
      tag.div(class: "contests-grid") do
        @contests.map { |contest| contest_item(contest) }.join.html_safe
      end +
      browse_empty(@contests, @catalog_title || "Contests").to_s.html_safe +
      (@pagy.series_nav if @pagy.pages > 1).to_s.html_safe
    end
  end
  
  def contest_item(contest)
    tag.article class: "contest-item" do
      tag.header(class: "contest-header") do
        link_to(contest, class: "contest-link") do
          tag.h2(contest_display_name(contest), class: "contest-name")
        end
      end +
      tag.div(class: "contest-details") do
        if contest.description.present?
          tag.div(class: "contest-description") do
            truncate(contest.description, length: 100)
          end
        end.to_s.html_safe +
        if contest.begin_date || contest.end_date
          tag.div(class: "contest-dates") do
            date_text = ""
            if contest.begin_date
              date_text = "From: #{contest.begin_date.strftime('%b %d, %Y')}"
            end
            if contest.end_date
              date_text += " to #{contest.end_date.strftime('%b %d, %Y')}"
            end
            date_text
          end
        end.to_s.html_safe
      end +
      tag.footer(class: "contest-actions") do
        link_to("View Details", contest, class: "tool-button")
      end
    end
  end
  
  def contest_show_page(contest)
    tag.div class: "contest-show-page" do
      browse_header(contest_display_name(contest)) do
        link_to(contest.kind == "game" ? "← Back to Games" : "← Back to Contests", contest.kind == "game" ? games_path : contests_path, class: "tool-button back-link")
      end +
      tag.div(class: "contest-content") do
        contest_info_section(contest) +
        if contest.begin_date || contest.end_date
          contest_dates_section(contest)
        end.to_s.html_safe +
        contest_appearances_section(contest) +
        contest_competition_section(contest) +
        if contest.comments.present?
          contest_comments_section(contest)
        end.to_s.html_safe +
        if contest.details.present?
          contest_details_section(contest)
        end.to_s.html_safe +
        if contest.contestants.any?
          contest_contestants_section(contest)
        end.to_s.html_safe
      end
    end
  end
  
  def contest_competition_section(contest)
    tag.section(class: "round-panel competition-context") do
      if contest.kind == "game"
        tag.h2("Competitions", class: "section-title") +
          safe_join(contest.competition_memberships.includes(:contest).map do |membership|
            tag.div do
              link_to(contest_display_name(membership.contest), contest_path(membership.contest)) +
                tag.p(competition_game_summary(membership))
            end
          end)
      else
        tag.h2("Competition format", class: "section-title") +
          tag.ul do
            safe_join(contest.format_rules.fetch("rounds", []).map do |round|
              tag.li([ round["name"].presence || round["key"].humanize, ("Best of #{round['best_of']}" if round["best_of"]) ].compact.join(" · "))
            end)
          end +
          tag.h2("Games", class: "section-title") +
          safe_join(contest.contest_games.includes(:game).sort_by { |membership| [ membership.game.begin_date || Date.new(1), membership.game_id ] }.map do |membership|
            tag.div do
              link_to(contest_display_name(membership.game), game_path(membership.game)) +
                tag.p(competition_game_summary(membership))
            end
          end) +
          tag.h2("Titles awarded", class: "section-title") +
          safe_join(contest.title_awards.includes(winner: { campaign: :team }).order(:key).map do |award|
            tag.p { tag.strong(award.name) + " · " + link_to_name(award.team) }
          end)
      end
    end
  end

  def competition_game_summary(membership)
    metadata = membership.metadata
    [ metadata["round"]&.humanize, ("Group #{metadata['group']}" if metadata["group"]),
      metadata["series"], ("Game #{metadata['game_number']}" if metadata["game_number"]),
      ("Leg #{metadata['leg']}" if metadata["leg"]) ].compact.join(" · ")
  end

  def contest_info_section(contest)
    tag.div class: "contest-info-section" do
      tag.h2("Contest Information", class: "section-title") +
      tag.div(class: "info-grid") do
        if contest.context.present?
          tag.div(class: "info-item") do
            tag.dt("Context") +
            tag.dd(link_to_name(contest.context))
          end
        end.to_s.html_safe +
        if contest.champion.present?
          tag.div(class: "info-item") do
            tag.dt("Champion") +
            tag.dd(link_to_name(contest.champion))
          end
        end.to_s.html_safe +
        if contest.description.present?
          tag.div(class: "info-item") do
            tag.dt("Description") +
            tag.dd(contest.description)
          end
        end.to_s.html_safe
      end
    end
  end
  
  def contest_dates_section(contest)
    tag.div class: "contest-info-section" do
      tag.h2("Contest Dates", class: "section-title") +
      tag.div(class: "dates-list") do
        dates_content = ""
        
        if contest.begin_date
          dates_content += tag.div(class: "date-item") do
            tag.dt("Start Date") +
            tag.dd(contest.begin_date.strftime('%B %d, %Y'))
          end
        end
        
        if contest.end_date
          dates_content += tag.div(class: "date-item") do
            tag.dt("End Date") +
            tag.dd(contest.end_date.strftime('%B %d, %Y'))
          end
        end
        
        dates_content.html_safe
      end
    end
  end

  def contest_appearances_section(contest)
    appearances = contest.appearances.includes(:player, contestant: { campaign: :team })
    return "".html_safe if appearances.empty?

    tag.section(class: "contest-info-section contest-appearances") do
      tag.h2("Player appearances", class: "section-title") +
      safe_join(appearances.map do |appearance|
        tag.article(class: "appearance-record") do
          tag.h3(link_to_name(appearance.player)) +
          tag.p(appearance.contestant.campaign.name) +
          tag.dl(class: "info-grid") do
            facts = { "Jersey number" => appearance.jersey_number.presence || "Unknown",
              "Starter" => appearance.starter.nil? ? "Unknown" : (appearance.starter ? "Yes" : "No") }
            facts.merge!(appearance.statistics.transform_keys(&:humanize))
            safe_join(facts.map do |label, value|
              tag.div(class: "info-item") { tag.dt(label) + tag.dd(value.nil? ? "Unknown" : value.to_s) }
            end)
          end
        end
      end)
    end
  end
  
  def contest_comments_section(contest)
    tag.div class: "comments-section" do
      tag.h3("Comments", class: "comments-title") +
      tag.div(class: "comments-content") do
        simple_format(contest.comments)
      end
    end
  end
  
  def contest_details_section(contest)
    tag.div class: "details-section" do
      tag.h3("Additional Details", class: "details-title") +
      tag.div(class: "details-content") do
        tag.pre(JSON.pretty_generate(contest.details), class: "details-json")
      end
    end
  end
  
  def contest_contestants_section(contest)
    tag.div class: "contestants-section" do
      tag.h3("Contestants", class: "contestants-title") +
      if contest.final_standings.any?
        contest_standings_table(contest)
      else
        contest_participants_list(contest)
      end
    end
  end
  
  def contest_standings_table(contest)
    tag.table(class: "standings-table") do
      tag.thead do
        tag.tr do
          tag.th("Place") +
          tag.th("Team") +
          tag.th("Wins") +
          tag.th("Losses") +
          tag.th("Record")
        end
      end +
      tag.tbody do
        contest.final_standings.map do |contestant|
          tag.tr(class: contestant_row_class(contestant)) do
            tag.td(contestant.placing || "—") +
            tag.td(contestant.campaign.team.mascot) +
            tag.td(contestant.wins || "—") +
            tag.td(contestant.losses || "—") +
            tag.td(contestant_record(contestant))
          end
        end.join.html_safe
      end
    end
  end
  
  def contest_participants_list(contest)
    tag.ul(class: "participants-list") do
      contest.contestants.includes(campaign: :team).map do |contestant|
        tag.li(contestant.campaign.team.mascot, class: "participant-item")
      end.join.html_safe
    end
  end
  
  def contestant_row_class(contestant)
    case contestant.placing
    when 1
      "winner"
    when 2
      "runner-up"
    else
      "participant"
    end
  end
  
  def contestant_record(contestant)
    if contestant.wins && contestant.losses
      "#{contestant.wins}-#{contestant.losses}"
    else
      "—"
    end
  end
end
