require "rails_helper"

RSpec.describe "Stripe payments and credit wallet", type: :request do
  let(:ace) { create(:ace) }
  let(:secret) { "whsec_athleteace_fixture" }

  before do
    @stripe_env = %w[STRIPE_SECRET_KEY STRIPE_WEBHOOK_SECRET].to_h { |key| [ key, ENV[key] ] }
    ENV["STRIPE_SECRET_KEY"] = "sk_test_athleteace_fixture"
    ENV["STRIPE_WEBHOOK_SECRET"] = secret
  end

  after { @stripe_env.each { |key, value| value ? ENV[key] = value : ENV.delete(key) } }

  def webhook(purchase, type: "checkout.session.completed", livemode: false, **changes)
    data = { id: "evt_#{SecureRandom.hex(8)}", type: type, livemode: livemode,
      data: { object: paid_session(purchase, **changes) } }.to_json
    timestamp = Time.current.to_i
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{data}")
    post stripe_webhook_path, params: data, headers: { "CONTENT_TYPE" => "application/json", "Stripe-Signature" => "t=#{timestamp},v1=#{signature}" }
  end

  it "keeps financial accounts signed in when ordinary deletion is refused" do
    buy_credit(ace, amount: 100)
    draft = ace.shout_out_drafts.create!(target: create(:player), message: "What a finish!")
    sign_in ace

    expect { delete ace_registration_path }.not_to change(Ace, :count)
    expect(response).to redirect_to(edit_ace_registration_path)
    expect(flash[:alert]).to include("financial records")
    expect(ShoutOutDraft.exists?(draft.id)).to be(true)
    get wallet_path
    expect(response).to have_http_status(:ok)
  end

  it "still deletes accounts without financial records" do
    sign_in ace

    expect { delete ace_registration_path }.to change(Ace, :count).by(-1)
    expect(flash[:notice]).to include("cancelled")
    get wallet_path
    expect(response).to redirect_to(new_ace_session_path)
  end

  it "requires a matching signed paid USD session and fulfills repeated events exactly once" do
    purchase = ace.stripe_purchases.create!(amount_cents: 1234, request_key: SecureRandom.uuid)
    webhook(purchase, payment_status: "unpaid")
    expect(response).to have_http_status(:ok)
    expect(CreditEntry.count).to eq(0)
    webhook(purchase, amount_total: 1200)
    expect(response).to have_http_status(:unprocessable_content)
    expect(CreditEntry.count).to eq(0)
    webhook(purchase, currency: "eur")
    expect(response).to have_http_status(:unprocessable_content)
    2.times { webhook(purchase) }
    expect(response).to have_http_status(:ok)
    expect(CreditAccount.for(ace).available_cents).to eq(1234)
    expect(CreditEntry.count).to eq(1)
  end

  it "rejects forged signatures and mismatched purchasers without granting credit" do
    purchase = ace.stripe_purchases.create!(amount_cents: 500, request_key: SecureRandom.uuid)
    post stripe_webhook_path, params: "{}", headers: { "CONTENT_TYPE" => "application/json", "Stripe-Signature" => "fake" }
    expect(response).to have_http_status(:bad_request)
    webhook(purchase, metadata: { "athleteace_purchase_id" => purchase.id.to_s, "ace_id" => create(:ace).id.to_s })
    expect(response).to have_http_status(:unprocessable_content)
    expect(CreditEntry.count).to eq(0)
  end

  it "rejects a signed live event when the app uses a test key" do
    purchase = ace.stripe_purchases.create!(amount_cents: 500, request_key: SecureRandom.uuid)
    webhook(purchase, livemode: true)
    expect(response).to have_http_status(:bad_request)
    expect(CreditEntry.count).to eq(0)
  end

  it "lets verified payment win over expiry regardless of delivery order" do
    purchase = ace.stripe_purchases.create!(amount_cents: 500, request_key: SecureRandom.uuid)
    purchase.update!(stripe_session_id: paid_session(purchase).fetch("id"))
    webhook(purchase, type: "checkout.session.expired")
    expect(purchase.reload.status).to eq("expired")
    webhook(purchase)
    expect(purchase.reload.status).to eq("paid")
    webhook(purchase, type: "checkout.session.expired")
    expect(purchase.reload.status).to eq("paid")
    expect(CreditAccount.for(ace).available_cents).to eq(500)
    expect(CreditEntry.count).to eq(1)
  end

  it "uses server amounts and idempotency keys, resumes existing sessions and never credits a return URL" do
    client = Stripe::StripeClient.new("sk_test_athleteace_fixture")
    sessions = client.v1.checkout.sessions
    result = Stripe::Checkout::Session.construct_from(id: "cs_fixture", url: "https://checkout.stripe.com/c/pay/fixture", status: "open")
    allow(Stripe::StripeClient).to receive(:new).and_return(client)
    expect(sessions).to receive(:create).once.with(hash_including(mode: "payment", line_items: [ { quantity: 1,
      price_data: { currency: "usd", unit_amount: 1234, product_data: { name: "AthleteAce credit" } } } ]),
      hash_including(:idempotency_key)).and_return(result)
    expect(sessions).to receive(:retrieve).with("cs_fixture").and_return(result)
    sign_in ace
    key = SecureRandom.uuid
    2.times do
      post wallet_path, params: { amount: "12.34", request_key: key, ace_id: create(:ace).id, amount_cents: 1, status: "paid" }
      expect(response).to redirect_to("https://checkout.stripe.com/c/pay/fixture")
    end
    expect(ace.stripe_purchases.count).to eq(1)
    purchase = ace.stripe_purchases.sole
    get stripe_purchase_path(purchase), params: { status: "paid" }
    expect(response.body).to include("Awaiting payment confirmation")
    expect(CreditEntry.count).to eq(0)
    expect(purchase.reload.status).to eq("pending")
  end

  it "keeps balances, purchases and checkout retries private" do
    purchase = create(:ace).stripe_purchases.create!(amount_cents: 500, request_key: SecureRandom.uuid)
    get wallet_path
    expect(response).to redirect_to(new_ace_session_path)
    sign_in ace
    get stripe_purchase_path(purchase)
    expect(response).to have_http_status(:not_found)
    sign_in ace
    post pay_stripe_purchase_path(purchase)
    expect(response).to have_http_status(:not_found)
    sign_in ace
    get wallet_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Available: $0.00", "Processing fees do not reduce")
    expect(response.headers["Cache-Control"]).to include("no-store")
  end

  it "validates top-up boundaries and refuses unconfigured checkout without minting credit" do
    sign_in ace
    %w[0.49 -1 1.001 1000000].each do |amount|
      post wallet_path, params: { amount: amount, request_key: SecureRandom.uuid }
      expect(response).to redirect_to(wallet_path)
    end
    ENV.delete("STRIPE_SECRET_KEY")
    post wallet_path, params: { amount: "10", request_key: SecureRandom.uuid }
    expect(response).to redirect_to(wallet_path)
    expect(CreditEntry.count).to eq(0)
    get wallet_path
    expect(Nokogiri::HTML(response.body).at_css('input[type="submit"][value="Buy credit with Stripe"]')["disabled"]).to be_present
  end
end
