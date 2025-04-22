["Baseball", "Basketball", "Football", "Soccer", "Hockey", "Lacrosse", "Rugby", "Cricket"].each do |sport_name|
  Sport.find_or_create_by!(name: sport_name)
end
