# README

## Local accounts

In development, registration on a host ending in `.test` confirms the account immediately without a confirmation email. Signing in on that host also confirms an existing unconfirmed account after a correct password and retains the saved return page.

Other hosts and environments require the normal email confirmation flow.

## Navigation and appearance

The root opens Feed for visitors and Play for signed-in fans. Moderators and admins return to their last side in the current session. Their first visit opens Moderate or Admin. A saved return page takes precedence after sign-in.

Switch sides in the dark top bar. Play has Home, Games, Quests, History, and Browse tabs. Moderate and Admin use a sidebar on desktop. On mobile, navigation within each side moves to the bottom of the screen. Shared player, team, place, quest, and catalog pages keep the side you arrived from. Browse replaces the old table dropdowns and retains their catalog links.

The Moderate badge counts pending submissions that the reviewer can decide, excluding their own. Open the account button for My ratings, Settings, Begin Quest, Sign Out, and Light, Dark, or System appearance. Appearance is stored on the signed-in account. Visitors can use the Appearance button, which stores the choice in a cookie.

Feed currently has an empty reading view and player/team browsing. Posting, follows, leaderboards, payments, and reports remain unfinished. Admin currently provides application totals and sports/content catalog links. Existing content editors keep their current permission rules. The shell omits navigation to unfinished workflows. Contextual search is separate work.

Apply the account-theme migration before running this version:

```sh
mise exec -- ruby -S bundle exec rails db:migrate
```

A nonzero exit means the migration failed. The migration adds the theme preference without changing account roles.

Build the stylesheet before browser checks:

```sh
mise exec -- ruby -S bundle exec rails tailwindcss:build
```

A nonzero exit means the stylesheet build failed.

Run the shell and authentication acceptance checks:

```sh
mise exec -- ruby -S bundle exec rspec spec/requests/shell_spec.rb spec/requests/local_confirmation_spec.rb spec/system/navigation_spec.rb spec/system/account_and_history_spec.rb
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
