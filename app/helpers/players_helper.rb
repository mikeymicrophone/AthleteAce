module PlayersHelper
  def sorting_scopes_for(players)
    tag.div class: "flex justify-end" do
      tag.div class: "flex space-x-2" do
        tag.a("First Name", href: players_path(sort: "first_name")) +
        tag.a("Last Name", href: players_path(sort: "last_name")) +
        tag.a("Team", href: players_path(sort: "team_id")) +
        tag.a("League", href: players_path(sort: "league_id")) +
        tag.a("Sport", href: players_path(sort: "sport_id"))
      end
    end
  end
end
