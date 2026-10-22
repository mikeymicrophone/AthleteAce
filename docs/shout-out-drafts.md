# Private shout-out drafts

Use **Write a draft** on Feed, or **Write a shout-out draft** on a player or team page. Sign-in is required. Entity-page links preselect that player or team. **My drafts** lists only your drafts, with pagination, editing, and deletion.

Search for a player or team using at least two characters. Results use the same public names, nicknames, and team abbreviations as Feed search, with at most five results of each type. Select a result, then write your message. The preview updates as you type. The emoji buttons insert an emoji at the cursor.

Messages require 1–200 Unicode code points after trimming surrounding Unicode whitespace. Compound emoji can count as several code points. Browser and server counts use the same rule. Links and web addresses are rejected on save; the form keeps your selected target and text when validation fails. Preview and saved text are escaped plain text.

**Save draft** stores private text. Drafts do not enter the moderation queue or the public Feed. Checkout, prices, tiers, payment holds, pins, and publication are not available. Banned-word configuration and publication rules remain part of the later submission flow. A saved draft does not establish that its message can be published.

If a player or team is deleted, its draft message remains available to its owner. Select a replacement target before saving changes. Deleting an account removes its drafts. A stale edit returns HTTP 409 and preserves the newer saved version; reload before editing again. Draft responses use `Cache-Control: private, no-store`.

## Apply and verify

Apply the storage migration and build styles:

```sh
mise exec -- ruby -S bundle exec rails db:migrate
mise exec -- ruby -S bundle exec rails tailwindcss:build
```

A nonzero exit means that migration or stylesheet generation failed.

Run the draft and related Feed checks:

```sh
mise exec -- ruby -S bundle exec rspec spec/requests/shout_out_drafts_spec.rb spec/system/shout_out_drafts_spec.rb spec/requests/feed_preferences_spec.rb spec/system/feed_preferences_spec.rb spec/requests/shell_spec.rb spec/system/follows_spec.rb
```

A nonzero RSpec exit, any failed example, or zero examples means verification failed. These checks require local PostgreSQL; browser checks also require Chrome.
