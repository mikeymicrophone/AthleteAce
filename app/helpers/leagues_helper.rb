module LeaguesHelper
  include SortableHelper

  def league_sort_links
    sort_links_for(@leagues, 'leagues')
  end
end
