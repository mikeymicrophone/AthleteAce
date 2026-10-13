module IconHelper
  # Only trusted, vendored SVG contents can be rendered. A caller cannot supply a file path.
  ICON_CONTENTS = Rails.root.glob("vendor/tabler/icons/*.svg").to_h do |path|
    [ path.basename(".svg").to_s, Nokogiri::XML(path.read).at_css("svg").inner_html.freeze ]
  end.freeze

  RESOURCE_ICONS = {
    sport: "ball-basketball", league: "stack-2", conference: "layout-columns",
    division: "tournament", team: "shield", player: "shirt-sport",
    stadium: "building-stadium", country: "world", state: "map", city: "building-community",
    quest: "script", goal: "target", highlight: "star", achievement: "medal",
    strength: "barbell", rating: "list-numbers", spectrum: "gauge", membership: "id-badge-2",
    year: "calendar", season: "calendar", contest: "medal", contract: "file-certificate",
    activation: "player-play", organization: "shield", position: "shirt-sport",
    chevron_down: "chevron-down", search: "search", shuffle: "arrows-shuffle"
  }.freeze

  SPORT_ICONS = {
    "baseball" => "ball-baseball", "basketball" => "ball-basketball",
    "football" => "ball-american-football", "american football" => "ball-american-football",
    "soccer" => "ball-football", "hockey" => "ice-skating", "ice hockey" => "ice-skating",
    "rugby" => "rugby", "cricket" => "cricket", "lacrosse" => "target"
  }.freeze

  def icon(name, size: 24, **options)
    content = ICON_CONTENTS.fetch name.to_s
    tag.svg content.html_safe, **options.merge(
      class: [ "ace-icon", options[:class] ].compact.join(" "),
      width: size, height: size, viewBox: "0 0 24 24", fill: "none",
      stroke: "currentColor", "stroke-width": 2, "stroke-linecap": "round",
      "stroke-linejoin": "round", "aria-hidden": true, focusable: false
    )
  end

  def icon_for_resource(resource_name, **options)
    name = RESOURCE_ICONS.fetch resource_name.to_s.singularize.to_sym, "info-circle"
    icon name, **options
  end

  def icon_for_sport(sport, **options)
    icon SPORT_ICONS.fetch(sport.name.downcase, "tournament"), **options
  end
end
