module VisualAssetPeriod
  extend ActiveSupport::Concern

  included do
    include SeedObservation
    belongs_to :team
    has_many :asset_representations, as: :subject, dependent: :destroy
    validates :name, presence: true
    validates :end_date, comparison: { greater_than_or_equal_to: :start_date }, if: -> { start_date && end_date }
    validates :end_date, absence: true, if: :ongoing?
  end
end
