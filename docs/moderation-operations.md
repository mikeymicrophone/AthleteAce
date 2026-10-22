# Review submissions and compare decision models

Run these commands from the AthleteAce repository, which contains `Gemfile` and `doppler.yaml`.

## Prepare the local app

Apply the migrations with the repository's Ruby version:

```sh
mise exec -- ruby -S bundle exec rails db:migrate
```

A nonzero exit means the migration failed. The migrations add approval states, creator references, reviewer roles, decision records, evaluation records, optimistic locking, and the timestamp/ID index for decision history. Existing content stays approved. New fan submissions enter review.

The Doppler project is `athleteace`, and the development config is `dev`. Add `TYPESAFE_API_KEY` and `OPENAI_API_KEY` there. Keep the values in Doppler, not this repository.

The web comparison reads the Rails process environment. Start Rails through Doppler to supply those keys:

```sh
doppler run --project athleteace --config dev -- mise exec -- ruby -S bundle exec rails server
```

For puma-dev on this Mac, `config/puma-dev.env.example` fetches the two keys from Doppler when the app starts. The file uses `/opt/homebrew/bin/doppler`. Adjust that path if Doppler is installed elsewhere.

If the app has no `.env`, install the startup file with:

```sh
cp -n config/puma-dev.env.example .env
```

A nonzero exit means the copy failed. If `.env` already exists, add the example's assignments and export line to it instead of replacing it. The file contains commands, not secret values, and Git ignores `.env`.

Restart only this app:

```sh
touch tmp/restart.txt
```

A nonzero exit means the restart request could not be written. Open a submission at `/moderate` after the restart. Both providers must show **Key configured** in **AI provider configuration**. **Key missing** means that the running Rails process lacks that key. A configured key does not prove a provider can answer. Click **Compare with AI** and inspect both recorded results or failures to verify access.

