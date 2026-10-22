# Team walls, reports and revenue

## Read a team wall

Open a team from Feed or Play. The team page keeps that shell and any nested catalog route. **Wall**, **Roster** and **Ratings** switch sections; the wall and roster show 25 entries per page, and ratings keep their existing visibility and controls. Wall is the default section.

The wall shows approved, spent shout-outs recorded for that team. **All**, **Team** and **Players** filter the recorded target type. A player transfer does not move an existing post to another team. Deleted targets retain their recorded names. Pending posts stay outside the wall, including the author's own pending submissions; authors can find them in **My shout-outs** or their personal Feed.

Wall ordering uses the same randomized-bid formula and session seed as Feed. Refreshes and pagination keep the order stable. Tab, filter, side and page are in the URL. Invalid section/filter names return HTTP 400. Weekly counts include currently live posts whose approval occurred since Monday in the app's time zone, UTC. The player summary breaks equal counts by recorded name and target ID. There are no pins or paid card tiers.

## Report a live shout-out

**Report** appears on live Feed and wall cards. Sign in, choose Harassment, Spam, Off-topic or Other, add an optional note, and select **Send report**. Notes are limited to 2000 Unicode code points. Each ace can report a post once; retries reuse the existing report, including a previously resolved report. Pending or hidden posts cannot receive new reports. A report alone does not hide a post or change anyone's credit.

Reporter identities, original notes and keep-live decisions appear only in reviewer views. They are absent from public cards and the author's private post view. Hiding records a standard moderation reason, which the author can see with their refund in the private post view. An author who is also a reviewer cannot inspect reports on their own posts. Deleting a reporter/reviewer account clears that identity reference while preserving the report and resolution.

## Review reports

Moderators and admins open **Reports** in the Moderate navigation or **Reports inbox** from the queue. Open reports are grouped by post, most reported first, then earliest report and post ID. The inbox excludes the reviewer's own posts. It shows 25 posts per page; **Resolved** shows resolved reports and the number of distinct posts resolved this week.

Open **Review reports** to inspect the card, reason counts, reporter notes, author profile and moderation history. Notes/history are paginated, 25 reports per page. A reviewer cannot decide their own post or a set containing their own open report.

Enter a decision reason, then choose:

- **Keep live** resolves the current open reports and records reviewer, reason and time. The post and its funding remain unchanged.
- **Hide and refund credit** uses the existing moderation transaction. The post leaves Feed and every wall, its full bid returns to available credit, a moderation decision is recorded and its open reports resolve as hidden. A hide from the ordinary moderation page performs the same report resolution and refund.

The post row lock serializes reports and decisions. A new report since the review form loaded, an already resolved set, or a changed post returns HTTP 409 and requires a reload. Concurrent hides can refund only once. Reviewers cannot bypass the own-report restriction through the ordinary hide action. Refunded posts cannot reopen for free.

Keep-live decisions are retained on each report, rather than added to the global `ModerationDecision` log. Warning/mute enforcement, escalation and automatic hiding remain separate work. There is no optional refund checkbox or automatic report threshold.

## Read revenue

Admins open **Revenue** in Admin, or **Shout-out revenue** from the overview. HTML and CSV require admin access. Choose 7, 30, 90 or 365 calendar days. The range includes today so far and uses UTC. **Export daily CSV** downloads one row per day with fixed columns and integer cents; it includes no user-authored text.

Period flows use ledger entry timestamps:

| Measure | Meaning |
| --- | --- |
| Cash purchases | Full credit added by verified paid Stripe sessions, recorded when the webhook is fulfilled. This can differ from the provider's original charge date. |
| Credit spent on approvals | Reserved credit spent when a post is approved. This is not a second cash payment. |
| Reservations released | Credit returned after rejection, without a second charge or card refund. |
| Refunded to credit | Full bids returned after hiding approved posts. A later-period refund appears in that later period. |

Current available/reserved wallet balances and live-post count cover all time, separately from selected-period flows. Paying aces counts distinct purchasers with credited purchases in the period. Top targets ranks period approvals by credit spent before subsequent refunds, with deterministic ties. Empty periods show zero amounts. All sums use exact cents, without floating-point money.

Card fees and net cash are explicitly unavailable until actual Stripe balance transactions are synced. The dashboard does not estimate fees, label wallet balances as profit, or combine purchases and credit spending into one cash-revenue total. It performs no Stripe calls and is not a provider settlement reconciliation or a tax report. Live Stripe setup remains in [shout-out payments](shout-out-payments.md).

## Verify locally

Install dependencies and apply the new reports migration before building CSS:

```sh
mise exec -- ruby -S bundle install
mise exec -- ruby -S bundle exec rails db:migrate
mise exec -- ruby -S bundle exec rails tailwindcss:build
```

A nonzero exit means the corresponding install, migration or stylesheet build failed.

```sh
mise exec -- ruby -S bundle exec rspec spec/requests/team_wall_spec.rb spec/requests/shout_out_reports_spec.rb spec/requests/shout_out_revenue_spec.rb spec/models/credit_concurrency_spec.rb spec/system/team_wall_reports_spec.rb
```

A nonzero exit, failed example or zero examples means verification failed. These checks require PostgreSQL and Chrome. They use the test database, fixture payments and independent database connections for races. They do not charge cards or call Stripe. The concurrency group truncates the test database after its committed-fixture checks.
