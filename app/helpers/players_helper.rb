module PlayersHelper
  # Display player name with logo
  def player_name_display player
    tag.div class: "record-name" do
      display_name_with_lazy_logo(player, logo_attribute: :image_url)
    end
  end
  
  # Display player metadata (team, league, sport)
  def player_metadata_display player
    tag.div class: "record-metadata" do
      link_to_name(player.team) + 
      " | " + 
      display_name_with_lazy_logo(player.league) + 
      " | " + 
      display_name_with_lazy_logo(player.sport, logo_attribute: :icon_url)
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
          tag.i class: "fa-solid fa-user"
        end
      end
    end
  end

  include SortableHelper

  def player_sort_links
    sort_links_for(@players, 'players')
  end
end
