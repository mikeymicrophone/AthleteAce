class StaffTenure < ApplicationRecord
  include SeedObservation

  ROLES = %w[coach staff broadcaster].freeze

  belongs_to :person
  belongs_to :organization
  belongs_to :team, optional: true

  normalizes :start_date, :end_date, with: ->(value) { value.presence }

  enum :role, ROLES.index_with(&:itself), validate: true
  validates :title, :entity_code, :source, presence: true
  validates :entity_code, uniqueness: true
  validate :dates_have_known_precision

  scope :chronological, -> { order(Arel.sql("start_date DESC NULLS LAST"), :id) }

  private

  def date_bounds(value)
    return unless value&.match?(/\A[0-9]{4}(?:-[0-9]{2}(?:-[0-9]{2})?)?\z/)

    year, month, day = value.split("-").map(&:to_i)
    return unless year.positive?

    first = Date.new(year, month || 1, day || 1)
    last = day ? first : month ? first.end_of_month : first.end_of_year
    [ first, last ]
  rescue Date::Error
    nil
  end

  def dates_have_known_precision
    bounds = %i[start_date end_date].to_h do |attribute|
      value = public_send(attribute)
      range = date_bounds(value)
      errors.add(attribute, "must be YYYY, YYYY-MM, or YYYY-MM-DD") if value.present? && range.nil?
      [ attribute, range ]
    end
    if bounds[:start_date] && bounds[:end_date] && bounds[:start_date].first > bounds[:end_date].last
      errors.add :end_date, "must not be before the start date"
    end
    errors.add :end_date, "must be absent for an ongoing appointment" if ongoing? && end_date.present?
  end
end
