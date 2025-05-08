module ApplicationHelper
  include Pagy::Frontend

  # Returns the active class for navigation links
  def active_class(link_path)
    current_page?(link_path) ? 'border-indigo-500 text-orange-400' : 'border-transparent text-white hover:border-gray-300 hover:text-orange-200'
  end

  def link_to_name(record, **options)
    default_options = { class: 'flex' }
    merged_options = default_options.merge(options)
    link_to record.name, record, **merged_options rescue ''
  end

  # Shared Tailwind classes for all index records
  def index_record_base_classes
    'flex items-center justify-between p-4 mb-2 bg-white rounded shadow hover:bg-orange-50 transition-colors duration-150'
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

  def conference_index_record_classes
    'border-l-4 border-red-400 hover:border-indigo-500'
  end

  def division_index_record_classes
    'border-l-4 border-indigo-400 hover:border-indigo-500'
  end

  def membership_index_record_classes
    'border-l-4 border-cyan-400 hover:border-indigo-500'
  end

  # Displays a record's name with a placeholder for a lazy-loaded logo.
  # The Stimulus 'lazy-logo_controller.js' will handle loading the actual image.
  #
  # @param record [ActiveRecord::Base] The record object (e.g., Team, Player).
  # @param name_attribute [Symbol] The attribute on the record for its name (defaults to :name).
  # @param logo_attribute [Symbol] The attribute for the logo URL (defaults to :logo_url).
  # @param options [Hash] Additional HTML options for the container span.
  # @return [ActiveSupport::SafeBuffer] HTML string for the container with name and logo placeholder.
  def display_name_with_lazy_logo(record, name_attribute: :name, logo_attribute: :logo_url, **options)
    return '' unless record

    logo_url_value = record.respond_to?(logo_attribute) ? record.public_send(logo_attribute) : nil
    entity_name = record.respond_to?(name_attribute) ? record.public_send(name_attribute) : "N/A"

    default_options = {
      class: "lazy-logo-container inline-flex items-center", # Added inline-flex and items-center
      data: {
        controller: "lazy-logo",
        lazy_logo_entity_id_value: record.id,
        lazy_logo_entity_type_value: record.class.name.underscore, # Use underscore for consistency if fetching via API later
        lazy_logo_url_value: logo_url_value
      }
    }
    merged_options = default_options.deep_merge(options)

    content_tag(:span, **merged_options) do
      # Placeholder for the image (Stimulus target)
      # Pre-styling for consistent size before image loads to reduce layout shift
      logo_placeholder = content_tag(:span, "", class: "logo-placeholder mr-1 w-5 h-5 inline-block", data: { lazy_logo_target: "image" })
      
      # Name (Stimulus target, though not strictly necessary if only displaying name)
      name_span = content_tag(:span, entity_name, data: { lazy_logo_target: "name" })
      
      logo_placeholder + name_span
    end
  rescue => e
    Rails.logger.error "Error in display_name_with_lazy_logo for record #{record&.id}: #{e.message}"
    entity_name || "Error"
  end
end
