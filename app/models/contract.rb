class Contract < ApplicationRecord
  belongs_to :player
  belongs_to :team
  has_many :activations, dependent: :nullify
  has_many :campaigns, through: :activations

  validates :end_date, comparison: { greater_than_or_equal_to: :start_date }, if: -> { start_date.present? && end_date.present? }

  def duration
    return unless start_date && end_date

    (end_date - start_date).to_i
  end
end
