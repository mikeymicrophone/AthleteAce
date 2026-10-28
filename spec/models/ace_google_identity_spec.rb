require "rails_helper"

RSpec.describe "Google account identity" do
  it "enforces unique Google identities even when model validation is bypassed" do
    create(:ace, google_uid: "123456789")
    another = create(:ace)
    expect {
      Ace.transaction(requires_new: true) { another.update_columns(google_uid: "123456789") }
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "rejects a missing identity or a verified email claim from another provider" do
    expect { Ace.from_google(nil) }.to raise_error(Ace::GoogleAuthenticationError)
    auth = OmniAuth::AuthHash.new(provider: "github", uid: "123456789", info: { email: "tess@gmail.com", email_verified: true })
    expect { Ace.from_google(auth) }.to raise_error(Ace::GoogleAuthenticationError)
  end
end
