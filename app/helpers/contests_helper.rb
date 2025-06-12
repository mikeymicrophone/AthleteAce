module ContestsHelper
  def contest_display_name(contest)
    contest.name.presence || "Contest ##{contest.id}"
  end
  
  def contests_index_page
    tag.div class: "contests-index-page" do
      tag.header(class: "page-header") do
        tag.h1("Contests", class: "page-title")
      end +
      tag.main(class: "contests-grid") do
        @contests.map { |contest| contest_item(contest) }.join.html_safe
      end +
      (pagy_nav(@pagy) if @pagy.pages > 1).to_s.html_safe
    end
  end
  
  def contest_item(contest)
    tag.article class: "contest-item" do
      tag.header(class: "contest-header") do
        link_to(contest, class: "contest-link") do
          tag.h3(contest_display_name(contest), class: "contest-name")
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
        link_to("View Details", contest, class: "btn btn-outline")
      end
    end
  end
  
  def contest_show_page(contest)
    tag.div class: "contest-show-page" do
      tag.div(class: "contest-show-header") do
        link_to("← Back to Contests", contests_path, class: "back-link") +
        tag.h1(contest_display_name(contest), class: "contest-title")
      end +
      tag.div(class: "contest-content") do
        contest_info_section(contest) +
        if contest.begin_date || contest.end_date
          contest_dates_section(contest)
        end.to_s.html_safe +
        if contest.comments.present?
          contest_comments_section(contest)
        end.to_s.html_safe +
        if contest.details.present?
          contest_details_section(contest)
        end.to_s.html_safe
      end
    end
  end
  
  def contest_info_section(contest)
    tag.div class: "contest-info-section" do
      tag.h2("Contest Information", class: "section-title") +
      tag.div(class: "info-grid") do
        if contest.context.present?
          tag.div(class: "info-item") do
            tag.dt("Context") +
            tag.dd(contest.context)
          end
        end.to_s.html_safe +
        if contest.champion_id.present?
          tag.div(class: "info-item") do
            tag.dt("Champion") +
            tag.dd("Champion ID: #{contest.champion_id}")
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
end