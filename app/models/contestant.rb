class Contestant < ApplicationRecord
  belongs_to :contest
  belongs_to :campaign
  has_many :appearances, dependent: :destroy
  has_many :title_awards, foreign_key: :winner_id, dependent: :restrict_with_error
  validates :campaign_id, uniqueness: { scope: :contest_id }
  validate :preserve_appearance_context
  validate :competition_membership_matches
  before_destroy :preserve_game_entry
  
  validates :placing, numericality: { greater_than: 0 }, allow_nil: true
  validates :wins, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :losses, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  scope :by_placing, -> { order(:placing) }
  scope :winners, -> { where(placing: 1) }
  scope :runner_ups, -> { where(placing: 2) }
  
  def winner?
    placing == 1
  end
  
  def runner_up?
    placing == 2
  end

  private

  def competition_membership_matches
    return unless contest && campaign

    if contest.season_id && contest.season_id != campaign.season_id
      errors.add :campaign, "must belong to the contest's season"
    end
    if contest.kind == "game"
      ContestGame.where(game_id: contest.id).includes(:contest).each do |membership|
        unless membership.contest.contestants.exists?(campaign_id: campaign_id)
          errors.add :campaign, "must be entered in each of the game's competitions"
        end
      end
    end
    if persisted? && (will_save_change_to_contest_id? || will_save_change_to_campaign_id?)
      errors.add :campaign, "cannot change an awarded title's winner" if title_awards.exists?
      if Contestant.joins(contest: :competition_memberships).where(campaign_id: campaign_id_in_database, contest_games: { contest_id: contest_id_in_database }).exists?
        errors.add :campaign, "cannot change while linked games use this competition entry"
      end
    end
  end

  def preserve_game_entry
    return if destroyed_by_association || contest&.kind == "game"
    if Contestant.joins(contest: :competition_memberships).where(campaign_id: campaign_id, contest_games: { contest_id: contest_id }).exists?
      errors.add :base, "Cannot remove an entry used by competition games"
      throw :abort
    end
  end

  def preserve_appearance_context
    return unless persisted? && (will_save_change_to_campaign_id? || will_save_change_to_contest_id?)
    appearances.includes(:player, :stint).each do |appearance|
      appearance.contestant = self
      errors.add :base, "Change would invalidate an appearance: #{appearance.errors.full_messages.join(', ')}" unless appearance.valid?
    end
  end
end
