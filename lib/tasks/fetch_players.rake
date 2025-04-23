require 'net/http'
require 'json'
require 'uri'
require 'fileutils'
require 'nokogiri'
require 'open-uri'

namespace :players do
  desc "Fetch NHL players and create JSON files"
  task :fetch_nhl => :environment do
    base_dir = Rails.root.join('db/seeds/athlete_ace_data/sports/hockey/USA/NHL/players')
    FileUtils.mkdir_p(base_dir) unless File.directory?(base_dir)
    
    # Load teams from the teams.json file
    teams_file = Rails.root.join('db/seeds/athlete_ace_data/sports/hockey/USA/NHL/teams.json')
    teams_data = JSON.parse(File.read(teams_file))
    teams = teams_data['teams']
    
    # Map NHL team abbreviations to ESPN team IDs
    nhl_team_ids = {
      'ANA' => '25', 'ARI' => '53', 'BOS' => '1', 'BUF' => '2',
      'CGY' => '3', 'CAR' => '4', 'CHI' => '5', 'COL' => '6',
      'CBJ' => '29', 'DAL' => '7', 'DET' => '8', 'EDM' => '9',
      'FLA' => '10', 'LAK' => '11', 'MIN' => '30', 'MTL' => '12',
      'NSH' => '27', 'NJD' => '13', 'NYI' => '14', 'NYR' => '15',
      'OTT' => '16', 'PHI' => '17', 'PIT' => '18', 'SJS' => '19',
      'SEA' => '55', 'STL' => '20', 'TBL' => '21', 'TOR' => '22',
      'VAN' => '23', 'VGK' => '54', 'WSH' => '24', 'WPG' => '28'
    }
    
    teams.each do |team|
      mascot = team['mascot']
      territory = team['territory']
      abbr = team['abbreviation']
      
      puts "Fetching players for #{territory} #{mascot}..."
      
      # Create filename based on mascot
      filename = "#{mascot.downcase.gsub(' ', '_')}.json"
      filepath = File.join(base_dir, filename)
      
      # Try to fetch from ESPN API using team ID instead of abbreviation
      begin
        team_id = nhl_team_ids[abbr]
        uri = URI("https://site.api.espn.com/apis/site/v2/sports/hockey/nhl/teams/#{team_id}/roster")
        req = Net::HTTP::Get.new(uri)
        req['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        
        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(req)
        end
        
        if res.is_a?(Net::HTTPSuccess)
          data = JSON.parse(res.body)
          players = []
          
          if data['athletes']
            data['athletes'].each do |athlete|
              if athlete['fullName']
                name_parts = athlete['fullName'].split(' ', 2)
                first_name = name_parts[0]
                last_name = name_parts[1] || ''
                players << {
                  'first_name' => first_name,
                  'last_name' => last_name
                }
              end
            end
          end
          
          # If we got players, write them to the file
          if players.any?
            File.write(filepath, JSON.pretty_generate({
              'team_name' => mascot,
              'players' => players
            }))
            puts "  Created #{filepath} with #{players.count} players"
          else
            # Try fallback to NHL.com
            puts "  No players found in ESPN API, trying NHL.com..."
            fetch_from_nhl_website(filepath, team)
          end
        else
          puts "  Error fetching data: #{res.code} #{res.message}"
          # Try fallback to NHL.com
          fetch_from_nhl_website(filepath, team)
        end
      rescue => e
        puts "  Error with ESPN API: #{e.message}"
        # Try fallback to NHL.com
        fetch_from_nhl_website(filepath, team)
      end
    end
    
    puts "Completed NHL player fetch"
  end
  
  # Fallback method to scrape NHL.com roster pages
  def fetch_from_nhl_website(filepath, team)
    begin
      mascot = team['mascot']
      url = team['url'] + '/roster'
      
      puts "  Trying to scrape roster from #{url}"
      doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36'))
      
      players = []
      
      # Try multiple selectors to handle different NHL.com page structures
      selectors = [
        # Current structure
        '.nhl-roster__table tr td:nth-child(2) a',
        # Alternate structure
        '.roster-table tr td.name a',
        # Legacy structure
        '.roster__table tbody tr .roster__player-name',
        # Very generic fallback
        'table tr td a[href*="/player/"]',
        # Additional selectors for potential new structures
        '.player-name a',
        '.roster-list .player-info .name'
      ]
      
      selectors.each do |selector|
        elements = doc.css(selector)
        puts "  Tried selector '#{selector}': found #{elements.count} elements"
        next if elements.empty?
        
        elements.each do |element|
          full_name = element.text.strip
          next if full_name.empty? || full_name.include?('Team') || full_name.include?('Roster')
          name_parts = full_name.split(' ', 2)
          first_name = name_parts[0]
          last_name = name_parts[1] || ''
          
          players << {
            'first_name' => first_name,
            'last_name' => last_name
          }
        end
        
        break if players.any? # Stop if we found players with this selector
      end
      
      if players.any?
        File.write(filepath, JSON.pretty_generate({
          'team_name' => mascot,
          'players' => players
        }))
        puts "  Created #{filepath} with #{players.count} players from NHL.com"
      else
        puts "  No players found with any selector on NHL.com"
        create_placeholder(filepath, mascot)
      end
    rescue => e
      puts "  Error scraping NHL.com: #{e.message}"
      create_placeholder(filepath, mascot)
    end
  end
  
  desc "Fetch NBA players and create JSON files"
  task :fetch_nba => :environment do
    base_dir = Rails.root.join('db/seeds/athlete_ace_data/sports/basketball/USA/NBA/players')
    FileUtils.mkdir_p(base_dir) unless File.directory?(base_dir)
    
    # Load teams from the teams.json file
    teams_file = Rails.root.join('db/seeds/athlete_ace_data/sports/basketball/USA/NBA/teams.json')
    teams_data = JSON.parse(File.read(teams_file))
    teams = teams_data['teams']
    
    # Map NBA team abbreviations to ESPN team IDs
    nba_team_ids = {
      'ATL' => '1', 'BOS' => '2', 'BKN' => '17', 'CHA' => '30',
      'CHI' => '4', 'CLE' => '5', 'DAL' => '6', 'DEN' => '7',
      'DET' => '8', 'GSW' => '9', 'HOU' => '10', 'IND' => '11',
      'LAC' => '12', 'LAL' => '13', 'MEM' => '29', 'MIA' => '14',
      'MIL' => '15', 'MIN' => '16', 'NOP' => '3', 'NYK' => '18',
      'OKC' => '25', 'ORL' => '19', 'PHI' => '20', 'PHX' => '21',
      'POR' => '22', 'SAC' => '23', 'SAS' => '24', 'TOR' => '28',
      'UTA' => '26', 'WAS' => '27'
    }
    
    teams.each do |team|
      mascot = team['mascot']
      territory = team['territory']
      abbr = team['abbreviation']
      
      puts "Fetching players for #{territory} #{mascot}..."
      
      # Create filename based on mascot
      filename = "#{mascot.downcase.gsub(' ', '_')}.json"
      filepath = File.join(base_dir, filename)
      
      # Try to fetch from ESPN API using team ID instead of abbreviation
      begin
        team_id = nba_team_ids[abbr]
        uri = URI("https://site.api.espn.com/apis/site/v2/sports/basketball/nba/teams/#{team_id}/roster")
        req = Net::HTTP::Get.new(uri)
        req['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        
        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(req)
        end
        
        if res.is_a?(Net::HTTPSuccess)
          data = JSON.parse(res.body)
          players = []
          
          if data['athletes']
            data['athletes'].each do |athlete|
              if athlete['fullName']
                name_parts = athlete['fullName'].split(' ', 2)
                first_name = name_parts[0]
                last_name = name_parts[1] || ''
                players << {
                  'first_name' => first_name,
                  'last_name' => last_name
                }
              end
            end
          end
          
          # If we got players, write them to the file
          if players.any?
            File.write(filepath, JSON.pretty_generate({
              'team_name' => mascot,
              'players' => players
            }))
            puts "  Created #{filepath} with #{players.count} players"
          else
            # Try fallback to NBA.com
            puts "  No players found in ESPN API, trying NBA.com..."
            fetch_from_nba_website(filepath, team)
          end
        else
          puts "  Error fetching data: #{res.code} #{res.message}"
          # Try fallback to NBA.com
          fetch_from_nba_website(filepath, team)
        end
      rescue => e
        puts "  Error with ESPN API: #{e.message}"
        # Try fallback to NBA.com
        fetch_from_nba_website(filepath, team)
      end
    end
    
    puts "Completed NBA player fetch"
  end
  
  # Fallback method to scrape NBA.com roster pages
  def fetch_from_nba_website(filepath, team)
    begin
      mascot = team['mascot']
      url = team['url'] + '/roster'
      
      puts "  Trying to scrape roster from #{url}"
      doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36'))
      
      players = []
      
      # Try multiple selectors to handle different NBA.com page structures
      selectors = [
        # Current structure
        '.nba-player-index__name a',
        # Alternate structure
        'table.roster tbody tr td.name',
        # Legacy structure
        '.roster__table tbody tr .roster__player-name',
        # Very generic fallback
        'a[href*="/player/"]'
      ]
      
      selectors.each do |selector|
        elements = doc.css(selector)
        next if elements.empty?
        
        elements.each do |element|
          full_name = element.text.strip
          name_parts = full_name.split(' ', 2)
          first_name = name_parts[0]
          last_name = name_parts[1] || ''
          
          players << {
            'first_name' => first_name,
            'last_name' => last_name
          }
        end
        
        break if players.any? # Stop if we found players with this selector
      end
      
      if players.any?
        File.write(filepath, JSON.pretty_generate({
          'team_name' => mascot,
          'players' => players
        }))
        puts "  Created #{filepath} with #{players.count} players from NBA.com"
      else
        create_placeholder(filepath, mascot)
      end
    rescue => e
      puts "  Error scraping NBA.com: #{e.message}"
      create_placeholder(filepath, mascot)
    end
  end
  
  desc "Fetch NHL players using hardcoded data"
  task :fetch_nhl_hardcoded => :environment do
    base_dir = Rails.root.join('db/seeds/athlete_ace_data/sports/hockey/USA/NHL/players')
    FileUtils.mkdir_p(base_dir) unless File.directory?(base_dir)
    
    # Load teams from the teams.json file
    teams_file = Rails.root.join('db/seeds/athlete_ace_data/sports/hockey/USA/NHL/teams.json')
    teams_data = JSON.parse(File.read(teams_file))
    teams = teams_data['teams']
    
    # Sample players for each team (just to get started)
    nhl_players = {
      'Ducks' => [
        {"first_name" => "John", "last_name" => "Gibson"}, 
        {"first_name" => "Trevor", "last_name" => "Zegras"}, 
        {"first_name" => "Troy", "last_name" => "Terry"}
      ],
      'Bruins' => [
        {"first_name" => "Brad", "last_name" => "Marchand"}, 
        {"first_name" => "David", "last_name" => "Pastrnak"}, 
        {"first_name" => "Charlie", "last_name" => "McAvoy"}
      ],
      'Sabres' => [
        {"first_name" => "Rasmus", "last_name" => "Dahlin"}, 
        {"first_name" => "Tage", "last_name" => "Thompson"}, 
        {"first_name" => "Alex", "last_name" => "Tuch"}
      ],
      'Flames' => [
        {"first_name" => "Jacob", "last_name" => "Markstrom"}, 
        {"first_name" => "Nazem", "last_name" => "Kadri"}, 
        {"first_name" => "Rasmus", "last_name" => "Andersson"}
      ],
      'Hurricanes' => [
        {"first_name" => "Sebastian", "last_name" => "Aho"}, 
        {"first_name" => "Andrei", "last_name" => "Svechnikov"}, 
        {"first_name" => "Jaccob", "last_name" => "Slavin"}
      ]
    }
    
    # Add a few default players for each team
    teams.each do |team|
      mascot = team['mascot']
      filename = "#{mascot.downcase.gsub(' ', '_')}.json"
      filepath = File.join(base_dir, filename)
      
      # Get team-specific players or use defaults
      players = nhl_players[mascot] || [
        {"first_name" => "Player", "last_name" => "One"}, 
        {"first_name" => "Player", "last_name" => "Two"},
        {"first_name" => "Player", "last_name" => "Three"}
      ]
      
      # Write to file
      File.write(filepath, JSON.pretty_generate({
        'team_name' => mascot,
        'players' => players
      }))
      puts "Created #{filepath} with #{players.count} players"
    end
    
    puts "Completed NHL player fetch with hardcoded data"
  end
  
  desc "Fetch all players for all leagues"
  task :fetch_all => [:fetch_nhl, :fetch_nba] do
    puts "All player data fetched successfully"
  end
  
  def create_placeholder(filepath, team_name)
    File.write(filepath, JSON.pretty_generate({
      'team_name' => team_name,
      'players' => [
        { 'first_name' => 'Player', 'last_name' => 'One' },
        { 'first_name' => 'Player', 'last_name' => 'Two' }
      ]
    }))
    puts "  Created placeholder file #{filepath}"
  end
end
