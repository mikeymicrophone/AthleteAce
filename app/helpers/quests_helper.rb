module QuestsHelper
  # Renders a button for an ace to begin a quest
  # If the ace is already on the quest, shows a different button
  def begin_quest_button(quest, options = {})
    return unless ace_signed_in?
    
    existing_goal = current_ace.goals.find_by(quest: quest)
    
    if existing_goal
      link_to quest_path(quest), class: "quest-continue-button #{options[:class]}" do
        content_tag(:span, class: 'quest-button-content') do
          content_tag(:i, nil, class: 'fa-solid fa-check quest-button-icon') + 
          content_tag(:span, 'Continue Quest')
        end
      end
    else
      button_to quest_goals_path(quest), method: :post, class: "quest-begin-button #{options[:class]}" do
        content_tag(:span, class: 'quest-button-content') do
          content_tag(:i, nil, class: 'fa-solid fa-flag quest-button-icon') + 
          content_tag(:span, 'Begin Quest')
        end
      end
    end
  end
  
  # UNUSED
  # Returns the number of aces currently on a quest
  def quest_participants_count(quest)
    quest.goals.count
  end
  
  # Displays the number of participants on a quest with appropriate styling
  def quest_participants_badge(quest)
    count = quest_participants_count(quest)
    content_tag(:span, class: 'quest-participants-badge') do
      content_tag(:i, nil, class: 'fa-solid fa-users quest-participants-icon') + 
      pluralize(count, 'participant')
    end
  end
end
