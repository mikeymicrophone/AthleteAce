module GameHistoryHelper
  def history_accuracy value
    value ? "#{value.round}%" : "—"
  end

  def history_entity record, fallback
    record ? entity_link(record) : tag.span(fallback, class: "history-unavailable")
  end

  def history_day_description day
    date = day[:date].strftime "%a, %b %-d"
    day[:total].positive? ? "#{history_accuracy day[:accuracy]} · #{date} · #{day[:correct]} of #{day[:total]} correct" : "#{date} · No attempts"
  end

  def history_chart days
    segments = []
    days.each_with_index do |day, index|
      if day[:accuracy]
        segments << [] if index.zero? || days[index - 1][:accuracy].nil?
        segments.last << "#{50 + index * 100},#{200 - day[:accuracy] * 2}"
      end
    end
    tag.div class: "history-chart", aria: { label: "Daily accuracy" } do
      axis = tag.div(class: "history-chart-axis", aria: { hidden: true }) { safe_join [100, 50, 0].map { |value| tag.span "#{value}%" } }
      plot = tag.div class: "history-chart-plot" do
        lines = tag.svg viewBox: "0 0 700 200", preserveAspectRatio: "none", class: "history-chart-lines", aria: { hidden: true } do
          safe_join([0, 100, 200].map { |y| tag.line x1: 0, x2: 700, y1: y, y2: y, class: "history-chart-gridline" } +
            segments.map { |points| tag.polyline points: points.join(" "), fill: "none", class: "history-chart-trend" })
        end
        points = days.each_with_index.map do |day, index|
          description = history_day_description day
          tag.div class: "history-chart-day" do
            if day[:accuracy]
              tag.button type: "button", class: "history-chart-point", style: "top: #{100 - day[:accuracy]}%;",
                aria: { label: description, describedby: "history-day-#{index}" } do
                tag.span(description, id: "history-day-#{index}", role: "tooltip", class: "history-chart-tooltip")
              end
            else
              tag.span "—", class: "history-chart-gap", title: description, aria: { label: description }
            end
          end
        end
        lines + tag.div(safe_join(points), class: "history-chart-points")
      end
      labels = tag.div(class: "history-chart-dates", aria: { hidden: true }) { safe_join days.map { |day| tag.span day[:date].strftime("%a") } }
      safe_join [axis, plot, labels]
    end
  end

  def history_game_filter_path
    @team ? team_strength_game_attempts_path(@team) : strength_game_attempts_path
  end
end
