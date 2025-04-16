class Player < PostgresqlRecord
  belongs_to :birth_city
  belongs_to :birth_country
  belongs_to :team
end
