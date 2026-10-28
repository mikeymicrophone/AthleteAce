require "rails_helper"

RSpec.describe "Browse entity navigation", type: :system do
  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  def viewport(width)
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: width, height: 900, deviceScaleFactor: 1, mobile: false
  end

  def expect_no_overflow
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true), "overflow on #{page.current_path}"
  end

  it "follows scoped links from a sport through a league to a team on a phone" do
    league = create :league, name: "Pacific Basketball League", sport: create(:sport, name: "Basketball")
    team = create :team, league: league, territory: "Oakland", mascot: "Herons"
    create_list :player, 2, team: team
    viewport 390
    visit sport_path(league.sport, side: "play")
    click_link league.name, exact: true
    expect(page).to have_css("main h1", text: league.name.upcase, count: 1)
    expect(page).to have_css('body[data-side="play"]')
    expect_no_overflow
    click_link "View all teams"
    expect(page).to have_current_path(league_teams_path(league))
    expect(page).to have_content(team.name)
    click_link team.name, exact: true
    expect(page).to have_css('body[data-side="play"]')
    expect(page).to have_content(league.name)
    expect_no_overflow
  end

  it "keeps entity records readable on phone and desktop in both themes" do
    country = create :country, name: "United States"
    state = create :state, name: "California", country: country
    city = create :city, name: "Oakland", state: state
    stadium = create :stadium, city: city, name: "Harbor Arena", address: "700 Harbor Way", capacity: 18000
    league = create :league, name: "Pacific Basketball League", jurisdiction: city.country, sport: create(:sport, name: "Basketball")
    team = create :team, league: league, stadium: stadium, territory: "Oakland", mascot: "Herons"
    player = create :player, team: team, birth_city: city, first_name: "Jordan", last_name: "Reyes"
    conference = create :conference, league: league, name: "Pacific Conference"
    division = create :division, conference: conference, name: "Coastal Division"
    membership = create :membership, team: team, division: division
    season = create :season, league: league, champion: team, year: create(:year, number: 2024)
    campaign = Campaign.create! team: team, season: season
    organization = create :organization, name: "Pacific Sports Group"
    affiliation = create :organization_affiliation, organization: organization, team: team, details: { "archive" => "a" * 250 }
    contract = Contract.create! organization: organization, player: player, details: { "source" => "b" * 250 }
    activation = Activation.create! player: player, campaign: campaign, contract: contract, details: { "note" => "c" * 250 }
    competition = Contest.create! name: "Pacific playoffs", context: league, season: season, kind: "playoffs", details: { "source" => "d" * 250 }
    spectrum = create :spectrum, name: "Composure"
    achievement = create :achievement, name: "Read the defense", target: team
    records = [ league.sport, league, conference, division, city.country, city.state, city, stadium, organization, affiliation, membership, season.year, season, campaign, contract, activation, competition, spectrum, achievement ]
    [ 390, 1280 ].each do |width|
      viewport width
      records.each do |record|
        visit polymorphic_path(record, side: "play")
        expect(page).to have_css("main h1", count: 1)
        %w[light dark].each do |theme|
          page.execute_script("document.documentElement.dataset.theme = arguments[0]", theme)
          expect_no_overflow
          if page.has_css?(".related-record", wait: 0)
            background = theme == "dark" ? "rgba(27, 31, 38, 1)" : "rgba(236, 235, 230, 1)"
            expect(page.first(".related-record")).to match_style("background-color" => background)
          end
          if [ league, organization, season, contract ].include?(record)
            page.save_screenshot Rails.root.join("tmp/screenshots/browse-#{record.model_name.singular}-#{width}-#{theme}.png")
          end
        end
      end
      [ organizations_path, organization_affiliations_path, campaigns_path, memberships_path, contracts_path, activations_path, seasons_path, contests_path, spectrums_path, achievements_path ].each do |path|
        visit path
        expect(page).to have_css("main h1", count: 1)
        expect_no_overflow
      end
    end
  end
end
