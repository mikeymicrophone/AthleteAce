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

RSpec.describe "Shared rating rows", type: :request do
  let(:ace) { create(:ace) }
  let(:player) { create(:player) }
  let(:spectrum) { create(:familiarity) }
  let(:stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  def document
    Nokogiri::HTML response.body
  end

  it "shows your own exact value and averages only active ratings" do
    sign_in ace
    create(:rating, ace: ace, target: player, spectrum: spectrum, value: 4300)
    create(:rating, target: player, spectrum: spectrum, value: 1700)
    create(:rating, target: player, spectrum: spectrum, value: -9000, archived: true)

    get player_path(player)

    expect(document.at_css(".rating-slider-input")["value"]).to eq("4300")
    expect(document.at_css(".slider-value").text).to eq("+4,300")
    expect(document.at_css(".rating-summary").text).to include("Aces average +3,000 · 2 ratings")
    expect(document.at_css(".average-marker")["style"]).to eq("left: 65.0%")
  end

  it "never shows another ace's rating as yours and distinguishes an unrated zero" do
    sign_in ace
    create(:rating, target: player, spectrum: spectrum, value: 8000)
    get player_path(player)
    expect(document.at_css(".slider-value").text).to eq("Not rated")
    expect(document.at_css(".rating-slider-instance")["data-rated"]).to eq("false")

    create(:rating, ace: ace, target: player, spectrum: spectrum, value: 0)
    get player_path(player)
    expect(document.at_css(".slider-value").text).to eq("0")
    expect(document.at_css(".rating-slider-instance")["data-rated"]).to eq("true")
  end

  it "replaces the row with the saved value and recomputed average without counting the archived version" do
    sign_in ace
    original = create(:rating, ace: ace, target: player, spectrum: spectrum, value: 1000)
    create(:rating, target: player, spectrum: spectrum, value: 3000)

    post player_ratings_path(player), params: { rating: { spectrum_id: spectrum.id, value: 5000 } }, headers: stream_headers

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(document.at_css("turbo-stream")["target"]).to eq("rating_spectrum_#{spectrum.id}_player_#{player.id}")
    expect(response.body).to include("+5,000", "Aces average +4,000 · 2 ratings", "Saved")
    expect(original.reload).to be_archived
  end

  it "returns public averages as read-only rows without exposing personal JSON ratings" do
    create(:rating, target: player, spectrum: spectrum, value: 2000)
    get for_spectrums_player_ratings_path(player), params: { spectrum_ids: spectrum.id.to_s }, headers: stream_headers

    expect(response).to have_http_status(:ok)
    expect(document.at_css("turbo-stream")["target"]).to eq("rating_rows_player_#{player.id}")
    expect(response.body).to include("Aces average +2,000 · 1 rating", "disabled", "Not rated")

    get for_spectrums_player_ratings_path(player), params: { spectrum_ids: spectrum.id.to_s }, as: :json
    expect(response.parsed_body).to eq("ratings" => {})
    post player_ratings_path(player), params: { rating: { spectrum_id: spectrum.id, value: 4000 } }
    expect(response).to redirect_to(new_ace_session_path)
    expect(player.ratings.active.count).to eq(1)
  end

  it "renders an empty selection rather than keeping obsolete rows" do
    sign_in ace
    get for_spectrums_player_ratings_path(player), params: { spectrum_ids: "" }, headers: stream_headers

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Select a spectrum")
    expect(response.body).not_to include("rating-slider-input")
  end
end
