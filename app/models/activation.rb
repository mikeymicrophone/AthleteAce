class Activation < ApplicationRecord
  belongs_to :contract
  belongs_to :campaign
  
  has_one :player, through: :contract
  has_one :team, through: :contract
end
