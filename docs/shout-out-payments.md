# Shout-out payments and ranking

Shout-outs use custom USD bids rather than fixed-price tiers. Save a private draft, then choose **Your bid (USD)** and **Payment method**. **Use credit** accepts positive amounts from $0.01. **Pay directly with Stripe** accepts $0.50 to AthleteAce's limit of $999,999.99 per payment. A submitted post snapshots its message, target name, team context, and bid. Editing the original draft does not change the submitted post.

## Credit and payment flow

**Credit wallet** shows available credit, credit reserved for review, and a paginated history. A purchase adds its full amount, with no processing-fee deduction. Stripe Checkout charges the card immediately. Credit purchases have Stripe's $0.50 minimum and allow any cent amount up to AthleteAce's $999,999.99 limit per charge. Stored credit can fund smaller bids. Credit is denominated in USD, cannot be withdrawn to a bank or transferred between aces, and is not automatically refunded to a card.

Credit-funded submissions reserve the bid atomically. Direct payments create an unfunded post, then open Stripe Checkout; only a verified paid Stripe event adds and reserves its credit. The return page never grants credit. Unfunded posts are absent from the review queue and Feed. Canceled checkout can be resumed from **Payment status** or the unfunded post; an expired checkout requires a new purchase attempt.

Approval spends reserved credit and publishes the post. Rejection releases the reservation to available credit. Hiding a live post returns the full bid as available credit, including posts paid for directly. Fees never reduce this amount. Refunded posts cannot be reopened for free; create a new funded submission. Another reviewer must decide an ace's own submission, including submissions by admins. The existing oldest-first moderation order remains.

Each saved draft version can create one submitted post. Retrying the same submission reuses it; changing its bid requires editing and saving a new draft version. Wallet purchases carry a request key, Stripe requests use a persistent purchase-based idempotency key, and ledger operations are keyed by source and action. Purchases, posts, and credit accounts use database row locks so simultaneous requests cannot duplicate credit or spend the same balance twice. Application workflows only append ledger entries; persisted `CreditEntry` records are read-only. Accounts with financial records require a separate closure process rather than ordinary deletion.

## My shout-outs

**My shout-outs** is private to the signed-in ace. Filter by All, Awaiting payment, In review, Live, Rejected, or Hidden. Each filter shows its total count across that ace's history. Pagination preserves the selected status and sorts newest submissions first, with descending ID as the tie-breaker. Unknown status values return HTTP 400.

**Your bid totals** summarizes all owned submissions, regardless of the selected filter: awaiting payment, reserved for review, spent on live posts, and returned as credit. These are current post-state totals, not cash receipts or available wallet balances. Rejected reservations and hidden-post refunds both contribute to **Returned as credit**. Unfunded posts count only as awaiting payment, not in review.

From an owned post with an existing target, **Copy to new draft** copies the submitted message and target into a separate private draft. Later edits to the original draft do not affect this copy. The original submission, moderation history, bid, credit ledger, and balances stay unchanged. Choose and fund a new bid through the ordinary submission flow. Muted or suspended aces cannot use this action, and a deleted target prevents copying. Numbered or emailed receipts and PDF downloads remain future work.

## Feed

Public Feed and [team walls](shout-out-operations.md) include approved, spent posts. Signed-in aces also see their own funded pending posts, labeled **in review**. Other accounts cannot see pending posts. **My teams** intersects posts with the recorded team context and chosen sport/league; its personal team cards remain separate from the stream. Target names remain recorded after catalog deletion. A pending post with a deleted target must be rejected, releasing its reservation, rather than approved.

Both Feed views support sport/league filters and live approval/removal updates. See [Feed filters and live updates](feed-engagement.md#filter-and-follow-the-live-feed) for session privacy, filter persistence and Cable behavior.

For each visitor, ranking uses:

```text
score = (bid_in_dollars + uniform_random(0.5, 2.5)) ** 1.6
```

Higher scores appear first. Each post has its own draw, derived from a random visitor-session seed and the post ID. The draw is stable across refreshes and pagination within that session; separate visitors get separate seeds. Score ties use descending post ID. This affects Feed, live-post search and featured-card display order only, never bid or ledger amounts. Free reactions do not change the score; the weekly leaderboard ranks by post count instead. No placement, number of views, tier, pin, or duration is guaranteed. Post pagination uses `posts_page`, independently of the My teams cards' `page` parameter.

Posting mutes block new shout-out submissions. Already-submitted posts and in-flight payments keep their normal funding/review lifecycle. An optional hide during a mute returns the full bid as credit. See [posting moderation](posting-moderation.md).

## Stripe setup and verification

Configure `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` through the app's secret storage. See `config/stripe.env.example` for variable names. Use test keys and Stripe CLI test events locally; live payments have not been verified by the automated suite. Checkout is disabled without both variables. There is no client-side publishable key because payment entry is hosted by Stripe.

Register `POST /stripe/webhook` for `checkout.session.completed` and `checkout.session.expired`. It verifies the raw-body signature and timestamp with Stripe's Ruby SDK, checks test/live mode against the secret key, and checks currency, amount, purchaser, session identity, payment status, and reference before fulfilling. A paid session is processed once even when Stripe sends different duplicate event IDs. Expiry does not undo an already paid purchase.

The [reports and revenue guide](shout-out-operations.md) covers report resolution, mandatory refunds, and the distinction between cash purchases and spent credit.

Apply migrations and build CSS before testing:

```sh
mise exec -- ruby -S bundle exec rails db:migrate
mise exec -- ruby -S bundle exec rails tailwindcss:build
```

A nonzero exit means migration or stylesheet generation failed.

```sh
mise exec -- ruby -S bundle exec rspec spec/models/shout_out_payments_spec.rb spec/requests/stripe_payments_spec.rb spec/requests/shout_outs_spec.rb spec/system/shout_out_payments_spec.rb spec/models/credit_concurrency_spec.rb
```

A nonzero RSpec exit, failed examples, or zero examples means verification failed. Tests use signed fixture events and stubbed Stripe Checkout calls; no real charges are made. The concurrency checks use committed fixtures in the test database and truncate that database after their group. PostgreSQL and Chrome are required for the full selection.

Stripe references: [minimum charge amounts](https://docs.stripe.com/currencies#minimum-and-maximum-charge-amounts), [Checkout fulfillment](https://docs.stripe.com/checkout/fulfillment), [webhook verification](https://docs.stripe.com/webhooks/signature), and [idempotent API requests](https://docs.stripe.com/api/idempotent_requests).