Puma-dev sources `.env` before starting Puma. See [Puma-dev's environment configuration](https://github.com/puma/puma-dev#advanced-configuration). The command-line comparison below loads Doppler directly.

## Review a submission

1. Sign in with an existing admin account or an ace with `moderator` enabled.
2. Open `/moderate`. The queue excludes your submissions and orders the oldest submissions first. Filter by status and content type. Type counts include all reviewable items with the selected status. The queue shows 25 items per page.
3. Open a submission. Inspect its current content and decision history. **Previous (K)** and **Next (J)** keep the status and type filters, including across queue pages.
4. Approve or reject a pending submission. Enter a reason when rejecting.

To hide approved content, open the **Approved** tab and give a reason. To reconsider rejected or hidden content, reopen the item before approving it. Refunded shout-outs cannot reopen. Their author must submit a newly funded draft version. Each action adds a decision record. Reviewers cannot decide their submissions or hide posts with their own open reports. The [reports inbox](shout-out-operations.md) supports Keep live and Hide, with mandatory full refunds as wallet credit. Concurrent or stale decisions return HTTP 409.

Use **Keyboard shortcuts ?** to show the available keys. On the queue, J and K focus rows, and Enter opens the focused review. On a review, J and K open the next and previous submissions. A approves a pending submission. R focuses the reason field without submitting a rejection. Shortcuts pause while you type in a field. After a decision, inspect the updated status and history, then choose **Next (J)** to continue.

The queue covers quests, achievements, highlights, spectrums, and funded shout-outs. Private shout-out drafts and unfunded posts stay outside the queue. Approving a shout-out spends its reserved credit, rejecting releases it, and hiding an approved post refunds its full bid as credit. See [shout-out payments](shout-out-payments.md) for the funding rules. Approve a highlight's quest and achievement before approving the highlight. Public goal requirements exclude unapproved highlights and achievements.

## Read and export decision history

Open **Decision log** from Moderate. **From (UTC)** and **Through (UTC)** select inclusive calendar dates. The default is the last 30 days through today. If you supply only the end date, the start defaults to 29 days earlier. Blank dates use these defaults. Future end dates, reversed ranges, invalid calendar dates and dates outside YYYY-MM-DD format return HTTP 400.

**Content type**, **Action** and **Recorded actor** intersect the date range. Actors include submitters as well as reviewers. **System or deleted account** selects records with no actor reference; it does not claim that every unattributed action was automated. Unsupported types, actions or account IDs return HTTP 400. **Apply filters** starts at the first page; **Clear filters** resets the default dates and removes the other selections.

The log shows 25 events per page, newest timestamp first, with descending event ID breaking ties. Pagination keeps every filter. It replaces the old latest-100 cutoff. Recorded names and reasons remain readable after content edits or deletion. Actor handles use the account's current identity while that account exists.

Totals cover every matching event, not just the current page. Approved events include trusted creation. Submitted events include resubmissions, and a post can have several events. These are event counts, not unique submissions, reviewer performance or approval percentages. The page and export exclude events dated later than the time the log is built. A later request can include newer events.

**Export CSV** downloads all matching events regardless of the current page. The limit is 10,000 events. An oversized export returns HTTP 400 with a request to narrow the filters, rather than dropping rows. An empty export contains its header only. The fields are event ID, UTC timestamp, subject type and ID, action, revision, previous and next status, actor ID and handle, recorded name and decision reason. It excludes account emails, report notes, provider evaluations, financial details and arbitrary snapshot fields. Spreadsheet-sensitive text receives a leading apostrophe, including handles beginning with @ and cells beginning with formula characters after whitespace. CSV quoting preserves commas and line breaks.

HTML and CSV require moderator or admin access and send private, no-store cache headers. Reading or exporting does not change moderation, content or credit. Report **Keep live** resolutions remain in the reports inbox, outside this global event log. AI comparisons remain on each submission. Escalation and specialized admin-overturn workflows remain separate work.

## Compare a submission

Click **Compare with AI** on the review page. The app sends the captured content and policy question to Jev and OpenAI Luna. It records their recommendations independently. The comparison never changes the submission's approval state.

Each evaluation records the model, policy version, content revision, input snapshot, answer distribution, confidence, latency, reported input tokens, and estimated cost. An older revision stays in the history with an older-content label. Missing usage produces an unknown cost. Failed calls can still incur provider charges, so provider billing remains the authority.

A repeated form submission with the same comparison key reuses its evaluations. A fresh comparison uses a new key. The client does not retry paid calls automatically. If a process stops during a call, its evaluation can remain `running`. Start a fresh comparison to retry and retain the interrupted record.

## Run the smoke comparison

The bundled examples include sports discussion, spam, a threat, insufficient context, a number change, and conflicting player evidence. Run both providers with:

```sh
doppler run --project athleteace --config dev -- mise exec -- ruby -S bundle exec rails decisions:compare
```

The task prints one JSON record per case and provider, followed by a `smoke_comparison` summary. A nonzero exit means a provider was unavailable, a call failed, or a result differed from its smoke label. A missing summary or zero completed evaluations does not establish a successful comparison.

The examples are a smoke check, not a production accuracy estimate. Compare a larger, independently labeled set before choosing automatic-clearance thresholds. Sports-data questions include supplied candidates and an `insufficient_evidence` outcome. Evaluations do not update players, teams, seasons, or jersey-number histories.

The [first live smoke results](decision-model-smoke-results.md) record the October 14 comparison, including its classification difference and measured token costs.

The client pins `jev-1.13.0` and `gpt-6-luna`. Its stored input rates are $0.042 and $0.10 per million tokens. These estimates cover short text requests and do not establish invoice totals. Review model versions and rates in [TypeSafe's documentation](https://docs.typesafe.ai/introduction/quickstart) and [OpenAI's Decisions documentation](https://developers.openai.com/api/docs/guides/decisions) before changing them.

## Check the implementation

Build the stylesheet before browser tests:

```sh
mise exec -- ruby -S bundle exec rails tailwindcss:build
```

A nonzero exit means the stylesheet build failed.

Run the focused acceptance tests:

```sh
mise exec -- ruby -S bundle exec rspec spec/models/moderation_spec.rb spec/requests/moderation_spec.rb spec/requests/moderation_log_spec.rb spec/system/moderation_log_spec.rb spec/services/decision_models_spec.rb spec/system/moderation_spec.rb
```

A nonzero exit, any failed example, or zero examples means the check failed. These tests cover privacy, attribution, stale decisions, provider failures, repeated comparison keys, and review on a 390-pixel viewport.
