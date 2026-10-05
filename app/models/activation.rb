class Activation < ApplicationRecord
  belongs_to :player
  belongs_to :contract, optional: true
  belongs_to :campaign

  has_one :team, through: :campaign

  before_validation :infer_player_from_contract

  validates :player_id, uniqueness: { scope: :campaign_id }
  validates :end_date, comparison: { greater_than_or_equal_to: :start_date }, if: -> { start_date.present? && end_date.present? }
  validate :contract_player_matches
  validate :player_sport_matches

  private

  def infer_player_from_contract
    self.player = contract.player if contract && player_id.nil? && player.nil?
  end

  def contract_player_matches
    return unless contract && player
    return if contract.player == player

    errors.add :contract, "must belong to the roster player"
  end

  def player_sport_matches
    return unless player&.sport_id && campaign&.season&.league
    return if player.sport_id == campaign.season.league.sport_id

    errors.add :player, "must belong to the campaign's sport"
  end
end
