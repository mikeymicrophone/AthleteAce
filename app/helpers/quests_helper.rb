module QuestsHelper
  def quest_goal quest
    return unless current_ace
    return @quest_goals[quest.id] if @quest_goals

    current_ace.goals.find_by quest: quest
  end

  def quest_progress goal
    required = goal.quest.highlights.public_requirements.count(&:required?)
    completed = [goal.progress, required].min
    { completed: completed, required: required, percent: required.positive? ? (completed.fdiv(required) * 100).round : 0 }
  end

  def quest_practice_path(achievement, goal: nil)
    return unless achievement.practice_scope && achievement.target

    goal ||= quest_goal(@quest) if @quest
    entry = goal&.goal_achievements&.find_by(achievement: achievement)
    new_game_round_path(entry ? entry.practice_scope : achievement.practice_scope)
  end

  # Renders a button for an ace to begin a quest
  # If the ace is already on the quest, shows a different button
  def begin_quest_button(quest, options = {})
    return unless ace_signed_in? && quest.approved?

    existing_goal = quest_goal quest

    if existing_goal
      link_to goal_path(existing_goal), class: "tool-button quest-continue-button #{options[:class]}" do
        content_tag(:span, class: 'quest-button-content') do
          icon("check", size: 18, class: "quest-button-icon") +
          content_tag(:span, 'Continue Quest')
        end
      end
    else
      button_to quest_goals_path(quest), method: :post, class: "game-button quest-begin-button #{options[:class]}" do
        content_tag(:span, class: 'quest-button-content') do
          icon("flag", size: 18, class: "quest-button-icon") +
          content_tag(:span, 'Begin Quest')
        end
      end
    end
  end

  # UNUSED
  # Returns the number of aces currently on a quest
  def quest_participants_count(quest)
    @quest_participant_counts ? @quest_participant_counts.fetch(quest.id, 0) : quest.goals.distinct.count(:ace_id)
  end

  # Displays the number of participants on a quest with appropriate styling
  def quest_participants_badge(quest)
    count = quest_participants_count(quest)
    content_tag(:span, class: 'quest-participants-badge') do
      icon("users", size: 18, class: "quest-participants-icon") +
      pluralize(count, 'participant')
    end
  end
end
