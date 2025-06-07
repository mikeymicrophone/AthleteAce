module SpectrumsHelper
  # UNUSED
  # Get the current selected spectrum IDs based on params, session, or default to Familiarity.
  # @param params [ActionController::Parameters] The request parameters
  # @return [Array<Integer>] The IDs of the current selected spectrums
  def selected_spectrum_ids
    ids_from_params = params[:spectrum_ids].is_a?(Array) ? params[:spectrum_ids].map(&:to_i).reject(&:zero?) : []
    ids_from_session = session[:selected_spectrum_ids].is_a?(Array) ? session[:selected_spectrum_ids].map(&:to_i).reject(&:zero?) : []

    selected_ids = ids_from_params.presence || ids_from_session.presence

    if selected_ids.present?
      # Ensure selected IDs are valid spectrum IDs
      Spectrum.where(id: selected_ids).pluck(:id)
    else
      # Default to Familiarity spectrum or first available spectrum
      familiarity = Spectrum.find_by(name: 'Familiarity')
      default_id = familiarity&.id || Spectrum.first&.id
      default_id ? [default_id] : []
    end
  end

  # UNUSED
  # Set the current selected spectrum IDs in the session.
  # @param spectrum_ids [Array<Integer>] The IDs to set as current selected spectrums
  def set_selected_spectrum_ids(spectrum_ids)
    session[:selected_spectrum_ids] = spectrum_ids.map(&:to_i).reject(&:zero?)
  end

  # Get the current selected spectrum objects.
  # @return [ActiveRecord::Relation<Spectrum>] The current selected spectrums
  def selected_spectrums
    ids = selected_spectrum_ids
    result = Spectrum.where(id: ids).order(:name)
    
    # If no spectrums are selected, return the first available spectrum for debugging
    if result.empty? && Spectrum.exists?
      Rails.logger.debug "[SpectrumsHelper] No spectrums selected, returning first spectrum"
      Spectrum.limit(1)
    else
      result
    end
  end

  # UNUSED
  # Get a collection of all spectrums for display in the picker.
  # @param limit [Integer] Maximum number of spectrums to return (currently unused but kept for consistency)
  # @return [ActiveRecord::Relation] Collection of spectrums
  def default_spectrums(limit = nil)
    spectrums = Spectrum.all.order(:name)
    limit.present? ? spectrums.limit(limit) : spectrums
  end

  # UNUSED
  # Generates options for the spectrum select tag.
  # Displays spectrum name without low/high labels.
  # Example: "Familiarity" instead of "Familiarity (Low - High)"
  # @return [Array<Array<String, Integer>>] An array of [display_name, id] pairs for options_for_select
  def spectrum_picker_options
    default_spectrums.map do |spectrum|
      # Assuming spectrum.name format is "Name (Low Label - High Label)"
      # or just "Name" if no parenthetical part exists.
      picker_name = spectrum.name.sub(/\s*\(.*\)\s*$/, '').strip
      [picker_name, spectrum.id]
    end
  end

  # Renders the floating spectrum picker component
  def render_floating_spectrum_picker(highlight_color: 'bg-blue-600')
    content_tag(:div, id: "spectrum-picker", class: "sticky top-4 right-4 z-50 bg-white p-3 rounded-lg shadow-xl border border-gray-200 w-64 sm:w-72 md:w-80", data: { controller: "spectrum-picker", spectrum_picker_highlight_color_value: highlight_color }) do
      form_with url: url_for, method: :get, local: true, data: { spectrum_picker_target: "form" } do |form|
        # Collapsed View / Toggle Button
        collapsed_view = content_tag(:div, class: "flex justify-between items-center cursor-pointer", data: { action: "click->spectrum-picker#toggleExpand" }) do
          summary_text = selected_spectrums.any? ? selected_spectrums.map { |s| s.name.sub(/\s*\(.*\)\s*$/, '').strip }.join(', ') : "None"
          summary_span = content_tag(:span, summary_text, class: "text-sm font-medium text-gray-700 truncate pr-2", data: { spectrum_picker_target: "summaryDisplay" })
          toggle_icon_svg = tag.svg(class: "w-5 h-5 text-gray-500 transform transition-transform duration-150", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg", data: { spectrum_picker_target: "toggleIcon" }) do
            tag.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M19 9l-7 7-7-7")
          end
          summary_span + toggle_icon_svg
        end

        # Expandable Content
        expandable_content = content_tag(:div, class: "hidden mt-3 pt-3 border-t border-gray-200", data: { spectrum_picker_target: "expandableContent" }) do
          # Multi-select Toggle
          multi_select_div = content_tag(:div, class: "mb-3") do
            label_tag(nil, class: "flex items-center text-sm text-gray-700 cursor-pointer") do
              check_box_tag(nil, nil, 
                            selected_spectrum_ids.count > 1 || (selected_spectrum_ids.empty? && default_spectrums.count > 1 && default_spectrums.any?),
                            class: "form-checkbox h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500", 
                            data: { spectrum_picker_target: "multiSelectToggle", action: "change->spectrum-picker#handleMultiSelectToggle" }) +
              content_tag(:span, "Multiple", class: "ml-2")
            end
          end

          # Spectrum Buttons
          buttons_div = content_tag(:div, class: "flex flex-wrap gap-2 mb-3", data: { spectrum_picker_target: "buttonContainer" }) do
            # Hidden input to ensure spectrum_ids[] is submitted even if none selected
            hidden_input = form.hidden_field :spectrum_ids, value: '', name: 'spectrum_ids[]', id: nil
            # Initial inputs for selected spectrums
            initial_inputs = selected_spectrum_ids.map { |id| form.hidden_field(:spectrum_ids, value: id, name: 'spectrum_ids[]') }.join.html_safe
            buttons = default_spectrums.map do |spectrum|
              selected = selected_spectrum_ids.include?(spectrum.id)
              btn_classes = ["px-2 py-1 rounded cursor-pointer", (selected ? highlight_color : "bg-gray-200 text-gray-700")].join(' ')
              button_tag spectrum.name.sub(/\s*\(.*\)\s*$/, '').strip,
                type: 'button',
                class: btn_classes,
                data: { action: "click->spectrum-picker#toggleSpectrum", spectrum_picker_target: "spectrumButton", spectrum_id: spectrum.id }
            end.join.html_safe
            hidden_input + initial_inputs + buttons
          end
          
          # Apply Button
          apply_button_div = content_tag(:div) do
            form.submit "Apply Filters", class: "w-full px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2", data: { action: "click->spectrum-picker#submitForm" }
          end

          multi_select_div + buttons_div + apply_button_div
        end
        
        collapsed_view + expandable_content
      end
    end
  end
end
