# Reactions, weekly leaders and public search

## React to a shout-out

Live cards in Feed, team walls and public post pages show **Fire**, **Love** and **Legend** with counts. Sign in to select or remove each kind independently. Aces may react to their own live posts. Each ace has at most one membership of each kind per post; toggling one kind does not remove the others. Guest buttons lead to sign-in.

Adding uses PUT and removing uses DELETE. Repeating either request preserves its intended state, including after a retry. The post row lock serializes these requests with moderation, and a unique database key prevents duplicate memberships. Only approved, spent posts accept reactions. Pending, rejected, hidden or unfunded posts return HTTP 404; unsupported kinds return 400. Old memberships remain stored when a post is hidden, but their card/counts are no longer public. Deleting a reacting account removes its memberships.

Reactions are free. They never change credit, bids, Feed ranking, leaderboard counts or moderation. Counts come from grouped database queries, not cached counters. Feed and team walls batch counts and the viewer's selections for the page. Turbo replaces the affected card after a reaction; ordinary HTML requests redirect back to a local page or the post permalink.

## Read weekly leaders

Open **Leaders** from Feed or its navigation. The public page separates **Players** and **Teams** and offers week, sport and league filters. The Teams board counts posts targeting the team itself, not its players. Each currently live post counts once, regardless of its bid or reactions.

Weeks run Monday through Sunday in UTC, using the approval decision timestamp rather than draft/submission time. A selected YYYY-MM-DD date normalizes to its Monday. Invalid dates, malformed target types and future weeks return HTTP 400. Empty weeks show an empty state. Previous/next week and **This week** preserve target/filter selections; pages contain 25 ranked targets.

Rank uses post count descending, then target ID ascending to break ties. Movement compares the same filters against the preceding week: **New**, **Same rank**, **Up N** or **Down N**. Each row has a distinct rank even for equal counts. The leading target on each page can expand its top shout-out, selected with the visitor's normal weighted bid order.

Counts use the post's recorded league, so transfers do not rewrite which league receives a post. Targets use their current catalog identity; deleted targets are omitted. Hiding a post removes it from current and past standings on the next read, including movement calculations. This is a live-content leaderboard, not a frozen historical snapshot.

Counts are fresh SQL aggregates. There is no stale leaderboard cache or sidebar widget in this increment. Bid-weighted Feed order remains separate from count-based leaderboard rank. Live broadcasts and any later measured caching work remain separate work.

## Search and share live posts

**Search live shout-outs** on Feed matches messages, recorded target names, public display names and handles. It accepts 2 to 80 Unicode code points and treats SQL wildcard characters literally. Whitespace is trimmed; input longer than 80 characters is shortened to 80. Empty input returns the normal Feed; a one-character direct Feed query returns HTTP 400. Shell search retains its existing minimum-two-character prompt and adds up to five live shout-out matches on the Feed side.

Both searches use the same visitor-session weighted order as Feed. On **My teams**, a search remains restricted to followed/high-Affinity teams and the selected league. The query stays in search forms, pagination and the All/My teams links. Search does not include the viewer's own pending posts, even for moderators or admins. Drafts, rejected/hidden/unfunded posts, report notes, account email and financial records are absent.

**Permalink** opens a public read-only post page at `/feed/posts/:id`. Shell post results lead there, not to a moderation or private-owner route. A hidden or otherwise non-live post returns HTTP 404 even to its author; the author's existing **My shout-outs** page remains available separately. A deleted target retains its recorded post name and readable message.

## Verify

Apply the reactions migration and build CSS:

```sh
mise exec -- ruby -S bundle exec rails db:migrate
mise exec -- ruby -S bundle exec rails tailwindcss:build
```

A nonzero exit means the respective migration or stylesheet build failed.

```sh
mise exec -- ruby -S bundle exec rspec spec/requests/feed_reactions_spec.rb spec/requests/public_shout_out_search_spec.rb spec/requests/shout_out_leaderboard_spec.rb spec/models/credit_concurrency_spec.rb spec/system/feed_engagement_spec.rb
```

A nonzero exit, failed example or zero examples means verification failed. PostgreSQL and Chrome are required. The concurrency group uses independent connections and committed fixtures, then truncates the test database. Payments use fixtures; no Stripe calls or card charges occur.
