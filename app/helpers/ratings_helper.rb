module RatingsHelper
  # Display ratings count for a record
  def ratings_count_display(record)
    if record.ratings.active.any?
      tag.div class: "record-stats-count" do
        tag.span pluralize(record.ratings.active.count, "rating"), class: "record-stats-count-value"
      end
    end
  end
  
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
    # Prepare data attributes based on the record type
    data_attrs = { controller: "rating-slider" }
    data_attrs[:rating_slider_player_id_value] = record.id.to_s if record.is_a?(Player)
    data_attrs[:rating_slider_team_id_value] = record.id.to_s if record.is_a?(Team)
    
    tag.div(
      id: "rating-slider-group-#{record.class.name.downcase}-#{record.id}", 
      class: "rating-slider-group-container",
      data: data_attrs
    ) do
      # Generate sliders for each selected spectrum
      content = ActiveSupport::SafeBuffer.new
      
      selected_spectrums.each do |spectrum|
        content << build_rating_slider(record, spectrum)
      end
      
      # Add empty state message if no spectrums are selected
      if selected_spectrums.empty?
        content << tag.p("Select a spectrum to see rating sliders.",
          id: "rating-slider-empty-state-#{record.class.name.downcase}-#{record.id}",
          class: "empty-state-message")
      end
      
      content
    end
  end
  
  private
  
  # Build an individual rating slider for a specific spectrum
  # @param record [ActiveRecord::Base] The object being rated
  # @param spectrum [Spectrum] The spectrum to display the slider for
  # @return [ActiveSupport::SafeBuffer] The HTML for a single rating slider
  def build_rating_slider(record, spectrum)
    record_type = record.class.name.downcase
    record_id = record.id
    spectrum_id = spectrum.id
    current_value = record.ratings.active.find_by(spectrum_id: spectrum_id)&.value || 0
    
    tag.div(
      id: "rating-slider-#{record_type}-#{record_id}-spectrum-#{spectrum_id}",
      class: "rating-slider-instance",
      data: { spectrum_id: spectrum_id }
    ) do
      content = ActiveSupport::SafeBuffer.new
      
      # Header with label and current value
      content << tag.div(class: "slider-header") do
        header_content = ActiveSupport::SafeBuffer.new
        header_content << tag.span(spectrum.name.sub(/\s*\(.*\)\s*$/, '').strip, class: "slider-label")
        header_content << tag.span(current_value,
          id: "rating-value-#{record_type}-#{record_id}-spectrum-#{spectrum_id}",
          class: "slider-value",
          data: { rating_slider_target: "value_#{spectrum_id}" })
        header_content
      end
      
      # Slider control with range input
      content << tag.div(class: "slider-control") do
        control_content = ActiveSupport::SafeBuffer.new
        control_content << tag.span(spectrum.low_label, class: "slider-low-label")
        control_content << tag.input(
          type: "range",
          min: -10000,
          max: 10000,
          value: current_value,
          step: 100,
          id: "rating-input-#{record_type}-#{record_id}-spectrum-#{spectrum_id}",
          class: "slider-input",
          data: {
            rating_slider_target: "slider_#{spectrum_id}",
            action: "input->rating-slider#updateValue change->rating-slider#submitRating",
            rating_slider_spectrum_id_param: spectrum_id
          }
        )
        control_content << tag.span(spectrum.high_label, class: "slider-high-label")
        control_content
      end
      
      # Status message area
      content << tag.div(class: "slider-status") do
        tag.span(
          "",
          id: "rating-status-#{record_type}-#{record_id}-spectrum-#{spectrum_id}",
          class: "status-indicator",
          data: { rating_slider_target: "status_#{spectrum_id}" }
        )
      end
      
      content
    end
  end
end
