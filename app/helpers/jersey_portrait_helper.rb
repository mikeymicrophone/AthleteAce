module JerseyPortraitHelper
  def jersey_portrait_fallback(name, number)
    if JerseyNumberAssignment.valid_number?(number)
      tag.span class: "jersey-mark" do
        icon("jersey", size: 112) + tag.span(number, class: "jersey-number")
      end
    else
      initials = name.to_s.split.filter_map { |word| word[0] }.first(3).join.upcase
      tag.span initials, class: "jersey-initials"
    end
  end

  def round_jersey_caption(question)
    number = question["subject_jersey_number"]
    return unless JerseyNumberAssignment.valid_number?(number)

    label = "No. #{number}"
    if question["subject_jersey_number_on"].present?
      label += " · recorded #{Date.iso8601(question['subject_jersey_number_on']).strftime('%b %-d, %Y')}"
    end
    label
  end
end
