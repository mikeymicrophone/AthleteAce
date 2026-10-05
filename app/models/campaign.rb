class Campaign < ApplicationRecord
  belongs_to :team
  belongs_to :season
  belongs_to :stadium, optional: true
  belongs_to :city, optional: true
  belongs_to :conference, optional: true
  belongs_to :division, optional: true
  
  has_one :league, through: :season
  has_one :sport, through: :league
  has_many :contestants, dependent: :destroy
  has_many :contests, through: :contestants
  has_many :activations, dependent: :destroy
  has_many :contracts, -> { distinct }, through: :activations
  has_many :activated_players, -> { distinct }, through: :activations, source: :player
  
  validates :team_id, presence: true
  validates :season_id, presence: true
  validates :team_id, uniqueness: { scope: :season_id }
  validate :conference_matches_season_league
  validate :division_matches_season_context

  def name
    display_name.presence || [territory, mascot].compact_blank.join(" ").presence || team.name
  end
  alias_method :full_name, :name
  
  def self.ransackable_attributes auth_object = nil
    column_names
  end
  
  def self.ransackable_associations auth_object = nil
    reflect_on_all_associations.map { |a| a.name.to_s }
  end

  private

  def conference_matches_season_league
    return unless conference && season
    return if conference.league_id == season.league_id

    errors.add :conference, "must belong to the season's league"
  end

  def division_matches_season_context
    return unless division && season

    if division.conference&.league_id != season.league_id
      errors.add :division, "must belong to the season's league"
    end
    if conference && division.conference != conference
      errors.add :division, "must belong to the campaign's conference"
    end
  end
end
