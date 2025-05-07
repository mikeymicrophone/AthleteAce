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

  # Get the current selected spectrum objects.
  # @return [ActiveRecord::Relation<Spectrum>] The current selected spectrums
  def selected_spectrums
    ids = selected_spectrum_ids
    Spectrum.where(id: ids).order(:name)
  end

  # Get a collection of all spectrums for display in the picker.
  # @param limit [Integer] Maximum number of spectrums to return (currently unused but kept for consistency)
  # @return [ActiveRecord::Relation] Collection of spectrums
  def default_spectrums(limit = nil)
    spectrums = Spectrum.all.order(:name)
    limit.present? ? spectrums.limit(limit) : spectrums
  end

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
end
