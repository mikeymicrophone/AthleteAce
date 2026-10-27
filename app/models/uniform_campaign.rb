class UniformCampaign < ApplicationRecord
  belongs_to :uniform
  belongs_to :campaign
  validates :campaign_id, uniqueness: { scope: :uniform_id }
  validate :same_team

  private

  def same_team
    errors.add :campaign, "must belong to the uniform's team" if uniform && campaign && uniform.team_id != campaign.team_id
  end
end
