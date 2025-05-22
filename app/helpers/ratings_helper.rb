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
  
  # Display the rating slider container
  def rating_slider_container(record, selected_spectrums)
    tag.div class: "record-rating-container" do
      render partial: "shared/rating_slider", locals: { 
        target: record, 
        selected_spectrums: selected_spectrums 
      }
    end
  end
end
