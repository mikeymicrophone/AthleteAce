class Player < ApplicationRecord
  belongs_to :birth_city, optional: true
  belongs_to :birth_country, optional: true
  belongs_to :team
  delegate :sport, to: :team
  delegate :league, to: :team

  def name
    "#{first_name} #{last_name}"
  end
end
