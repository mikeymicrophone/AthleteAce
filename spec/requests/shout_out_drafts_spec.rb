require "rails_helper"

RSpec.describe "Private shout-out drafts", type: :request do
  let(:ace) { create(:ace) }
  let(:player) { create(:player, first_name: "Jalen", last_name: "Brunson") }
  let(:attributes) { { target_type: "Player", target_id: player.id, message: "What a finish! 👏" } }

  it "requires sign-in for drafts and target searches" do
    get new_shout_out_draft_path, params: { target_type: "Player", target_id: player.id }
    expect(response).to redirect_to(new_ace_session_path)
    destination = URI.parse(request.session["ace_return_to"])
    expect(destination.path).to eq(new_shout_out_draft_path)
    expect(Rack::Utils.parse_nested_query(destination.query)).to eq("target_type" => "Player", "target_id" => player.id.to_s)
    get targets_shout_out_drafts_path, params: { q: "Brunson" }
    expect(response).to redirect_to(new_ace_session_path)
    expect { post shout_out_drafts_path, params: { shout_out_draft: attributes } }.not_to change(ShoutOutDraft, :count)
  end

  it "saves a private owned draft and ignores publication, tier and payment fields" do
    sign_in ace
    expect {
      post shout_out_drafts_path, params: { shout_out_draft: attributes.merge(ace_id: create(:ace).id, status: "live", price_cents: 100, tier: "pinned") }
    }.to change(ace.shout_out_drafts, :count).by(1)
    draft = ace.shout_out_drafts.sole
    expect(draft.target).to eq(player)
    expect(draft.message).to eq(attributes[:message])
    expect(response).to redirect_to(edit_shout_out_draft_path(draft))
    get edit_shout_out_draft_path(draft)
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
    expect(response.body).to include("Checkout and publication are not available yet", draft.message)
    expect(Nokogiri::HTML(response.body).at_css("body")["data-side"]).to eq("feed")
    sign_out ace
    get feed_path
    expect(response.body).not_to include(draft.message)
  end

  it "does not expose or mutate another account's drafts" do
    foreign = create(:ace).shout_out_drafts.create!(target: player, message: "An unforgettable performance")
    sign_in ace
    get shout_out_drafts_path, params: { ace_id: foreign.ace_id }
    expect(response.body).not_to include(foreign.message)
    get edit_shout_out_draft_path(foreign)
    expect(response).to have_http_status(:not_found)
    sign_in ace
    patch shout_out_draft_path(foreign), params: { shout_out_draft: attributes }
    expect(response).to have_http_status(:not_found)
    expect(foreign.reload.message).to eq("An unforgettable performance")
    sign_in ace
    expect { delete shout_out_draft_path(foreign) }.not_to change(ShoutOutDraft, :count)
    expect(response).to have_http_status(:not_found)
  end

  it "validates missing or unsupported targets, blank text, Unicode length and web addresses on the server" do
    sign_in ace
    invalid = [ attributes.merge(target_type: "Ace", target_id: ace.id), attributes.merge(target_id: -1),
      attributes.merge(message: " "), attributes.merge(message: "👏" * 201), attributes.merge(message: "Watch https://example.com"),
      attributes.merge(message: "Try www.example.com"), attributes.merge(message: "Visit example.org/highlights") ]
    invalid.each do |values|
      expect { post shout_out_drafts_path, params: { shout_out_draft: values } }.not_to change(ShoutOutDraft, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
    post shout_out_drafts_path, params: { shout_out_draft: attributes.merge(message: "👏" * 200) }
    expect(response).to have_http_status(:see_other)
    expect(ace.shout_out_drafts.reload.sole.message.length).to eq(200)
  end

  it "trims Unicode whitespace before enforcing the server's character limit" do
    sign_in ace
    text = "\u00A0#{'👏' * 200}\u00A0"
    post shout_out_drafts_path, params: { shout_out_draft: attributes.merge(message: text) }
    expect(response).to have_http_status(:see_other)
    expect(ace.shout_out_drafts.reload.sole.message).to eq("👏" * 200)
  end

  it "updates and deletes its own draft and rejects stale edits" do
    draft = ace.shout_out_drafts.create!(target: player, message: "Great finish")
    sign_in ace
    patch shout_out_draft_path(draft), params: { shout_out_draft: attributes.merge(lock_version: 0) }
    expect(response).to redirect_to(edit_shout_out_draft_path(draft))
    expect(draft.reload.message).to eq(attributes[:message])
    patch shout_out_draft_path(draft), params: { shout_out_draft: attributes.merge(lock_version: 0, message: "Older tab") }
    expect(response).to have_http_status(:conflict)
    expect(draft.reload.message).to eq(attributes[:message])
    expect { delete shout_out_draft_path(draft) }.to change(ShoutOutDraft, :count).by(-1)
    expect(response).to redirect_to(shout_out_drafts_path)
  end

  it "retains message text after a target is deleted and requires a replacement before saving" do
    draft = ace.shout_out_drafts.create!(target: player, message: "A memorable night")
    player.destroy!
    sign_in ace
    get shout_out_drafts_path
    expect(response.body).to include("Target no longer available", "A memorable night")
    get edit_shout_out_draft_path(draft)
    expect(response).to have_http_status(:ok)
    patch shout_out_draft_path(draft), params: { shout_out_draft: { message: "A memorable night" } }
    expect(response).to have_http_status(:unprocessable_content)
    team = create(:team)
    patch shout_out_draft_path(draft), params: { shout_out_draft: { message: "A memorable night", target_type: "Team", target_id: team.id } }
    expect(response).to have_http_status(:see_other)
    expect(draft.reload.target).to eq(team)
  end

  it "searches only public player and team identities with bounded literal matching" do
    player
    team = create(:team, territory: "New York", mascot: "Knicks", abbreviation: "NYK")
    sign_in ace
    get targets_shout_out_drafts_path, params: { q: "Brunson" }
    expect(response.body).to include("Choose Jalen Brunson", 'data-target-type="Player"')
    get targets_shout_out_drafts_path, params: { q: "NYK" }
    expect(response.body).to include("Choose #{team.name}", 'data-target-type="Team"')
    get targets_shout_out_drafts_path, params: { q: "%_" }
    expect(response.body).to include("No matching players or teams")
    get targets_shout_out_drafts_path, params: { q: "B" }
    expect(response.body).to include("Enter at least 2 characters")
  end

  it "escapes draft text in preview and paginates only the owner's list" do
    sign_in ace
    6.times { |i| ace.shout_out_drafts.create!(target: player, message: "Great finish #{i}") }
    draft = ace.shout_out_drafts.last
    draft.update!(message: "<script>alert(1)</script>")
    get edit_shout_out_draft_path(draft)
    expect(response.body).to include("&lt;script&gt;alert(1)&lt;/script&gt;")
    expect(response.body).not_to include("<script>alert(1)</script>")
    get shout_out_drafts_path
    doc = Nokogiri::HTML(response.body)
    expect(doc.css(".draft-card").size).to eq(5)
    expect(response.body).to include("page=2")
    ace.destroy!
    expect(ShoutOutDraft.count).to eq(0)
  end
end
