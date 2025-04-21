module ApplicationHelper
  # Returns the active class for navigation links
  def active_class(link_path)
    current_page?(link_path) ? 'border-indigo-500 text-orange-400' : 'border-transparent text-white hover:border-gray-300 hover:text-orange-200'
  end

  # Shared Tailwind classes for all index records
  def index_record_base_classes
    'flex items-center p-4 mb-2 bg-white rounded shadow hover:bg-orange-50 transition-colors duration-150'
  end

  # Resource-specific example: Teams
  def team_index_record_classes
    'border-l-4 border-orange-400 hover:border-indigo-500'
  end

  def player_index_record_classes
    'border-l-4 border-blue-400 hover:border-indigo-500'
  end

  def league_index_record_classes
    'border-l-4 border-green-400 hover:border-indigo-500'
  end

  def country_index_record_classes
    'border-l-4 border-yellow-400 hover:border-indigo-500'
  end

  def state_index_record_classes
    'border-l-4 border-purple-400 hover:border-indigo-500'
  end

  def city_index_record_classes
    'border-l-4 border-pink-400 hover:border-indigo-500'
  end

  def stadium_index_record_classes
    'border-l-4 border-gray-400 hover:border-indigo-500'
  end

  def sport_index_record_classes
    'border-l-4 border-teal-400 hover:border-indigo-500'
  end
end
