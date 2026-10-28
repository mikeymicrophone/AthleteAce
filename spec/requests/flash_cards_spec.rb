require "rails_helper"

RSpec.describe "Flash cards", type: :request do
  let(:team) { create(:team, territory: "Cincinnati", mascot: "Reds") }
  let!(:rival) { create(:team, league: team.league) }
  let!(:player) { create(:player, first_name: "Chase", last_name: "Burns", team: team, current_position: "SP") }

  it "shows each player's team and position to guests without saving a round" do
    expect {
      get flash_cards_path, params: { team_ids: [ team.id ], length: 10, delay: 2 }
    }.not_to change { [ GameRound.count, GameAttempt.count ] }
    expect(response).to have_http_status(:ok)
    card = Nokogiri::HTML(response.body).at_css(".flash-card")
    expect(card.text.squish).to include("Chase Burns is on the", team.name, "(SP)")
    expect(response.body).to include('data-flash-cards-delay-value="2"', "2s per card")
  end

  it "names clubs without a place and without \"the\"" do
    club = create(:team, territory: nil, mascot: "Real Madrid", league: team.league)
    create(:player, first_name: "Jude", last_name: "Bellingham", team: club)
    expect(club.name).to eq("Real Madrid")
    get flash_cards_path, params: { team_ids: [ club.id ] }
    expect(Nokogiri::HTML(response.body).at_css(".flash-card-sentence").text.squish).to match(/\AJude Bellingham is on \S*Real Madrid\z/)
  end

  it "offers flash cards and their delays from the round setup" do
    get new_game_round_path, params: { game_type: "flash_cards", team_ids: [ team.id ], delay: 5 }
    doc = Nokogiri::HTML(response.body)
    expect(doc.css('input[type=radio][name="delay"]').map { |input| input["value"] }).to eq(%w[0 2 5])
    expect(doc.at_css('input[type=radio][name="delay"][checked]')["value"]).to eq("5")
    form = doc.at_css(".round-start-dock form")
    expect(form["action"]).to eq(flash_cards_path)
    expect(form.css("input[type=hidden]").to_h { |input| [ input["name"], input["value"] ] }).to include("delay" => "5", "team_ids[]" => team.id.to_s)
  end

  it "returns to setup when the scope has no players" do
    get flash_cards_path, params: { team_ids: [ rival.id ] }
    expect(response).to redirect_to(new_game_round_path(team_ids: [ rival.id ], game_type: "flash_cards", length: 10, include_inactive: false, fact_type: "team", delay: 0))
    expect(flash[:alert]).to eq("No players in this scope. Try another team or league.")
  end

  it "refuses to save flash cards as a scored round" do
    sign_in create(:ace)
    expect {
      post game_rounds_path, params: { game_type: "flash_cards", team_ids: [ team.id ] }
    }.not_to change(GameRound, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Start flash cards")
  end
end
