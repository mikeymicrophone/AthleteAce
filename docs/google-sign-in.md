# Configure Google sign-in

AthleteAce supports Google alongside email and password. Google sign-in requires a web application OAuth client and two environment variables:

| Variable | Value |
| --- | --- |
| `GOOGLE_CLIENT_ID` | The Google web client's client ID |
| `GOOGLE_CLIENT_SECRET` | The same client's secret |

The sign-in and signup pages show **Continue with Google** only when both variables are present at application boot. Restart the server after changing them. The Rails callback is `/aces/auth/google_oauth2/callback`.

## Configure the development client

Use the existing Google Cloud project `athleteace`. In [Google Auth Platform Clients](https://console.cloud.google.com/auth/clients?project=athleteace), create a **Web application** client named `AthleteAce development` with these Authorized redirect URIs:

```text
http://localhost:3000/aces/auth/google_oauth2/callback
http://127.0.0.1:3000/aces/auth/google_oauth2/callback
https://ace.mikeymicrophone.fun/aces/auth/google_oauth2/callback
```

This server-side flow does not require Authorized JavaScript origins. Use localhost or [the development tunnel](https://ace.mikeymicrophone.fun/aces/sign_in) for Google sign-in. Google permits HTTP loopback callbacks, while ordinary redirect hosts must meet its [redirect URI validation rules](https://developers.google.com/identity/protocols/oauth2/web-server#uri-validation). The app's `.test` hostname is for the existing local password flow.

Store both values in the AthleteAce Doppler project's `dev` config. Keep the secret out of Git and chat. Run the app from the checkout:

```sh
mise exec -- bundle exec rails db:migrate tailwindcss:build
doppler run --project athleteace --config dev -- mise exec -- bundle exec rails server -b 127.0.0.1 -p 3000
```

Open [local sign-in](http://localhost:3000/aces/sign_in). A missing Google button means at least one variable was absent when this server booted. A `redirect_uri_mismatch` means the browser's exact scheme, host, port, and callback path must be checked against this client's Authorized redirect URIs. Register each deployed HTTPS origin's callback separately before enabling Google there.

The tunnel routes `ace.mikeymicrophone.fun` to the same puma-dev app as `athleteace.test`, preserving the public host and HTTPS. Its route is managed by MICharisma Local Apps, whose roster is `config/local_apps.json` in the MICharisma checkout. The Mac must be awake and online with the shared connector, puma-dev, and PostgreSQL running. Development error reports are disabled because this app is publicly reachable.

On this Mac, the ignored `.pumaenv` fetches `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` from Doppler `athleteace / dev` when puma-dev boots the app. It stores no credential values in the checkout and stops startup if retrieval fails. After changing either credential, use **Restart** on AthleteAce in MICharisma Local Apps, then **Google sign-in** to open the tunnel's sign-in page. Keep the Doppler CLI authenticated on the Mac. The controller manages the route and restart; puma-dev loads the credentials.

## Account behavior

Google's stable subject ID is stored as `Ace.google_uid`, with a unique database index. A returning bound ID signs into the same Ace even if Google reports a different email; the app does not change the Ace's email or public profile.

A verified matching email automatically links an existing unbound Ace, as selected for AthleteAce. Google's verified email also confirms that account. An unverified claim is rejected. A different Google ID cannot overwrite an existing binding, and suspended accounts cannot link or sign in.

A new Google user chooses a handle and display name on the existing signup form before the account is created. The pending session contains only the verified Google ID, email, and suggested name. The server supplies the email and ID during signup, ignores client-supplied identity or role fields, and generates a random password. The account is confirmed without another email challenge. **Use another account** clears the pending signup.

Email and password remain available. A Google-created account can use the existing password-reset flow to choose a password later. Existing linked accounts retain their current passwords. Successful Google sign-ins and completed Google signups use the existing `SignInEvent` audit.

The request phase uses POST with Rails CSRF verification and bypasses Turbo navigation. The callback keeps OmniAuth's state verification. Only email and profile scopes are requested, access is online, and Google access or refresh tokens are not stored in the Ace record or pending signup session. Authorization codes are filtered from request logs.

## Verify the integration

```sh
mise exec -- bundle exec rspec spec/requests/google_sign_in_spec.rb spec/requests/account_flow_spec.rb spec/models/ace_identity_spec.rb spec/models/ace_google_identity_spec.rb spec/requests/authorization_spec.rb
```

The run must execute a positive example count and report zero failures. These tests use OmniAuth's mock provider response while exercising the real request middleware, callback, session, signup form, account linking, suspension checks, and CSRF verifier. They do not prove that a live Google client has been configured.

After client setup, verify a real authorization redirect, complete Google sign-in, and check the intended Ace and saved destination. Keep this provider verification distinct from local mock-based tests. Changing deployed environment variables or releasing this code requires the usual explicit deployment authorization.
