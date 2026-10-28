# Admin overview

The Admin landing page combines recorded operational metrics with links to People, Revenue, Sports data, Content catalog, Moderation oversight, the review queue, and escalations. It requires an active admin and sends private, no-store responses. Opening the page does not change accounts, moderation decisions, credit, or escalations and makes no Stripe calls.

All day-based metrics use UTC and share the displayed **As of** time. Today includes records through that time; it is not a completed-day comparison.

## Metrics

- **Cash purchases today** uses the existing revenue report's purchase ledger entries. It records the full amount when verified payment adds credit, which can differ from the original Stripe charge date. Spending credit and returning reservations or spent credit do not become additional purchases.
- **New accounts today** counts accounts currently present whose creation times fall between UTC midnight and the displayed time. Unconfirmed accounts count. Deleted accounts do not remain in this count.
- **Review events today** counts pending-to-approved, pending-to-rejected, approved-to-hidden, and rejected/hidden-to-pending ModerationDecision events. Submissions, resubmissions, trusted creation, and content edits are excluded. Keep-live report resolutions, warnings, mutes, and escalation closures without a content decision remain outside this measure.
- **Open escalations** counts the open cases the signed-in admin can view, excluding that admin's own account and submissions. This is the same visibility rule as the escalation inbox.

The existing **Application totals** still shows current Ace, Player, and Team record counts and the pending queue count the admin can review. Pending queue counts exclude the admin's own submissions, unfunded shout-outs, and open escalations.

## Cash purchases over 14 days

The daily chart includes today and the preceding 13 UTC dates, with explicit zero values for dates without purchases. Its total covers those 14 dates. Chart bar widths are relative to the largest daily amount; all displayed currency calculations retain integer cents. Today is labeled incomplete.

These figures use the same ledger definitions as [the revenue dashboard](shout-out-operations.md#read-revenue). They do not show card fees, provider settlement, profit, or tax-receipt totals.

## Review activity and escalation cases

Review counts group by the recorded actor reference, regardless of that actor's current role. Missing or deleted actors appear as **System or deleted account**. Actors' current public names are displayed. Counts describe events, not distinct content, review speed, or reviewer quality. **Decision log** opens the detailed history.

The case list shows the five oldest visible open escalations, using ID to break timestamp ties. It retains captured subject names when subjects have been deleted. Original escalation reasons are omitted from the overview. **View case** opens the existing protected case workflow; another admin may be required to resolve a case. **All escalations** opens the full inbox.

[Moderation oversight](admin-moderation-oversight.md) shows review counts over a selected UTC period, measured pending waits, and later status changes with exact log drilldowns. Seed-run status, backup health, review-time targets, and formal appeal-linked overturn statistics remain separate work.

## Verify locally

```sh
mise exec -- ruby -S bundle exec rails tailwindcss:build
mise exec -- ruby -S bundle exec rspec spec/requests/admin_overview_spec.rb spec/requests/shell_spec.rb spec/requests/shout_out_revenue_spec.rb spec/system/admin_overview_spec.rb
```

A nonzero build exit indicates a stylesheet failure. A nonzero RSpec exit, failed examples, or zero examples indicates verification failed. The checks use local PostgreSQL, Chrome, and fixture payments without real charges.
