class SeedSeasons
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Seasons -----"

    seed_files glob_patterns

    SeedHelpers.log_and_puts "Seasons seeding complete: #{Season.count} total"
  end

  def self.sync_references(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Syncing Season Champion References -----"

    seed_files glob_patterns, references_only: true
  end

  def self.seed_files(glob_patterns, references_only: false)
    glob_patterns.each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading seasons from #{SeedHelpers.relative_path(file_data[:path])}"

        league = League.find_by(name: file_data[:data]['league_name'])
        if league.nil?
          SeedHelpers.log_and_puts "Warning: League not found: #{file_data[:data]['league_name']}"
          next
        end

        file_data[:data]['seasons'].each do |season_data|
          year = Year.find_by(number: season_data['year'])
          if year.nil?
            SeedHelpers.log_and_puts "Warning: Year not found: #{season_data['year']}"
            next
          end

          attributes = references_only ? reference_attributes(season_data, league, year) : build_attributes(season_data, league, year)

          SeedHelpers.find_or_create_with_changes(
            Season,
            { year: year, league: league },
            attributes
          )
        end
      end
    end
  end

  def self.build_attributes(season_data, league, year)
    attributes = season_data.except(
      'year',
      'champion_name',
      'championship_contest_name'
    ).dup

    %w[start_date end_date playoff_start_date playoff_end_date].each do |date_field|
      attributes[date_field] = Date.parse(attributes[date_field]) if attributes[date_field]
    end

    attributes['comments'] ||= []
    attributes.merge reference_attributes(season_data, league, year)
  end

  def self.reference_attributes(season_data, league, year)
    attributes = {}

    championship_contest = resolve_championship_contest(season_data, league, year)
    if championship_contest.nil? && (season_data['championship_contest_id'].present? || season_data['championship_contest_name'].present?)
      SeedHelpers.log_and_puts "Warning: Championship contest not found for #{league.name} #{year.number}: #{season_data['championship_contest_name'] || season_data['championship_contest_id']}"
    end
    attributes['championship_contest_id'] = championship_contest&.id

    champion = resolve_champion(season_data) || championship_contest&.champion
    if champion.nil? && (season_data['champion_id'].present? || season_data['champion_name'].present?)
      SeedHelpers.log_and_puts "Warning: Champion not found for #{league.name} #{year.number}: #{season_data['champion_name'] || season_data['champion_id']}"
    end
    attributes['champion_id'] = champion&.id

    attributes
  end

  def self.resolve_champion(season_data)
    if season_data['champion_id'].present?
      find_team_by_reference season_data['champion_id']
    elsif season_data['champion_name'].present?
      find_team_by_reference season_data['champion_name']
    end
  end

  def self.resolve_championship_contest(season_data, league, year)
    season = Season.find_by(year: year, league: league)

    if season_data['championship_contest_id'].present?
      Contest.find_by(id: season_data['championship_contest_id'])
    elsif season_data['championship_contest_name'].present? && season.present?
      season.contests.find_by(name: season_data['championship_contest_name'])
    end
  end

  def self.find_team_by_reference(value)
    return Team.find_by(id: value) if value.to_s.match?(/^\d+$/)

    Team.find_by(mascot: value) ||
      Team.find_by(territory: value) ||
      Team.find_by("territory || ' ' || mascot = ?", value)
  end
end
