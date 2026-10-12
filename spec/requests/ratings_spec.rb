require 'rails_helper'

RSpec.describe "Ratings", type: :request do
  let(:ace) { create(:ace) }
  let(:player) { create(:player) }
  let(:spectrum) { create(:spectrum) }

  before { sign_in ace }

  describe "POST /players/:player_id/ratings" do
    it "rates the player from the URL using the form's fields" do
      post player_ratings_path(player), params: { rating: { spectrum_id: spectrum.id, value: 500, notes: "Solid" } }

      expect(response).to redirect_to(player_path(player))
      rating = ace.ratings.active.sole
      expect(rating).to have_attributes(target: player, spectrum: spectrum, value: 500, notes: "Solid")
    end

    it "ignores a target smuggled in through the params" do
      post player_ratings_path(player), params: { rating: { spectrum_id: spectrum.id, value: 500, target_type: "Ace", target_id: ace.id } }

      expect(ace.ratings.active.sole.target).to eq(player)
    end

    it "archives the previous rating on the same spectrum" do
      post player_ratings_path(player), params: { rating: { spectrum_id: spectrum.id, value: 100 } }
      post player_ratings_path(player), params: { rating: { spectrum_id: spectrum.id, value: 900 } }

      expect(ace.ratings.active.pluck(:value)).to eq([900])
      expect(ace.ratings.archived.pluck(:value)).to eq([100])
    end

    it "answers the slider's JSON requests" do
      post player_ratings_path(player), params: { rating: { spectrum_id: spectrum.id, value: 300 } }, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("rating", "value")).to eq(300)
    end

    it "shows validation errors instead of exception messages" do
      post player_ratings_path(player), params: { rating: { spectrum_id: spectrum.id, value: 99_999 } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to eq(["Value must be less than or equal to 10000"])
    end

    it "re-renders the form when the rating is invalid" do
      post player_ratings_path(player), params: { rating: { spectrum_id: spectrum.id, value: 99_999 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(ace.ratings).to be_empty
    end
  end

  describe "PATCH /ratings/:id" do
    let!(:rating) { create(:rating, ace: ace, target: player, spectrum: spectrum, value: 100) }

    it "replaces the rating, keeping its target and spectrum" do
      patch rating_path(rating), params: { rating: { spectrum_id: spectrum.id, value: 700 } }

      expect(response).to redirect_to(player_path(player))
      expect(rating.reload).to be_archived
      expect(ace.ratings.active.sole).to have_attributes(target: player, spectrum: spectrum, value: 700)
    end

    it "keeps the original rating when the new value is invalid" do
      patch rating_path(rating), params: { rating: { spectrum_id: spectrum.id, value: 99_999 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(rating.reload).not_to be_archived
      expect(ace.ratings.count).to eq(1)
    end

    it "doesn't let aces change other aces' ratings" do
      someone_elses = create(:rating, target: player, spectrum: spectrum, value: 100)

      patch rating_path(someone_elses), params: { rating: { value: 700 } }

      expect(response).to redirect_to(ratings_path)
      expect(someone_elses.reload.value).to eq(100)
      expect(someone_elses).not_to be_archived
    end
  end
end
