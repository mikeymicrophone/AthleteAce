class PostgresqlRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :postgresql }
end
