module SearchesHelper
  def shell_search_placeholder
    { "play" => "Search players, teams, places", "feed" => "Search shout-outs, players, teams",
      "mod" => "Search the queue and aces", "admin" => "Search aces, data, settings" }.fetch(current_side)
  end

  def shell_search_name(record)
    return record.public_name if record.is_a?(Ace)
    return "#{record.target_name}: #{record.message.truncate(100)}" if record.is_a?(ShoutOut) && current_side == "feed"
    return moderation_item_name(record) if record.is_a?(Highlight)
    record.name
  end

  def shell_search_path(record)
    if record.is_a?(ShoutOut) && current_side == "feed"
      feed_post_path(record)
    elsif record.is_a?(Ace)
      current_side == "admin" ? admin_person_path(record) : ace_profile_path(record, side: current_side)
    elsif Moderation::Queue::TYPES.value?(record.class)
      moderation_item_path(type: record.class.name, id: record.id)
    else
      polymorphic_path(record, side: current_side)
    end
  end

  def shell_search_settings(query)
    return [] unless current_side == "admin" && query.length >= 2

    [ [ "Account settings", edit_ace_registration_path ], [ "Your profile", edit_profile_path ],
      [ "Admin overview", admin_path ], [ "People", admin_people_path ], [ "Sports data", admin_catalog_records_path ],
      [ "Content catalog", browse_path(section: "content", side: "admin") ] ].select { |name, _path| name.downcase.include?(query.downcase) }
  end
end
