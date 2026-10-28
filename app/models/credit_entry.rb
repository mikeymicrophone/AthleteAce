class CreditEntry < ApplicationRecord
  belongs_to :credit_account
  belongs_to :source, polymorphic: true

  def readonly?
    persisted?
  end
end
