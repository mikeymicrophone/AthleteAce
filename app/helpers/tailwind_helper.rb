module TailwindHelper
  # Helper method to generate filter component classes
  # This helps maintain consistency across filter UI elements
  # and makes it easier to update styles in one place
  
  # UNUSED
  # Filter panel classes
  def filter_panel_classes
    {
      container: "bg-white rounded-lg shadow p-4 mb-6",
      header: "text-lg font-medium text-gray-800 mb-3",
      body: "space-y-4",
      filter_row: "flex flex-wrap items-center gap-2"
    }
  end
  
  # UNUSED
  # Filter breadcrumb classes
  def filter_breadcrumb_classes
    {
      container: "flex items-center flex-wrap gap-2 mb-4",
      item: "flex items-center bg-blue-50 text-blue-600 px-3 py-1 rounded-full text-sm",
      separator: "text-gray-400 mx-1",
      clear_button: "text-gray-500 hover:text-red-500 ml-1",
      current: "font-semibold"
    }
  end
  
  # UNUSED
  # Filter selector classes
  def filter_selector_classes
    {
      container: "relative",
      label: "block text-sm font-medium text-gray-700 mb-1",
      select: "rounded-md border-gray-300 py-2 pl-3 pr-10 text-base focus:border-blue-500 focus:outline-none focus:ring-blue-500 sm:text-sm",
      button_group: "flex space-x-2"
    }
  end
  
  # UNUSED
  # Filter chip classes
  def filter_chip_classes
    {
      container: "inline-flex items-center bg-blue-100 text-blue-800 text-sm px-3 py-1 rounded-full",
      label: "font-medium",
      value: "ml-1",
      remove_button: "ml-1 text-blue-500 hover:text-blue-700"
    }
  end
  
  # UNUSED
  # Navigation link classes
  def nav_link_classes(active = false)
    base = "px-4 py-2 text-sm font-medium rounded-md"
    active ? "#{base} bg-blue-600 text-white" : "#{base} text-gray-700 hover:bg-gray-100"
  end
  
  # UNUSED
  # Card classes
  def card_classes
    {
      container: "bg-white rounded-lg shadow overflow-hidden",
      header: "px-4 py-3 border-b border-gray-200",
      body: "p-4",
      footer: "px-4 py-3 bg-gray-50 border-t border-gray-200"
    }
  end
  
  # UNUSED
  # Button classes by type
  def button_classes(type = :primary, size = :medium)
    base = "inline-flex items-center justify-center font-medium rounded-md"
    
    # Size variations
    size_classes = case size
    when :small
      "px-2.5 py-1.5 text-xs"
    when :medium
      "px-4 py-2 text-sm"
    when :large
      "px-6 py-3 text-base"
    end
    
    # Type variations
    type_classes = case type
    when :primary
      "bg-blue-600 hover:bg-blue-500 text-white"
    when :secondary
      "bg-white hover:bg-gray-50 text-gray-700 border border-gray-300"
    when :success
      "bg-green-600 hover:bg-green-500 text-white"
    when :danger
      "bg-red-600 hover:bg-red-500 text-white"
    when :warning
      "bg-yellow-500 hover:bg-yellow-400 text-white"
    when :info
      "bg-cyan-500 hover:bg-cyan-400 text-white"
    end
    
    "#{base} #{size_classes} #{type_classes}"
  end
  
  # UNUSED
  # Badge classes by type
  def badge_classes(type = :default)
    base = "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
    
    case type
    when :primary
      "#{base} bg-blue-100 text-blue-800"
    when :secondary
      "#{base} bg-gray-100 text-gray-800"
    when :success
      "#{base} bg-green-100 text-green-800"
    when :danger
      "#{base} bg-red-100 text-red-800"
    when :warning
      "#{base} bg-yellow-100 text-yellow-800"
    when :info
      "#{base} bg-cyan-100 text-cyan-800"
    else
      "#{base} bg-gray-100 text-gray-800"
    end
  end
  
  # UNUSED
  # Apply Tailwind utility to an element
  # This helps with extracting common utility patterns
  def tw(utilities)
    utilities.join(' ')
  end
end
