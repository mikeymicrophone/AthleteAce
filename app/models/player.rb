class Player < ApplicationRecord
  belongs_to :birth_city, optional: true
  belongs_to :birth_country, optional: true
  belongs_to :team
end
