# README

## Local accounts

In development, registration on a host ending in `.test` confirms the account immediately without a confirmation email. Signing in on that host also confirms an existing unconfirmed account after a correct password and retains the saved return page.

Other hosts and environments require the normal email confirmation flow.

Registration asks for a handle and display name. Handles use 3–24 letters, numbers, or underscores, are stored in lowercase, and are unique without regard to case. System names such as `admin`, `moderator`, and `athleteace` are reserved. Handles stay fixed after selection. Display names can change and have a 60-character limit.

Existing accounts choose a handle and display name after their next sign-in, then return to their saved destination. An already signed-in account without a handle also completes this setup before using the app. Sign-out, account security settings, and appearance controls remain accessible during setup.

Open **Profile** in the account menu to view or edit your display name and initials-avatar color. Public attribution and moderation views show the name and handle, with a generic Ace label for older accounts that have not completed setup. Email remains in private account settings. Photo uploads are not included.

## Navigation and appearance

The root opens Feed for visitors and Play for signed-in fans. Moderators and admins return to their last side in the current session. Their first visit opens Moderate or Admin. A saved return page takes precedence after sign-in.

Switch sides in the dark top bar. Play has Home, Games, Quests, History, and Browse tabs. Moderate and Admin use a sidebar on desktop. On mobile, navigation within each side moves to the bottom of the screen. Shared player, team, place, quest, and catalog pages keep the side you arrived from. Browse replaces the old table dropdowns and retains their catalog links.

The Moderate badge counts pending submissions that the reviewer can decide, excluding their own. Open the account button for Profile, My ratings, Settings, Begin Quest, Sign Out, and Light, Dark, or System appearance. Appearance is stored on the signed-in account. Visitors can use the Appearance button, which stores the choice in a cookie.

Feed shows approved shout-outs in bid-weighted order, plus the current ace's own funded posts in review. My teams shows a private, paginated team list from your follows and high Affinity ratings, with sport/league filters and practice links. [Private shout-out drafts](docs/shout-out-drafts.md) support target search, message previews, saving, editing, and deletion. [Stripe and credit payments](docs/shout-out-payments.md) support custom bids, credit purchases, review reservations, and refunds to credit after rejection or removal. Stripe keys and a signed webhook must be configured before checkout is available. [Team walls, private reports, and the admin revenue dashboard](docs/shout-out-operations.md) are available. [Free reactions, weekly leaderboards and live-post search](docs/feed-engagement.md) are available. All and My teams support sport/league filters and live approval/removal updates, preserving each visitor's filters and weighted order. The [moderation decision log](docs/moderation-operations.md#read-and-export-decision-history) supports date, type, actor and action filters, event totals and CSV export. The [Admin overview](docs/admin-overview.md) shows recorded daily cash purchases, new accounts, review events, visible open escalations, and application totals. Admin also provides People, revenue, editable player/team data, and other sports/content catalog links. Existing content editors keep their current permission rules. The shell omits navigation to unfinished workflows.

## Search

Open the search control or press Command+K or Control+K. Enter at least two characters, use the arrow keys to choose a result, Enter to open it, and Escape to close. Player search includes full names and nicknames. Team search includes territory, club name, and abbreviation, using the same matching as the round scope picker. Search input is limited to 80 characters and wildcard characters are treated literally. Each record group shows at most five matches.

Play searches players, teams, sports, leagues, conferences, divisions, and places. Feed searches players, teams and live shout-outs, including public author names and handles. Moderate searches pending submissions that the reviewer can decide, plus account handles and display names. Admin adds account identities, Organizations, and existing settings destinations to the public catalog search. Search never grants access to a side the account cannot use and does not search account emails.

Moderators and admins can open a matching ace's identity, recent submissions, reports and posting history. [Warnings, timed posting mutes and private moderator notes](docs/posting-moderation.md) are available, with a private Posting status page for the ace. [Escalations](docs/moderation-escalations.md) hand content and account cases to another admin. [Admin People](docs/admin-people.md) provides account search, audited role changes, suspension/reactivation, sign-in events and queued password-reset requests. [Admin Sports data](docs/admin-sports-data.md) provides searchable player/team tables, immediate edits, follow-up reasons, and a JSONL correction log for manual seed maintenance.

The five most recently opened or submitted searches are stored in the browser, separately for each account and side. Use **Clear recent searches** to remove them. Search results are fetched anew and are not stored in this history. The search control also links to a full search page when JavaScript is unavailable.

See [Play rounds and learning progress](docs/play-learning.md) for the six saved games, due reviews, roster-based quest completion, time zones, anonymous preview, and production mail configuration.

Sporting [competitions, games and titles](docs/competition-games.md) support league seasons, playoffs, cross-league cups, JSONB format rules, shared fixtures and separate title awards. These sporting Games are distinct from Play's quiz rounds. Player appearance ingestion remains follow-up work.

The committed development configuration uses `athlete_ace_development_seedtest_20261005`. Other checkouts must create that database or adjust their local database configuration.

Before upgrading a database with existing Contracts, follow the [organization reconciliation requirements](docs/roster-history-proposal.md#contract-transition). The second Contract migration refuses records without a verified Organization. The development seed-test database had no legacy Contracts when this transition was applied.

Apply the pending migrations, including account theme, identity, Play reviews, quest roster progress, and player groups, before running this version:

```sh
mise exec -- ruby -S bundle exec rails db:migrate
```

A nonzero exit means a migration failed. These migrations add account preferences, identity, review schedules, round learning results, quest roster snapshots, and curated player groups without changing account roles. Existing handles remain unset until each ace chooses one.

Build the stylesheet before browser checks:

```sh
mise exec -- ruby -S bundle exec rails tailwindcss:build
```

A nonzero exit means the stylesheet build failed.

Run the shell and authentication acceptance checks:

```sh
mise exec -- ruby -S bundle exec rspec spec/models/ace_identity_spec.rb spec/requests/profiles_spec.rb spec/requests/account_flow_spec.rb spec/requests/local_confirmation_spec.rb spec/requests/shell_spec.rb spec/system/ace_profiles_spec.rb spec/system/navigation_spec.rb spec/system/account_and_history_spec.rb
```

A nonzero exit, any failed example, or zero examples means the check failed.

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
