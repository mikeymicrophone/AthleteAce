module PlayersHelper
  # Display player name with logo
  def player_name_display player
    tag.div class: "record-name" do
      record_identity player
    end
  end

  # Display player metadata (team, league, sport)
  def player_metadata_display player
    tag.div class: "record-metadata" do
      safe_join [player.team, player.current_organization, player.league, player.sport].compact.map { |record| entity_link record }
    end
  end

  # Display player position tag if available
  def player_position_display player
    if player.primary_position
      tag.div player.primary_position.name, class: "record-tag"
    end
  end

  # Combine all player info elements
  def player_info_display player
    player_name_display(player) +
    player_metadata_display(player) +
    player_position_display(player)
  end

  def player_photo_display player
    tag.div class: "player-photo-container" do
      if player.photo_urls.present?
        tag.img src: player.photo_urls.sample, alt: player.full_name, class: "player-photo"
      else
        tag.div class: "player-photo-placeholder" do
          icon "shirt-sport", size: 48
        end
      end
    end
  end

  include SortableHelper

  def player_sort_links
    sort_links_for(@players, 'players')
  end
end
