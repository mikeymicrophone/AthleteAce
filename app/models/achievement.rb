class Achievement < ApplicationRecord
  include Moderatable
  TARGET_TYPES = %w[Player Team Division Conference League Sport City State Country Federation PlayerGroup].freeze

  has_many :goal_achievements, dependent: :destroy
  PRACTICE_SCOPES = { "PlayerGroup" => :player_group_id, "Team" => :team_id, "Division" => :division_id, "Conference" => :conference_id,
    "League" => :league_id, "Sport" => :sport_id, "City" => :city_id, "State" => :state_id }.freeze

  def practice_scope
    return { player_id: target_id, include_inactive: true } if target_type == "Player"

    key = PRACTICE_SCOPES[target_type]
    { key => target_id, include_inactive: true } if key
  end

  def roster_snapshot
    return unless practice_scope && target
    return { ids: [ target_id ], scope: practice_scope } if target_type == "Player"

    return { ids: target.players.pluck(:id), scope: practice_scope } if target_type == "PlayerGroup"

    setup = GameRoundSetup.new(practice_scope)
    players = setup.scoped_players
    if players.none?
      seasonal = setup.season_suggestion
      return { ids: seasonal.subjects.pluck(:id), scope: seasonal.scope_params } if seasonal
    end
    { ids: players.pluck(:id), scope: practice_scope }
  end

  has_many :highlights, dependent: :destroy
  has_many :quests, through: :highlights
  # Presence is checked below, after the type check, so a bogus type is never constantized
  belongs_to :target, polymorphic: true, optional: true

  validates :name, presence: true
  validates :target_type, inclusion: { in: TARGET_TYPES }
  validates :target, presence: { message: :required }, if: -> { TARGET_TYPES.include?(target_type) }
  
  # Add this achievement to a quest
  def add_to_quest(quest, position: nil, required: true)
    highlights.create(
      quest: quest,
      position: position,
      required: required
    )
  end
  
  # Remove this achievement from a quest
  def remove_from_quest(quest)
    highlights.where(quest: quest).destroy_all
  end
end
