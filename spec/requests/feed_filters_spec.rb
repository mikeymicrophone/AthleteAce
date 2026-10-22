require "rails_helper"

RSpec.describe "Feed sport and league filters", type: :request do
  let(:author) { create(:ace) }
  let(:baseball) { create(:sport, name: "Baseball") }
  let(:basketball) { create(:sport, name: "Basketball") }
  let(:mlb) { create(:league, sport: baseball, name: "MLB") }
  let(:nba) { create(:league, sport: basketball, name: "NBA") }

  it "intersects sport, league and search using recorded leagues, including after a transfer" do
    buy_credit(author)
    cubs = create(:team, league: mlb)
    player = create(:player, team: cubs)
    post = submit_credit(ace: author, target: player, message: "Unstoppable effort")
    other = submit_credit(ace: author, target: create(:team, league: nba), message: "Unstoppable defense")
    [ post, other ].each { |record| review_post(record, action: "approve") }
    player.update!(team: other.target)
    get feed_path(sport_id: baseball.id, q: "Unstoppable")
    expect(response.body).to include(post.message)
    expect(response.body).not_to include(other.message)
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
    expect(response.body).to include('name="turbo-refresh-method" content="morph"', "turbo-cable-stream-source")
    get feed_path(league_id: nba.id)
    expect(response.body).to include(other.message)
    expect(response.body).not_to include(post.message)
    get feed_path(sport_id: baseball.id, league_id: nba.id)
    expect(response.body).not_to include(post.message, other.message)
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('#league_id option[selected]')["value"]).to eq(nba.id.to_s)
    expect(doc.at_css('#sport_id option[selected]')["value"]).to eq(baseball.id.to_s)
  end

  it "keeps pending posts private and applies sport to My teams cards and posts" do
    buy_credit(author)
    cubs = create(:team, league: mlb)
    bulls = create(:team, league: nba)
    [ cubs, bulls ].each { |team| author.follows.create!(followable: team) }
    pending = submit_credit(ace: author, target: cubs, message: "My next Cubs shout-out")
    other = submit_credit(ace: author, target: bulls, message: "My next Bulls shout-out")
    sign_in author
    get feed_path(view: "my_teams", sport_id: baseball.id)
    expect(response.body).to include(pending.message)
    expect(response.body).not_to include(other.message)
    expect(Nokogiri::HTML(response.body).css('.feed-team-card').map { |node| node['aria-label'] }).to eq([ cubs.name ])
    sign_out author
    get feed_path(sport_id: baseball.id)
    expect(response.body).not_to include(pending.message)
    get feed_path(sport_id: -1)
    expect(response).to have_http_status(:not_found)
    get feed_path(league_id: -1)
    expect(response).to have_http_status(:not_found)
  end

  it "preserves query and filters across views and pagination without changing session ranking" do
    buy_credit(author)
    team = create(:team, league: mlb)
    posts = 6.times.map { |index| submit_credit(ace: author, target: team, message: "Cubs hustle #{index}", bid: 1) }
    posts.each { |post| review_post(post, action: "approve") }
    get feed_path(sport_id: baseball.id, league_id: mlb.id, q: "hustle")
    first_order = Nokogiri::HTML(response.body).css('article[id^="shout_out_"]').map { |node| node['id'] }
    expect(first_order.size).to eq(5)
    doc = Nokogiri::HTML(response.body)
    links = doc.css('a[href]').select { |link| link['href'].include?('posts_page=2') || link.text == 'My teams' }
    expect(links.map { |link| link["href"] }.uniq.size).to eq(2)
    links.each do |link|
      query = Rack::Utils.parse_nested_query(URI.parse(link['href']).query)
      expect(query).to include('sport_id' => baseball.id.to_s, 'league_id' => mlb.id.to_s, 'q' => 'hustle')
    end
    get feed_path(sport_id: baseball.id, league_id: mlb.id, q: "hustle")
    expect(Nokogiri::HTML(response.body).css('article[id^="shout_out_"]').map { |node| node['id'] }).to eq(first_order)
    get links.find { |link| link['href'].include?('posts_page=2') }['href']
    expect(Nokogiri::HTML(response.body).css('article[id^="shout_out_"]').size).to eq(1)
  end
end
