module GoalsHelper
  # Renders a goal status badge with icon and text
  # @param goal [Goal] The goal object
  # @param size [Symbol] Size variant (:small, :medium, :large)
  # @return [String] HTML for the status badge
  def goal_status_badge(goal, size: :medium)
    status_config = {
      'not_started' => {
        text: 'Not Started',
        icon: 'fa-solid fa-circle-pause',
        css_class: 'goal-status-badge goal-status-not-started'
      },
      'in_progress' => {
        text: 'In Progress', 
        icon: 'fa-solid fa-circle-play',
        css_class: 'goal-status-badge goal-status-in-progress'
      },
      'completed' => {
        text: 'Completed',
        icon: 'fa-solid fa-circle-check', 
        css_class: 'goal-status-badge goal-status-completed'
      }
    }
    
    config = status_config[goal.status]
    size_class = "goal-status-badge-#{size}"
    
    tag.span class: "#{config[:css_class]} #{size_class}" do
      tag.i(class: "#{config[:icon]} goal-status-icon") + 
      config[:text]
    end
  end

  # Renders a progress bar for a goal
  # @param goal [Goal] The goal object  
  # @param show_percentage [Boolean] Whether to show percentage inside bar
  # @param size [Symbol] Size variant (:small, :medium, :large)
  # @return [String] HTML for the progress bar
  def goal_progress_bar(goal, show_percentage: true, size: :medium)
    size_class = "goal-progress-bar-#{size}"
    
    tag.div class: "goal-progress-container" do
      bar_content = tag.div class: "goal-progress-bar #{size_class}", 
                           style: "width: #{goal.percent_complete}%" do
        if show_percentage && goal.percent_complete > 15
          tag.span "#{goal.percent_complete}%", class: "goal-progress-text"
        end
      end
      
      tag.div(class: "goal-progress-track") { bar_content } +
      if show_percentage && goal.percent_complete <= 15
        tag.div "#{goal.percent_complete}% complete", class: "goal-progress-external-text"
      end
    end
  end

  # Renders goal action buttons
  # @param goal [Goal] The goal object
  # @param layout [Symbol] Layout variant (:horizontal, :vertical)
  # @return [String] HTML for action buttons
  def goal_action_buttons(goal, layout: :horizontal)
    view_quest_button = link_to "View Quest", goal.quest, class: "goal-action-button goal-action-secondary"
    view_goal_button = link_to "View Goal", goal, class: "goal-action-button goal-action-primary"
    if goal.status != 'completed'
      abandon_button = link_to goal_path(goal),
      method: :delete,
      class: "goal-action-button goal-action-danger", 
      confirm: "Are you sure you want to abandon this quest?",
      title: "Abandon Quest",
      id: dom_id(goal, :abandon_button_for) do
        tag.i class: "fa-solid fa-trash"
      end
    end

    tag.div class: "goal-actions goal-actions-#{layout}" do      
      safe_join [view_quest_button, view_goal_button, abandon_button].compact
    end
  end

  # Renders a notice/alert message
  # @param message [String] The message text
  # @param type [Symbol] Message type (:notice, :alert, :error)
  # @return [String] HTML for the message
  def goal_notice(message, type: :notice)
    return "" unless message.present?
    tag.p message.html_safe, class: "goal-notice goal-notice-#{type}", id: "notice"
  end

  # Renders the goal container wrapper
  def goal_container(**options, &block)
    default_options = { class: "goal-container" }
    merged_options = default_options.merge(options)
    
    tag.div **merged_options, &block
  end

  # Renders a complete goals index page structure
  def goals_index_page(title, notice: nil, &block)
    goal_container do
      (goal_notice(notice) +
       goal_page_header(title) do
         link_to "Browse Quests", quests_path, class: "goal-action-button goal-action-primary"
       end +
       tag.div(id: "goals", class: "goals-collection", &block)).html_safe
    end
  end

  # Renders a goals group section for status-based grouping
  def goals_group_section(status, goals, &block)
    tag.div class: "goals-group" do
      tag.h2(class: "goals-group-title") do
        (status.humanize + " Goals " + tag.span("(#{goals.count})", class: "goals-group-count")).html_safe
      end +
      tag.div(class: "goals-group-list", &block)
    end
  end

  # Renders goals collection with status grouping
  def goals_collection_with_grouping(goals)
    if goals.any?
      goals.group_by(&:status).map do |status, grouped_goals|
        goals_group_section status, grouped_goals do
          grouped_goals.map { |goal| render goal }.join.html_safe
        end
      end.join.html_safe
    else
      goals_empty_state
    end
  end

  # Renders empty state for goals
  def goals_empty_state
    tag.div class: "goals-empty-state" do
      (tag.div(class: "goals-empty-icon") do
         tag.i class: "fa-solid fa-target text-6xl"
       end +
       tag.h3("No goals yet", class: "goals-empty-title") +
       tag.p("Start your journey by adopting a quest and setting some goals.", class: "goals-empty-description") +
       link_to("Browse Quests", quests_path, class: "goal-action-button goal-action-primary")).html_safe
    end
  end

  # Renders a complete goal detail page structure
  def goal_detail_page(goal, notice: nil, &block)
    goal_container do
      (goal_notice(notice) +
       goal_page_header(goal.quest.name, subtitle: "Personal Goal Progress") do
         link_to("View Quest", goal.quest, class: "goal-action-button goal-action-primary") +
         link_to("All Goals", goals_path, class: "goal-action-button goal-action-secondary")
       end +
       tag.div(class: "goal-detail-sections", &block)).html_safe
    end
  end

  # Renders goal status section for detail page
  def goal_status_section(goal)
    tag.div class: "goal-detail-card" do
      (tag.div(class: "goal-detail-header") do
         (tag.h2("Goal Status", class: "goal-detail-title") +
          goal_status_badge(goal)).html_safe
       end +
       tag.div(class: "goal-detail-content") do
         tag.div do
           (tag.div(class: "goal-progress-stats") do
              (tag.span("Progress") +
               tag.span("#{goal.progress} / #{goal.quest.highlights.required.count} achievements", 
                       class: "goal-progress-stats-value")).html_safe
            end +
            goal_progress_bar(goal)).html_safe
         end
       end).html_safe
    end
  end

  # Renders quest description section
  def quest_description_section(quest)
    tag.div class: "goal-detail-card" do
      (tag.h2("Quest Description", class: "goal-detail-title") +
       tag.p(quest.description, class: "text-gray-700 leading-relaxed")).html_safe
    end
  end

  # Renders abandon quest section if applicable
  def abandon_quest_section(goal)
    return unless goal.status != 'completed'
    
    tag.div class: "goal-page-actions justify-end" do
      link_to goal_path(goal),
              method: :delete,
              class: "goal-action-button goal-action-danger",
              confirm: "Are you sure you want to abandon this quest? This action cannot be undone.",
              title: "Abandon Quest",
              id: dom_id(goal, :abandon_button_detail) do
