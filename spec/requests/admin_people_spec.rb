require "rails_helper"

RSpec.describe "Admin people", type: :request do
  let(:admin) { create(:ace, :admin) }
  let(:ace) { create(:ace, username: "wrigley_wes", display_name: "Wes Miller") }

  def change_account(action: "role", role: "moderator", **changes)
    patch admin_person_path(ace), params: { account_action: action, role: role, reason: "Roster review responsibilities",
      current_password: "password123", request_key: SecureRandom.uuid, version: ace.reload.account_version }.merge(changes)
  end

  it "limits private account/email/activity access and actions to admins" do
    get admin_people_path
    expect(response).to redirect_to(new_ace_session_path)
    [ create(:ace), create(:ace, moderator: true) ].each do |viewer|
      sign_in viewer
      get admin_people_path
      expect(response).to have_http_status(:see_other)
      get admin_person_path(ace)
      expect(response.body).not_to include(ace.email)
      change_account
      expect(ace.reload).not_to be_moderator
    end
    sign_in admin
    get admin_person_path(ace)
    expect(response).to have_http_status(:ok)
    expect(response.headers['Cache-Control']).to include('private', 'no-store')
    expect(response.body).to include(ace.email)
    expect(response.body).not_to include(ace.encrypted_password)
  end

  it "filters by identity, role, mutually exclusive status and inclusive joined dates" do
    sign_in admin
    ace.update!(created_at: Time.zone.local(2026, 1, 20, 12))
    ace.warnings.create!(moderator: admin, reason: 'Keep it relevant', request_key: SecureRandom.uuid)
    get admin_people_path(q: 'WRIGLEY', role: 'fan', status: 'warned', joined_from: '2026-01-20', joined_to: '2026-01-20')
    expect(response.body).to include('Wes Miller', ace.email)
    get admin_people_path(q: '@wrigley_wes')
    expect(response.body).to include(ace.email)
    get admin_people_path(q: 'WRIGLEY', status: 'active')
    expect(response.body).not_to include(ace.email)
    ace.mutes.create!(moderator: admin, reason: 'Pause posting', request_key: SecureRandom.uuid, starts_at: 1.hour.ago, ends_at: 23.hours.from_now, duration_hours: 24)
    get admin_people_path(q: 'WRIGLEY', status: 'muted')
    expect(response.body).to include(ace.email)
    ace.update!(suspended_at: Time.current)
    get admin_people_path(q: 'WRIGLEY', status: 'muted')
    expect(response.body).not_to include(ace.email)
    get admin_people_path(q: 'WRIGLEY', status: 'suspended')
    expect(response.body).to include(ace.email)
    get admin_people_path(q: '%')
    expect(response.body).not_to include(ace.email)
    get admin_people_path(role: "forged")
    expect(response).to have_http_status(:bad_request)
    get admin_people_path(joined_from: [ '2026-01-01' ])
    expect(response).to have_http_status(:bad_request)
    get admin_people_path(joined_to: { date: '2026-01-01' })
    expect(response).to have_http_status(:bad_request)
    get admin_people_path(joined_from: 'bad')
    expect(response).to have_http_status(:bad_request)
    get admin_people_path(joined_from: '2026-02-01', joined_to: '2026-01-01')
    expect(response).to have_http_status(:bad_request)
  end

  it "records role grants and reversals once, rejects stale requests and requires the admin password" do
    sign_in admin
    change_account(current_password: 'wrong')
    expect(response).to have_http_status(:forbidden)
    expect(ace.reload.role).to eq('fan')
    key = SecureRandom.uuid
    2.times { change_account(request_key: key, version: 0) }
    expect(response).to have_http_status(:see_other)
    expect(ace.reload.role).to eq('moderator')
    expect(AccountAction.count).to eq(1)
    record = AccountAction.sole
    expect(record.actor).to eq(admin)
    expect(record.before_state).to eq('role' => 'fan', 'suspended' => false)
    expect(record.after_state).to eq('role' => 'moderator', 'suspended' => false)
    expect { record.update!(reason: 'Rewrite') }.to raise_error(ActiveRecord::ReadOnlyRecord)
    change_account(role: 'admin', version: 0)
    expect(response).to have_http_status(:conflict)
    change_account(request_key: key, role: 'admin')
    expect(response).to have_http_status(:conflict)
    change_account(role: 'admin')
    expect(response).to have_http_status(:see_other)
    expect(ace.reload.role).to eq('admin')
    change_account(role: 'fan')
    expect(response).to have_http_status(:see_other)
    expect(ace.reload.role).to eq('fan')
    expect(AccountAction.count).to eq(3)
    change_account(role: 'forged')
    expect(response).to have_http_status(:unprocessable_content)
    change_account(reason: 'x' * 2001)
    expect(response).to have_http_status(:unprocessable_content)
    get admin_person_path(ace)
    expect(response.body).to include('Roster review responsibilities')
    sign_in ace
    get profile_path
    expect(response.body).not_to include('Roster review responsibilities')
  end

  it "blocks self changes and the last admin's account deletion" do
    sign_in admin
    patch admin_person_path(admin), params: { account_action: 'suspend', reason: 'Self', current_password: 'password123', request_key: SecureRandom.uuid, version: 0 }
    expect(response).to have_http_status(:forbidden)
    expect(admin.reload).not_to be_suspended
    create(:ace, :admin, :unconfirmed)
    expect(admin.destroy).to be(false)
    expect(admin.errors.full_messages.join).to include('Keep at least one active admin')
    expect(Ace.exists?(admin.id)).to be(true)
    delete ace_registration_path
    expect(response).to redirect_to(edit_ace_registration_path)
    follow_redirect!
    expect(response.body).to include("Your account is the last active admin")
    expect(response.body).not_to include("Your account has financial records")
    expect(Ace.exists?(admin.id)).to be(true)
  end

  it "suspends without changing financial/content state and keeps payment settlement possible" do
    buy_credit(ace)
    post_record = submit_credit(ace: ace, target: create(:team), bid: 125)
    sign_in admin
    change_account(action: 'suspend')
    expect(response).to have_http_status(:see_other)
    expect(ace.reload).to be_suspended
    expect(ace).not_to be_active_for_authentication
    expect(post_record.reload.funding_status).to eq('reserved')
    expect(CreditAccount.for(ace).available_cents).to eq(875)
    expect { create(:quest, created_by: ace) }.to raise_error(Ace::AccountSuspended)
    review_post(post_record, action: 'approve')
    review_post(post_record, action: 'hide')
    expect(CreditAccount.for(ace).available_cents).to eq(1000)
    purchase = ace.stripe_purchases.create!(amount_cents: 50, request_key: SecureRandom.uuid)
    purchase.fulfill!(paid_session(purchase))
    expect(CreditAccount.for(ace).available_cents).to eq(1050)
    change_account(action: 'reactivate')
    expect(response).to have_http_status(:see_other)
    expect(ace.reload).to be_active_for_authentication
    expect(ace.session_version).to eq(1)
  end

  it "records real successful/failed logins and revokes an existing session across reactivation" do
    original_salt = ace.authenticatable_salt
    post ace_session_path, params: { ace: { email: ace.email, password: 'wrong' } }, headers: { 'HTTP_USER_AGENT' => 'Firefox/140.0' }
    expect(response).to have_http_status(:unprocessable_content)
    expect(SignInEvent.where(ace: ace).pluck(:outcome)).to eq([ 'failure' ])
    post ace_session_path, params: { ace: { email: ace.email, password: 'password123' } }
    expect(response).to have_http_status(:see_other)
    expect(SignInEvent.where(ace: ace).order(:id).pluck(:outcome)).to eq(%w[failure success])
    get profile_path
    expect(response).to have_http_status(:ok)
    Admin::ChangeAccount.call(ace: ace, actor: admin, action: 'suspend', reason: 'Review access', password: 'password123', request_key: SecureRandom.uuid, version: 0)
    Admin::ChangeAccount.call(ace: ace, actor: admin, action: 'reactivate', reason: 'Review complete', password: 'password123', request_key: SecureRandom.uuid, version: 1)
    expect(ace.reload.authenticatable_salt).not_to eq(original_salt)
    get profile_path
    expect(response).to redirect_to(new_ace_session_path)
    post ace_session_path, params: { ace: { email: ace.email, password: 'password123' } }
    expect(response).to have_http_status(:see_other)
    sign_out ace
    ace.update!(suspended_at: Time.current)
    post ace_session_path, params: { ace: { email: ace.email, password: 'password123' } }
    expect(response).to redirect_to(new_ace_session_path)
    follow_redirect!
    expect(response.body).to include('Your account is suspended')
    post ace_session_path, params: { ace: { email: 'unknown@example.test', password: 'wrong' } }
    expect(SignInEvent.count).to eq(4)
  end

  it "queues one password-reset request without recording passwords or changing suspension" do
    sign_in admin
    ace.update!(suspended_at: Time.current)
    key = SecureRandom.uuid
    expect { 2.times { change_account(action: 'password_reset', request_key: key, version: 0) } }.to have_enqueued_job(AdminPasswordResetJob).exactly(:once)
    record = AccountAction.sole
    expect(record.attributes.to_json).not_to include('password123')
    expect(ace.reload).to be_suspended
    expect { AdminPasswordResetJob.perform_now(record.id) }.to change { ActionMailer::Base.deliveries.size }.by(1)
    expect(ActionMailer::Base.deliveries.last.to).to eq([ ace.email ])
    expect(ace.reload.reset_password_token).to be_present
    expect(ace).to be_suspended
  end

  it "paginates stably and reports net captured credit without double-counting top-ups" do
    sign_in admin
    26.times { |index| create(:ace, display_name: "Roster Fan #{index}", created_at: Time.zone.local(2026, 1, 1)) }
    get admin_people_path(joined_from: '2026-01-01', joined_to: '2026-01-01')
    expect(Nokogiri::HTML(response.body).css('.people-table tbody tr').length).to eq(25)
    get admin_people_path(joined_from: '2026-01-01', joined_to: '2026-01-01', page: 2)
    expect(Nokogiri::HTML(response.body).css('.people-table tbody tr').length).to eq(1)
    buy_credit(ace)
    post_record = submit_credit(ace: ace, target: create(:team), bid: 175)
    review_post(post_record, action: 'approve')
    get admin_people_path(q: 'wrigley_wes')
    expect(response.body).to include('$1.75')
    review_post(post_record, action: 'hide')
    get admin_people_path(q: 'wrigley_wes')
    expect(response.body).to include('$0.00')
  end
end
