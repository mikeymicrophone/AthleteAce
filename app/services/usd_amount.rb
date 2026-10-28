class UsdAmount
  def self.parse(value, minimum_cents: 1)
    text = value.to_s.strip
    raise ArgumentError, "Enter a dollar amount with at most two decimal places." unless text.match?(/\A\d+(?:\.\d{1,2})?\z/)
    cents = (BigDecimal(text) * 100).to_i
    unless cents.between?(minimum_cents, 9_223_372_036_854_775_807)
      raise ArgumentError, "The amount must be at least $#{format('%.2f', minimum_cents / 100.0)} and fit the supported balance."
    end
    cents
  end
end
