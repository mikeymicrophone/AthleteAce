# Redesign completion pass

Local review on October 25, 2026, following the Browse, Play detail, Admin content catalog and moderation oversight commits. This records the interface pass; production payment and email checks remain separate.

## Reviewed journeys

The existing browser suite exercised visitor and account navigation, saved rounds, game answers and summaries, quest progress, ratings, follows, Feed engagement, drafts and funded review, account history, moderation decisions, reports, escalations and Admin editing.

A separate layout survey opened these 23 screens at 390, 768 and 1440 pixels in both light and dark themes. All 138 rendered states fit the viewport without whole-page horizontal overflow. Wide Admin tables retain their horizontal scroll containers.

| Side | Screens in the layout survey |
| --- | --- |
| Play | Home, new round, quests, history, Browse, player profile |
| Feed | All, My teams, leaders, drafts, composer, wallet |
| Moderate | Queue, submission review, reports, escalations, decision log |
| Admin | Overview, People, revenue, sports data, content catalog, moderation oversight |

Survey records used realistic names, teams, content and an approved funded shout-out created through the existing factories and payment helpers. These were local test records. No real payment was made.

## Repairs

Every page declares English as its document language. **Skip to content** is the first keyboard link, appears on focus above the sticky header, and moves focus into the main content. The keyboard regression covers all four sides at phone and desktop widths.

Drafts, wallet, payment and other shout-out pages use the Feed section label. Report review uses Moderate and revenue uses Admin. Public entity headings retain Browse even when reached from another side.

An empty filtered Feed list distinguishes no matches from a new Feed with no posts. **Reset view** clears search, sport and league together while retaining All or My teams. Signed-out My teams shows its sign-in prompt without a misleading empty-post message. Leaderboard **Clear filters** removes sport and league while retaining the selected week and target kind.

## Remaining feature work

These are implementation or product gaps beyond this interface pass:

- Formal appeal outcomes linked to original moderation decisions, including a defined overturn rate, under AA-203 and AA-207.
- Bulk review and an explicit edit-and-approve workflow under AA-195. Paid submissions remain immutable.
- Additional sports-data editors, number-history editing and bulk changes under AA-192; broader sourced palette and jersey coverage under AA-172.
- Recorded seed runs, backup scope, scheduling, storage and restore previews under AA-193.
- Audited configurable message rules and approved moderation targets under AA-201 and AA-166.
- Payment terms, live Checkout/webhook verification and notification delivery under AA-165 and AA-197. Numbered receipts, receipt email and PDF download remain AA-204.
- A full component styleguide, remaining table/inline-edit variants and deliberate toast behavior under AA-176.

The [October 2 design comparison](redesign-review.md) remains a historical review. Current functional references are [Browse entities](browse-entities.md), [Feed engagement](feed-engagement.md), [Admin content catalog](admin-content-catalog.md) and [Moderation oversight](admin-moderation-oversight.md).

## Local checks

```sh
mise exec -- ruby -S bundle exec rails tailwindcss:build
mise exec -- ruby -S bundle exec rspec
```

A nonzero build exit indicates a stylesheet failure. A nonzero RSpec exit, failed examples or zero examples indicates verification failed. Browser checks require local PostgreSQL and Chrome. Payment fixtures use no real charges. Passing these checks does not verify production services or deployment.
