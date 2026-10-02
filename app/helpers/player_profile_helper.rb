module PlayerProfileHelper
  def player_breadcrumbs player, filtered_breadcrumb, filters
    crumbs = if filters.present?
      filtered_breadcrumb
    else
      [player.sport, player.league, player.team.conference, player.team.division, player.team].compact.map do |record|
        { label: record.name, path: polymorphic_path(record), type: record.model_name.singular }
      end
    end
    tag.nav class: "player-breadcrumbs", aria: { label: "Breadcrumb" } do
      tag.ol do
        safe_join crumbs.each_with_index.map { |crumb, index|
          tag.li do
            separator = index.positive? ? icon("arrow-right", size: 14) : ""
            content = if crumb[:current]
              tag.span crumb[:label], aria: { current: "page" }
            else
              link_to crumb[:path], class: "entity-chip", data: { entity: crumb[:type].to_s.underscore.singularize } do
                icon_for_resource(crumb[:type].to_s.underscore, size: 16) + tag.span(crumb[:label])
              end
            end
            safe_join [separator, content]
          end
        }
      end
    end
  end

  def player_hero_portrait player
    team = player.team
    primary = team.primary_color.to_s.match?(/\A#[0-9a-f]{6}\z/i) ? team.primary_color : nil
    foreground = if primary
      red, green, blue = primary.delete_prefix("#").scan(/../).map { |part| part.to_i(16) }
      (red * 299 + green * 587 + blue * 114) / 1000 > 155 ? "#131418" : "#FFFFFF"
    end
    style = primary ? "--jersey-color: #{primary}; --jersey-ink: #{foreground};" : nil
    tag.div class: "profile-portrait", style: style, data: { controller: "entity-image" } do
      fallback = tag.div class: "profile-jersey", data: { entity_image_target: "fallback" }, aria: { hidden: true } do
        icon("jersey", size: 112) + tag.span(team.abbreviation.presence || team.name.split.map { |word| word[0] }.first(3).join.upcase)
      end
      photo = if player.photo_url.present?
        tag.img src: player.photo_url, alt: "", class: "profile-photo hidden",
          data: { entity_image_target: "image", action: "load->entity-image#loaded error->entity-image#failed" }
      end
      safe_join [fallback, photo].compact
    end
  end

  def player_status_line player
    items = [player.primary_position&.name || player.current_position.presence]
    items << (player.active? ? "Active" : "Inactive") unless player.active.nil?
    items << "Since #{player.debut_year}" if player.debut_year.present?
    safe_join items.compact, " · "
  end
end
