module QuestsHelper
  # Renders a button for an ace to begin a quest
  # If the ace is already on the quest, shows a different button
  def begin_quest_button(quest, options = {})
    return unless ace_signed_in?
    
    existing_goal = current_ace.goals.find_by(quest: quest)
    
    if existing_goal
      link_to quest_path(quest), class: "rounded-md px-3.5 py-2 bg-green-600 hover:bg-green-500 text-white font-medium #{options[:class]}" do
        content_tag(:span, class: 'flex items-center') do
          content_tag(:i, nil, class: 'fa-solid fa-check mr-2') + 
          content_tag(:span, 'Continue Quest')
        end
      end
    else
      button_to quest_goals_path(quest), method: :post, class: "rounded-md px-3.5 py-2 bg-blue-600 hover:bg-blue-500 text-white font-medium #{options[:class]}" do
        content_tag(:span, class: 'flex items-center') do
          content_tag(:i, nil, class: 'fa-solid fa-flag mr-2') + 
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
    content_tag(:span, class: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800') do
      content_tag(:i, nil, class: 'fa-solid fa-users mr-1') + 
      pluralize(count, 'participant')
    end
  end
end
