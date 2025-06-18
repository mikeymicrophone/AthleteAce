module DivisionsHelper
  include SortableHelper

  def division_sort_links
    sort_links_for(@divisions, 'divisions')
  end

  def logo_bank_for resource
    bank_items = case resource
    when Division
      [resource.league, resource.conference, resource]
    end

    logo_links = bank_items.map { |item| display_name_with_lazy_logo item }
    tag.div class: "logo-bank #{resource.class.name.underscore}" do
      safe_join logo_links
    end
  end
end