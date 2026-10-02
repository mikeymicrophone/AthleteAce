module SpectrumsHelper
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

  # Set the current selected spectrum IDs in the session.
  # @param spectrum_ids [Array<Integer>] The IDs to set as current selected spectrums
  def set_selected_spectrum_ids(spectrum_ids)
    session[:selected_spectrum_ids] = spectrum_ids.map(&:to_i).reject(&:zero?)
  end

  # Select a single spectrum, e.g. from a ?spectrum_id= link
  def set_current_spectrum_id(spectrum_id)
    set_selected_spectrum_ids([spectrum_id])
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

  # Get a collection of all spectrums for display in the picker.
  # @param limit [Integer] Maximum number of spectrums to return (currently unused but kept for consistency)
  # @return [ActiveRecord::Relation] Collection of spectrums
  def default_spectrums(limit = nil)
    spectrums = Spectrum.all.order(:name)
    limit.present? ? spectrums.limit(limit) : spectrums
  end

  def render_floating_spectrum_picker highlight_color: nil
    selected_ids = selected_spectrum_ids
    tag.div id: "spectrum-picker", class: "spectrum-picker", data: { controller: "spectrum-picker" } do
      form_with url: url_for, method: :get, data: { spectrum_picker_target: "form" } do |form|
        toggle = tag.button type: "button", class: "spectrum-picker-toggle", aria: { expanded: false, controls: "spectrum-picker-panel" },
          data: { spectrum_picker_target: "toggleButton", action: "spectrum-picker#toggleExpand" } do
          tag.span(selected_spectrums.map(&:name).join(", "), data: { spectrum_picker_target: "selectedSummary" }) +
            icon("chevron-down", size: 18, data: { spectrum_picker_target: "toggleIcon" })
        end
        panel = tag.div id: "spectrum-picker-panel", class: "spectrum-picker-panel hidden", data: { spectrum_picker_target: "pickerPanel" } do
          multiple = tag.label class: "spectrum-multiple" do
            check_box_tag(:multiple_spectrums, "1", selected_ids.size > 1,
              data: { spectrum_picker_target: "multiSelectToggle", action: "change->spectrum-picker#handleMultiSelectToggle" }) + "Multiple"
          end
          buttons = tag.div class: "spectrum-buttons" do
            safe_join default_spectrums.map { |spectrum|
              tag.button spectrum.name, type: "button", aria: { pressed: selected_ids.include?(spectrum.id) },
                data: { action: "spectrum-picker#toggleSpectrum", spectrum_picker_target: "spectrumButton", spectrum_id: spectrum.id }
            }
          end
          safe_join [multiple, buttons, tag.p("", role: "status", data: { spectrum_picker_target: "status" })]
        end
        inputs = selected_ids.map { |id| form.hidden_field :spectrum_ids, value: id, name: "spectrum_ids[]", id: nil }
        safe_join [toggle, panel, *inputs]
      end
    end
  end
end
