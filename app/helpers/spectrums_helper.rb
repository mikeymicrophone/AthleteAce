module SpectrumsHelper
  # Get the current spectrum ID based on params or default to Familiarity
  # @param params [ActionController::Parameters] The request parameters
  # @return [Integer] The ID of the current spectrum
  def current_spectrum_id
    # First try to get from params
    return params[:spectrum_id].to_i if params[:spectrum_id].present?
    
    # Then try to get from session
    return session[:current_spectrum_id].to_i if session[:current_spectrum_id].present?
    
    # Otherwise default to Familiarity spectrum or first available spectrum
    familiarity = Spectrum.find_by(name: 'Familiarity')
    return familiarity.id if familiarity.present?
    
    # If all else fails, get the first spectrum
    Spectrum.first&.id || 1
  end
  
  # Set the current spectrum ID in the session
  # @param spectrum_id [Integer] The ID to set as current
  def set_current_spectrum_id(spectrum_id)
    session[:current_spectrum_id] = spectrum_id.to_i
  end
  
  # Get the current spectrum object
  # @return [Spectrum] The current spectrum
  def current_spectrum
    Spectrum.find_by(id: current_spectrum_id)
  end
  
  # Get a collection of default spectrums for display
  # @param limit [Integer] Maximum number of spectrums to return
  # @return [ActiveRecord::Relation] Collection of spectrums
  def default_spectrums(limit = nil)
    spectrums = Spectrum.all.order(:name)
    limit.present? ? spectrums.limit(limit) : spectrums
  end
end
