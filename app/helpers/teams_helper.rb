module TeamsHelper
  # Renders a "Quiz Me" link for a specific team
  # @param team [Team] The team to quiz on
  # @param options [Hash] Options to customize the link
  # @option options [String] :class Additional CSS classes for the link
  # @return [String] HTML for the quiz link
  def team_quiz_link(team, options = {})
    default_classes = "team-quiz-link text-sm bg-indigo-100 hover:bg-indigo-200 text-indigo-700 font-medium py-1 px-2 rounded inline-flex items-center"
    css_classes = options[:class] ? "#{default_classes} #{options[:class]}" : default_classes
    
    # Use Rails tag builders as per user preference
    link_to strength_team_match_path(team_id: team.id), class: css_classes do
      # Use the icon helper for consistency
      tag.i(class: "#{icon_for_resource(:quests)} mr-1") +
      "Quiz Me"
    end
  end
end
