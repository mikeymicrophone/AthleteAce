class Season < ApplicationRecord
  belongs_to :year
  belongs_to :league
  has_many :campaigns, dependent: :destroy
  has_many :contests, dependent: :destroy
  
  validates :year, presence: true
  validates :league, presence: true
  validates :year_id, uniqueness: { scope: :league_id, message: "already has a season for this league" }
  validates :end_date, comparison: { greater_than: :start_date }, if: -> { start_date.present? && end_date.present? }
  validates :playoff_start_date, comparison: { greater_than_or_equal_to: :end_date }, if: -> { end_date.present? && playoff_start_date.present? }
  validates :playoff_end_date, comparison: { greater_than: :playoff_start_date }, if: -> { playoff_start_date.present? && playoff_end_date.present? }
  
  scope :recent, -> { joins(:year).order("years.number DESC") }
  scope :chronological, -> { joins(:year).order("years.number ASC") }
  scope :seeded, -> { where.not(seed_version: nil) }
  scope :current, -> { where("start_date <= ? AND (end_date IS NULL OR end_date >= ?)", Date.current, Date.current) }
  scope :completed, -> { where("end_date < ?", Date.current) }
  
  def name
    "#{year.number} #{league.name}"
  end
  
  def to_s
    name
  end
  
  def season_duration
    return nil unless start_date && end_date
    (end_date - start_date).to_i
  end
  
  def playoffs?
    playoff_start_date.present?
  end
  
  def playoffs_duration
    return nil unless playoff_start_date && playoff_end_date
    (playoff_end_date - playoff_start_date).to_i
  end
  
  def status
    return "upcoming" if start_date && start_date > Date.current
    return "in_playoffs" if playoffs? && playoff_start_date <= Date.current && (playoff_end_date.nil? || playoff_end_date >= Date.current)
    return "completed" if end_date && end_date < Date.current
    "in_progress"
  end
end
