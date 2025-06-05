module RatingsHelper
  # UNUSED
  # Display ratings count for a record
  def ratings_count_display(record)
    if record.ratings.active.any?
      tag.div class: "record-stats-count" do
        tag.span pluralize(record.ratings.active.count, "rating"), class: "record-stats-count-value"
      end
    end
  end
  
  # UNUSED
  # Display ratings details (top 3 spectrums with percentages)
  def ratings_details_display(record)
    return unless record.ratings.active.any?
    
    content = "".html_safe
    record.ratings.active.group(:spectrum_id).count.first(3).each do |spectrum_id, count|
      spectrum = Spectrum.find(spectrum_id)
      content += tag.div class: "record-stats-detail" do
        "#{spectrum.name}: #{record.normalized_average_rating_on(spectrum)&.*(100)&.round || 'N/A'}%"
      end
    end
    
    content
  end
  
  # UNUSED
  # Display empty ratings message
  def empty_ratings_display
    tag.div "No ratings yet", class: "record-stats-empty"
  end
  
  # Combine all ratings display elements
  def ratings_stats_display(record)
    if record.ratings.active.any?
      ratings_count_display(record) + ratings_details_display(record)
    else
      empty_ratings_display
    end
  end
  
  # Generate a rating slider for a record and selected spectrums
  # @param record [ActiveRecord::Base] The object being rated (player, team, etc.)
  # @param selected_spectrums [Array<Spectrum>] Collection of currently selected spectrums to display sliders for
  # @return [ActiveSupport::SafeBuffer] The HTML for the rating slider
  def rating_slider_container(record, selected_spectrums)
    # Determine the record type from the record class
    record_type = record.class.name.underscore
    
    # Validate this is a ratable model
    unless Rails.application.config.ratable_models_hash[record.class.name]
      raise ArgumentError, "#{record.class.name} is not in the list of ratable models"
    end

    # The outer div simply wraps everything, matches what we see in the teams page
    tag.div class: "rating-container" do
      # If no spectrums selected, just show a message
      if selected_spectrums.empty?
        tag.p "Select a spectrum to see rating sliders.",
             class: "empty-state-message"
      else
        # The main div with the controller that handles the sliders
        # This matches the structure in the screenshot exactly
        tag.div id: "rating-slider-group-#{record_type}-#{record.id}", 
                class: "rating-slider-group-container",
                data: {
                  controller: "rating-slider",
                  'rating-slider-target-type-value': record_type,
                  'rating-slider-target-id-value': record.id,
                  'rating-slider-precision-mode': 'coarse',
                  # Also provide data attributes for backward compatibility
                  'rating-slider-target-type': record_type,
                  'rating-slider-target-id': record.id
                } do
          
          # Generate content for each spectrum
          content = ActiveSupport::SafeBuffer.new
          
          # Build a slider for each selected spectrum
          selected_spectrums.each do |spectrum|
            content << build_spectrum_slider(record, spectrum)
          end
          
          content
        end
      end
    end
  end
  
  private
  
  # Build a slider for a specific spectrum
  # @param record [ActiveRecord::Base] The object being rated
  # @param spectrum [Spectrum] The spectrum to display the slider for
  # @return [ActiveSupport::SafeBuffer] The HTML for a single spectrum slider
  def build_spectrum_slider(record, spectrum)
    record_type = record.class.name.downcase
    record_id = record.id
    spectrum_id = spectrum.id
    current_value = record.ratings.active.find_by(spectrum_id: spectrum_id)&.value || 0
    
    # The individual slider container
    tag.div class: "rating-slider-instance",
            data: { spectrum_id: spectrum_id } do
      
      slider_content = ActiveSupport::SafeBuffer.new
      
      # Header with spectrum name and value display
      slider_content << tag.div(class: "slider-header") do
        header = ActiveSupport::SafeBuffer.new
        header << tag.span(spectrum.name.sub(/\s*\(.*\)\s*$/, '').strip, 
                          class: "slider-label")
        header << tag.span(current_value,
                          class: "slider-value",
                          data: { rating_slider_target: "value_#{spectrum_id}" })
        header
      end
      
      # Slider (without min/max labels)
      slider_content << tag.div(class: "slider-control") do
        slider_row = ActiveSupport::SafeBuffer.new
        slider_row << tag.input(
          type: "range",
          min: -10000,
          max: 10000,
          value: current_value,
          step: 100,
          class: "slider-input",
          data: {
            rating_slider_target: "slider_#{spectrum_id}",
            action: "input->rating-slider#updateValue change->rating-slider#submitRating",
            rating_slider_spectrum_id_param: spectrum_id,
            rating_slider_original_step: 100
          }
        )
        slider_row
      end
      
      # Status message area
      slider_content << tag.div(class: "slider-status") do
        tag.span(
          "",
          class: "status-indicator",
          data: { rating_slider_target: "status_#{spectrum_id}" }
        )
      end
      
      slider_content
    end
  end
end
