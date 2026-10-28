class CreditAccount < ApplicationRecord
  belongs_to :ace
  has_many :credit_entries, dependent: :restrict_with_error

  def self.for(ace)
    find_or_create_by!(ace_id: ace.id)
  end

  def apply!(source:, kind:, available_delta:, reserved_delta: 0)
    key = "#{source.class.name}:#{source.id}:#{kind}"
    with_lock(requires_new: true) do
      previous = credit_entries.find_by(operation_key: key)
      if previous
        unless previous.available_delta == available_delta && previous.reserved_delta == reserved_delta
          raise ArgumentError, "This credit operation was already recorded with different amounts."
        end
        return previous
      end
      if available_cents + available_delta < 0 || reserved_cents + reserved_delta < 0
        raise ArgumentError, "There is not enough available credit for this bid."
      end
      update!(available_cents: available_cents + available_delta, reserved_cents: reserved_cents + reserved_delta)
      credit_entries.create!(source: source, operation_key: key, kind: kind,
        available_delta: available_delta, reserved_delta: reserved_delta)
    end
  end
end
