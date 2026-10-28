class SignInEvent < ApplicationRecord
  belongs_to :ace
  validates :outcome, inclusion: { in: %w[success failure] }

  def self.record!(ace, request, outcome:)
    create!(ace: ace, outcome: outcome, ip_address: request.remote_ip.to_s.first(64), user_agent: request.user_agent.to_s.first(512))
  end

  def readonly?
    persisted?
  end
end
