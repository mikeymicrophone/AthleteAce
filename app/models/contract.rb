class Contract < ApplicationRecord
  belongs_to :player
  belongs_to :team
  has_many :activations, dependent: :destroy
  has_many :campaigns, through: :activations
end
