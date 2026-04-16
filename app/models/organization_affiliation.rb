class OrganizationAffiliation < ApplicationRecord
  belongs_to :organization
  belongs_to :team

  has_one :league, through: :team
  has_one :sport, through: :league

  validates :organization, presence: true
  validates :team, presence: true
  validates :team_id, uniqueness: { scope: [:organization_id, :start_date], message: "already has this organization affiliation starting on this date" }
  validates :end_date, comparison: { greater_than_or_equal_to: :start_date }, if: -> { start_date.present? && end_date.present? }
  validate :team_affiliations_do_not_overlap

  scope :chronological, -> { order(start_date: :desc, end_date: :desc, created_at: :desc) }
  scope :current, -> {
    where("start_date IS NULL OR start_date <= ?", Date.current)
      .where("end_date IS NULL OR end_date >= ?", Date.current)
  }

  def self.ransackable_attributes(auth_object = nil)
    column_names
  end

  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |association| association.name.to_s }
  end

  def active_on?(date)
    starts_before = start_date.blank? || start_date <= date
    ends_after = end_date.blank? || end_date >= date

    starts_before && ends_after
  end

  private

  def team_affiliations_do_not_overlap
    return unless team

    overlapping_affiliation = team.organization_affiliations.where.not(id: id).detect do |other|
      date_ranges_overlap?(other)
    end

    return unless overlapping_affiliation

    errors.add(
      :base,
      "Team affiliation dates overlap with #{overlapping_affiliation.organization.name}"
    )
  end

  def date_ranges_overlap?(other)
    this_start = start_date || Date.new(0, 1, 1)
    this_end = end_date || Date.new(9999, 12, 31)
    other_start = other.start_date || Date.new(0, 1, 1)
    other_end = other.end_date || Date.new(9999, 12, 31)

    this_start <= other_end && other_start <= this_end
  end
end
