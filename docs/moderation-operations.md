# Review submissions and compare decision models

Run these commands from the AthleteAce repository, which contains `Gemfile` and `doppler.yaml`.

## Prepare the local app

Apply the migrations with the repository's Ruby version:

```sh
mise exec -- ruby -S bundle exec rails db:migrate
```

A nonzero exit means the migration failed. The migrations add approval states, creator references, reviewer roles, decision records, evaluation records, and optimistic locking. Existing content stays approved. New fan submissions enter review.

The Doppler project is `athleteace`, and the development config is `dev`. Add `TYPESAFE_API_KEY` and `OPENAI_API_KEY` there. Keep the values in Doppler, not this repository.

The web comparison reads the Rails process environment. Start Rails through Doppler to supply those keys:

```sh
doppler run --project athleteace --config dev -- mise exec -- ruby -S bundle exec rails server
```

If you use puma-dev, its existing process needs the same environment before the web comparison can use the keys. The command-line comparison below loads Doppler directly.

## Review a submission

1. Sign in with an existing admin account or an ace with `moderator` enabled.
2. Open `/moderate`. The queue excludes your submissions and orders the oldest submissions first.
3. Open a submission. Inspect its current content and decision history.
4. Approve or reject a pending submission. Enter a reason when rejecting.

To hide approved content, open the **Approved** tab and give a reason. To reconsider rejected or hidden content, reopen the item before approving it. Each action adds a decision record. Reviewers cannot decide their submissions. Concurrent or stale decisions return HTTP 409.

The first version covers quests, achievements, highlights, and spectrums. Approve a highlight's quest and achievement before approving the highlight. Public goal requirements exclude unapproved highlights and achievements.

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
mise exec -- ruby -S bundle exec rspec spec/models/moderation_spec.rb spec/requests/moderation_spec.rb spec/services/decision_models_spec.rb spec/system/moderation_spec.rb
```

A nonzero exit, any failed example, or zero examples means the check failed. These tests cover privacy, attribution, stale decisions, provider failures, repeated comparison keys, and review on a 390-pixel viewport.
