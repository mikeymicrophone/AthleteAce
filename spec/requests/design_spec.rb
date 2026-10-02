require 'rails_helper'

RSpec.describe "Design reference pages", type: :request do
  it "GET /design/tokens renders the tokens in every theme" do
    get design_tokens_path

    expect(response).to have_http_status(:success)
    document = response.parsed_body
    %w[light dark system].each do |theme|
      panel = document.at_css("##{theme}_token_sheet")
      expect(panel["data-theme"]).to eq(theme)
      expect(panel.css("h2").map(&:text)).to include("Type", "Ground", "Shell", "Status", "Charts", "Sides", "Entity families", "Radii and shadows")
      expect(panel.css("[data-side]").map { |sample| sample["data-side"] }).to contain_exactly("play", "feed", "mod", "admin")
      expect(panel.at_css('[data-entity="organization_affiliation"]')).to be_present
    end
  end
end
