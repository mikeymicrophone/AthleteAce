require 'rails_helper'

RSpec.describe "Authorization for shared content", type: :request do
  let(:ace) { create(:ace) }
  let(:admin) { create(:ace, :admin) }
  let!(:quest) { create(:quest) }
  let!(:spectrum) { create(:spectrum) }

  context "when signed out" do
    it "redirects quest creation to sign in" do
      expect {
        post quests_path, params: { quest: { name: "Sneaky" } }
      }.not_to change(Quest, :count)
      expect(response).to redirect_to(new_ace_session_path)
    end

    it "redirects achievement creation to sign in" do
      expect {
        post achievements_path, params: { achievement: { name: "Sneaky", target_type: "Sport", target_id: 1 } }
      }.not_to change(Achievement, :count)
      expect(response).to redirect_to(new_ace_session_path)
    end

    it "redirects quest deletion to sign in" do
      expect { delete quest_path(quest) }.not_to change(Quest, :count)
      expect(response).to redirect_to(new_ace_session_path)
    end
  end

  context "when signed in as a regular ace" do
    before { sign_in ace }

    it "can create quests" do
      expect {
        post quests_path, params: { quest: { name: "My Quest" } }
      }.to change(Quest, :count).by(1)
    end

    it "can create spectrums" do
      expect {
        post spectrums_path, params: { spectrum: { name: "Hustle", low_label: "Low", high_label: "High" } }
      }.to change(Spectrum, :count).by(1)
    end

    it "cannot update or delete quests" do
      patch quest_path(quest), params: { quest: { name: "Renamed" } }
      expect(response).to have_http_status(:see_other)
      expect(quest.reload.name).not_to eq("Renamed")

      expect { delete quest_path(quest) }.not_to change(Quest, :count)
    end

    it "cannot delete spectrums" do
      expect { delete spectrum_path(spectrum) }.not_to change(Spectrum, :count)
      expect(flash[:alert]).to eq("Only admins can do that.")
    end

    it "cannot remove achievements from quests" do
      highlight = create(:highlight, quest: quest)
      expect { delete quest_highlight_path(quest, highlight) }.not_to change(Highlight, :count)
    end

    it "gets a 403 for JSON requests" do
      delete quest_path(quest, format: :json)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when signed in as an admin" do
    before { sign_in admin }

    it "can update and delete quests" do
      patch quest_path(quest), params: { quest: { name: "Renamed" } }
      expect(quest.reload.name).to eq("Renamed")

      expect { delete quest_path(quest) }.to change(Quest, :count).by(-1)
    end

    it "can delete spectrums" do
      expect { delete spectrum_path(spectrum) }.to change(Spectrum, :count).by(-1)
    end
  end

  describe "quest creators" do
    let(:own_quest) { create(:quest, creator: ace) }

    before { sign_in ace }

    it "are recorded when a quest is created" do
      post quests_path, params: { quest: { name: "My Quest" } }
      expect(Quest.find_by!(name: "My Quest").creator).to eq(ace)
    end

    it "can't be set from params" do
      post quests_path, params: { quest: { name: "Spoofed", creator_id: admin.id } }
      expect(Quest.find_by!(name: "Spoofed").creator).to eq(ace)
    end

    it "can update and delete their own quests" do
      patch quest_path(own_quest), params: { quest: { name: "Renamed" } }
      expect(own_quest.reload.name).to eq("Renamed")

      expect { delete quest_path(own_quest) }.to change(Quest, :count).by(-1)
    end

    it "can manage achievements on their own quests" do
      highlight = create(:highlight, quest: own_quest)
      patch quest_highlight_path(own_quest, highlight), params: { highlight: { position: 3 } }
      expect(highlight.reload.position).to eq(3)

      expect { delete quest_highlight_path(own_quest, highlight) }.to change(Highlight, :count).by(-1)
    end

    it "can't change quests someone else created" do
      someone_elses = create(:quest, creator: create(:ace))

      patch quest_path(someone_elses), params: { quest: { name: "Renamed" } }
      expect(someone_elses.reload.name).not_to eq("Renamed")
      expect(flash[:alert]).to eq("Only its creator or an admin can do that.")
    end

    it "see edit controls only on their own quests" do
      someone_elses = create(:quest, creator: create(:ace))

      get quest_path(own_quest)
      expect(response.body).to include(edit_quest_path(own_quest), "You created this quest")

      get quest_path(someone_elses)
      expect(response.body).not_to include(edit_quest_path(someone_elses), "You created this quest")
    end
  end

  describe "admin-only controls" do
    let!(:highlight) { create(:highlight, quest: quest) }

    it "are hidden from regular aces" do
      sign_in ace
      get quest_path(quest)
      expect(response.body).not_to include(edit_quest_highlight_path(quest, highlight))
      get spectrum_path(spectrum)
      expect(response.body).not_to include(edit_spectrum_path(spectrum))
    end

    it "are shown to admins" do
      sign_in admin
      get quest_path(quest)
      expect(response.body).to include(edit_quest_highlight_path(quest, highlight))
      get spectrum_path(spectrum)
      expect(response.body).to include(edit_spectrum_path(spectrum))
    end
  end

  describe "GET /achievements/target_options" do
    before { sign_in ace }

    it "returns options for allowed target types" do
      sport = create(:sport)
      get target_options_achievements_path, params: { type: "Sport" }
      expect(response.parsed_body).to include({ "id" => sport.id, "name" => sport.name })
    end

    it "returns nothing for other classes" do
      %w[Ace Rating Kernel NoSuchThing].each do |type|
        get target_options_achievements_path, params: { type: type }
        expect(response.parsed_body).to eq([])
      end
    end

    it "returns nothing without a type" do
      get target_options_achievements_path
      expect(response.parsed_body).to eq([])
    end
  end

  describe "GET /players?sort=" do
    it "ignores SQL in sort params" do
      queries = []
      record_query = ->(*, payload) { queries << payload[:sql] }
      ActiveSupport::Notifications.subscribed(record_query, "sql.active_record") do
        get players_path, params: { sort: "first_name asc,id/**/+(select/**/count(*)/**/from/**/aces) asc" }
      end

      expect(response).to have_http_status(:success)
      expect(queries.grep(/ORDER BY players\.first_name ASC/)).not_to be_empty
      expect(queries.grep(%r{from/\*\*/aces})).to be_empty
    end
  end
end
