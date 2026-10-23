# Warn an ace or pause posting

Open an ace from Moderate search or submission attribution. Moderator profiles show the last sign-in recorded by Devise, current submission counts, warning and mute counts, and received report counts. The sign-in time is not a last-seen indicator. Submission counts include current proposal states and funded shout-outs, excluding unpaid posts. The Submissions section shows the ten most recent entries.

## Record a warning or note

Expand **Warn**, enter **Warning reason**, optionally select a related submission and choose **Record warning**. The related item must belong to that ace. The warning retains its recorded name after the content changes or disappears. A warning does not hide a post, reserve credit or block posting.

Use **Add moderator note** for internal context. Notes stay visible to other reviewers and are unavailable to the ace concerned, even if that ace is a reviewer. Mute notes have the same privacy boundary. Warning reasons, mute reasons and early-ending reasons are visible to the ace.

Moderators can act on fans. Admins can also act on moderators. Self-actions and actions against admin accounts are unavailable. Another authorized reviewer must handle the account. Suspension and role management remain separate Admin People work.

## Start or end a timed mute

Expand **Mute from posting** and choose **24 hours**, **7 days** or **30 days**. Enter a reason and optionally add a private moderator note. Only one active mute is allowed. Starting another returns HTTP 409 rather than extending the current mute. Use **End mute early** with a reason before starting a replacement. The original interval, actor and reason remain recorded, alongside the early-ending time, actor and reason.

The mute ends automatically at its recorded end time. There is no expiry job. At the exact end instant, posting is available again. New shout-outs, proposal creation and opening/saving the draft composer are blocked during the mute. Existing drafts remain readable in My drafts and can be deleted. HTML and JSON attempts return HTTP 403 with the end time. Forged form fields cannot set duration endpoints or reviewer identities.

Muted aces retain sign-in, Play, reading, follows, ratings, reactions, reporting and wallet access. Already-submitted posts retain normal review and funding behavior. An in-flight Stripe payment still receives its full credit and funds the existing submission. A mute does not reverse existing decisions or payments. Ending a mute does not restore a hidden post.

## Also hide a reported shout-out

The mute form can select one of the ace's live posts with open reports under **Hide their live shout-out that was reported**. The selector lists up to 100 posts in ID order. Use the Reports section or inbox to inspect any others.

Hiding always returns the full bid as wallet credit and resolves open reports through the normal moderation transaction. There is no no-refund option. The mute and hide commit together. A missing/changed post, a resolved report set, a report filed by the acting reviewer or invalid mute data prevents the combined action. No mute, hide or refund remains after a failed combined transaction.

## Inspect history and personal status

**Submissions**, **Reports**, **Warnings and mutes** and **Moderator notes** separate the moderator profile. Reports, warnings, mutes and notes show 25 records per page, with stable descending timestamps and IDs. A reviewer cannot inspect reports or internal notes on their own account. Empty sections show an empty state.

Signed-in aces see a banner for posting warnings or an active mute. **Posting status** in the account menu opens their private warning and mute history at `/account/posting`. It uses only the signed-in account, not a supplied account ID. It omits reporter data and private moderator notes. These are in-app notices; this workflow does not send email.

Warnings, mutes and notes are separate from the content Decision log. The log continues to record a combined post hide normally. Account moderation records have no public Feed broadcasts or public profile badges. Reviewer profiles and personal status responses use private, no-store headers.

## Implementation and acceptance boundaries

`PostingWarning` maps to the `warnings` table because Ruby already defines the top-level `Warning` module. Warnings and standalone notes are read-only after creation. Original mute fields are read-only; the early-ending workflow appends its audit fields. Deleting a reviewer clears the actor reference and retains history. Deleting the subject account removes its account-moderation history through foreign-key cascades, subject to the existing financial-account deletion restrictions.

| Requirement | Boundary | Resolution |
| --- | --- | --- |
| Durations | Unsupported durations, overlap and exact expiry. | Explicit: 24, 168 or 720 hours, one active mute, active strictly before the end time. |
| Enforcement | An old form or direct model write can bypass UI checks. | Explicit: form/API checks plus an account row lock around creation of all authored moderated records. Mute creation holds the same lock. |
| Retries | Repeated warning, note or mute submissions can duplicate actions. | Explicit: Warning, note and mute forms have an idempotency key. The same request returns the recorded action; changed fields with a reused key return HTTP 409. Repeating an early-ending action retains its first recorded result. |
| Combined hide | Failure after the refund can leave partial effects. | Explicit: one transaction for mute, post hide, report resolution and full credit refund. Normal self-report review restrictions apply. |
| Identity and privacy | Staff actions can expose notes or silently become account suspension. | Explicit: hierarchy and self-action restrictions, private internal notes, personal reasons only, unchanged sign-in/Play/wallet permissions. |
| History | Current content or deleted actors can rewrite the apparent warning. | Explicit: retain related names and action history. Show deleted-reviewer attribution without inventing an identity. |

The six acceptance probes are explicitly resolved. No backstop or judgment items remain. [Escalation controls](moderation-escalations.md) hand account cases to another admin without changing permissions. Account suspension remains separate work.

## Verify locally

Apply the migration, then build styles:

```sh
mise exec -- ruby -S bundle exec rails db:migrate
mise exec -- ruby -S bundle exec rails tailwindcss:build
```

A nonzero exit means that migration or stylesheet generation failed.

```sh
mise exec -- ruby -S bundle exec rspec spec/requests/posting_moderation_spec.rb spec/models/posting_enforcement_spec.rb spec/models/posting_concurrency_spec.rb spec/models/credit_concurrency_spec.rb spec/system/posting_moderation_spec.rb
```

A nonzero exit, failed example or zero examples means verification failed. PostgreSQL and Chrome are required. Concurrency checks use committed fixtures on independent connections and truncate the test database after their groups. Payments use fixtures, without Stripe calls or card charges.
