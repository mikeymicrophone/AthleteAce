module TeamsHelper
  # Generates a link to start a team quiz
  # @param team [Team] The team to generate the quiz link for
  # @param options [Hash] Additional HTML options for the link
  # @return [String] HTML link to start the team quiz
  def team_quiz_link(team, options = {})
    return unless team.present?
    
    default_options = {
      class: 'inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500',
      data: { turbo: false }
    }
    
    # Use the direct path since we don't have a named route for team_match with team_id
    link_to 'Quiz Me', "/strength/team_match?team_id=#{team.id}", 
           default_options.merge(options)
  end
end
