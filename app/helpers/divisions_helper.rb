module DivisionsHelper
  include SortableHelper

  def division_sort_links
    sort_links_for(@divisions, 'divisions')
  end
end