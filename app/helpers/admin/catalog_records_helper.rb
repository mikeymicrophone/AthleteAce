module Admin::CatalogRecordsHelper
  def catalog_value(value)
    return "Not set" if value.nil?
    return "Empty list" if value == []
    value.is_a?(Array) ? value.join("\n") : value.to_s
  end

  def catalog_kind(edit)
    edit.record_type == "Player" ? "players" : "teams"
  end
end
