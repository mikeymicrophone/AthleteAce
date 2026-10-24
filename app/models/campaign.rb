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
  has_many :title_awards, through: :contestants
  has_many :contests, through: :contestants
  has_many :activations, dependent: :destroy
  has_many :contracts, -> { distinct }, through: :activations
  has_many :activated_players, -> { distinct }, through: :activations, source: :player
  has_many :rosters, dependent: :destroy
  has_many :roster_entries, through: :rosters
  has_many :appearances, through: :contestants
  
  validates :team_id, presence: true
  validates :season_id, presence: true
  validates :team_id, uniqueness: { scope: :season_id }
  validate :conference_matches_season_league
  validate :division_matches_season_context
  validate :preserve_contest_seasons, on: :update

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

  def preserve_contest_seasons
    if will_save_change_to_season_id? && contestants.joins(:contest).where.not(contests: { season_id: nil }).where.not(contests: { season_id: season_id }).exists?
      errors.add :season, "must agree with the campaign's contests"
    end
  end

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
