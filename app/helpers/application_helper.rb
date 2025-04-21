module ApplicationHelper
  # Returns the active class for navigation links
  def active_class(link_path)
    current_page?(link_path) ? 'border-indigo-500 text-gray-900' : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'
  end
end
