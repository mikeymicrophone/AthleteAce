class Contest < ApplicationRecord
  belongs_to :context, polymorphic: true
  belongs_to :champion, class_name: 'Team', optional: true
  belongs_to :season, optional: true
  has_one :championship_season, class_name: "Season", foreign_key: :championship_contest_id

  has_many :title_awards, dependent: :destroy
  has_many :contestants, dependent: :destroy
  has_many :campaigns, through: :contestants
  has_many :teams, through: :campaigns
  has_many :leagues, -> { distinct }, through: :teams
  has_many :conferences, -> { distinct }, through: :teams
  has_many :divisions, -> { distinct }, through: :teams
  has_many :countries, -> { distinct }, through: :leagues, source: :jurisdiction, source_type: "Country"
  has_many :appearances, through: :contestants
  has_many :contest_games, dependent: :destroy
  has_many :games, through: :contest_games
  has_many :competition_memberships, class_name: "ContestGame", foreign_key: :game_id, dependent: :destroy
  has_many :competitions, through: :competition_memberships, source: :contest
  before_validation :assign_game_type
  validate :preserve_appearance_context
  validate :format_rules_are_valid
  validate :preserve_competition_context

  scope :competitions, -> { where(type: nil) }
  
  serialize :comments, coder: JSON
  
  def winner
    contestants.winners.first
  end
  
  def runner_up
    contestants.runner_ups.first
  end
  
  def final_standings
    contestants.by_placing
  end

  private

  def assign_game_type
    self.type = "Game" if kind == "game"
  end

  def format_rules_are_valid
    unless format_rules.is_a?(Hash)
      errors.add :format_rules, "must be a mapping"
      return
    end
    return unless format_rules.key?("rounds")

    rounds = format_rules["rounds"]
    unless rounds.is_a?(Array) && rounds.all? { |round| round.is_a?(Hash) && round["key"].is_a?(String) && round["key"].match?(/\A[a-z0-9][a-z0-9_-]{0,79}\z/) }
      errors.add :format_rules, "rounds must be a list of mappings with stable round keys"
      return
    end
    keys = rounds.map { |round| round["key"] }
    errors.add :format_rules, "round keys must be unique" unless keys.uniq == keys
    rounds.each do |round|
      best_of = round["best_of"]
      errors.add :format_rules, "best_of must be a positive integer" if round.key?("best_of") && !(best_of.is_a?(Integer) && best_of.positive?)
      errors.add :format_rules, "round names must be text of at most 200 characters" if round.key?("name") && !(round["name"].is_a?(String) && round["name"].length <= 200)
    end
  end

  def preserve_competition_context
    return unless persisted?
    if will_save_change_to_kind? && kind == "game" && (contest_games.exists? || title_awards.exists?)
      errors.add :kind, "cannot become game while competition records exist"
    end
    if will_save_change_to_format_rules? && format_rules.is_a?(Hash)
      used = contest_games.pluck(:metadata).filter_map { |metadata| metadata["round"] }.uniq
      declared = Array(format_rules["rounds"]).filter_map { |round| round["key"] if round.is_a?(Hash) }
      if (format_rules.key?("rounds") || format_rules_in_database.to_h.key?("rounds")) && (used - declared).any?
        errors.add :format_rules, "cannot remove rounds referenced by games"
      end
    end
    if will_save_change_to_season_id? && season_id && contestants.joins(:campaign).where.not(campaigns: { season_id: season_id }).exists?
      errors.add :season, "must match the entered campaigns, or remain unset for cross-league competitions"
    end
  end

  def preserve_appearance_context
    return unless persisted? && (will_save_change_to_kind? || will_save_change_to_begin_date?)
    return unless appearances.exists?

    errors.add :kind, "must remain game while appearances exist" unless kind == "game"
    appearances.includes(:stint).each do |appearance|
      if appearance.stint && !appearance.stint.permits_date?(begin_date)
        errors.add :begin_date, "must agree with linked appearance stints"
        break
      end
    end
  end
end
