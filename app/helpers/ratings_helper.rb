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
  
  def rating_rows_id record
    dom_id record, :rating_rows
  end

  def rating_row_id record, spectrum
    dom_id record, "rating_spectrum_#{spectrum.id}"
  end

  def signed_rating value
    value.nil? ? "Not rated" : "#{value.positive? ? '+' : ''}#{number_with_delimiter(value.round)}"
  end

  def rating_slider_container record, spectrums
    return unless record.is_ratable?

    tag.div class: "rating-container" do
      tag.div id: dom_id(record, :rating_slider_group), class: "rating-slider-group-container", data: {
        controller: "rating-slider", rating_slider_precision_value: "coarse",
        rating_spectrum_url: polymorphic_path([record, :ratings], action: :for_spectrums)
      } do
        controls = tag.div class: "rating-toolbar" do
          tag.span("You · Aces average", class: "rating-legend-heading") +
            tag.div(class: "precision-control", role: "group", aria: { label: "Rating precision" }) do
              safe_join %w[Coarse Fine].map { |label|
                tag.button label, type: "button", aria: { pressed: label == "Coarse" },
                  data: { rating_slider_target: "precisionButton", action: "rating-slider#changePrecision", precision: label.downcase }
              }
            end
        end
        sign_in = unless ace_signed_in?
          tag.p(class: "rating-sign-in") { link_to("Sign in", new_ace_session_path) + " to add your rating." }
        end
        safe_join [controls, sign_in, tag.div(id: rating_rows_id(record)) {
          render "ratings/slider_rows", record: record, spectrums: spectrums
        }].compact
      end
    end
  end
end