(tag.i(class: "fa-solid fa-trash mr-2") + "Abandon Quest").html_safe
      end
    end
  end

  # Renders a goal card wrapper
  # @param goal [Goal] The goal object
  # @param options [Hash] Additional HTML options  
  # @return [String] HTML for goal card
  def goal_card(goal, **options, &block)
    default_options = {
      id: dom_id(goal),
      class: "goal-card"
    }
    merged_options = default_options.merge(options)
    
    tag.div **merged_options, &block
  end

  # Renders page header with title and actions
  # @param title [String] Page title
  # @param subtitle [String] Optional subtitle
  # @return [String] HTML for page header
  def goal_page_header(title, subtitle: nil, &block)
    tag.div class: "goal-page-header" do
      header_content = tag.div(class: "goal-page-header-content") do
        content = tag.h1(title, class: "goal-page-title")
        content += tag.p(subtitle, class: "goal-page-subtitle") if subtitle.present?
        content
      end
      
      if block_given?
        header_content + tag.div(class: "goal-page-actions", &block)
      else
        header_content  
      end
    end
  end

  # Renders achievement item
  # @param highlight [Highlight] The highlight/achievement object
  # @param required [Boolean] Whether this achievement is required
  # @return [String] HTML for achievement item
  def achievement_item(highlight, required: true)
    icon_class = required ? "fa-solid fa-star achievement-icon-required" : 
                           "fa-regular fa-star achievement-icon-optional"
    
    tag.div class: "achievement-item" do
      (tag.div(class: "achievement-icon-container") do
         tag.i class: icon_class
       end +
       tag.div(class: "achievement-content") do
         (tag.h3(highlight.achievement.name, class: "achievement-name") +
          tag.p(highlight.achievement.description, class: "achievement-description")).html_safe
       end).html_safe
    end
  end

  # Renders achievement list section
  # @param highlights [ActiveRecord::Relation] Collection of highlights
  # @param title [String] Section title
  # @param required [Boolean] Whether these are required achievements
  # @return [String] HTML for achievements section
  def achievements_section(highlights, title, required: true)
    tag.div class: "achievements-section" do
      (tag.h2(title, class: "achievements-section-title") +
       if highlights.any?
         tag.div(class: "achievements-list") do
           highlights.includes(:achievement).map do |highlight|
             achievement_item highlight, required: required
           end.join.html_safe
         end
       else
         tag.p("No #{title.downcase} for this quest.", class: "achievements-empty")
       end).html_safe
    end
  end
end