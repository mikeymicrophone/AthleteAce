# Admin People

Admin People provides private account search, role management, suspension, reactivation and password-reset requests. The page is available from the Admin navigation, overview and Admin search results. Moderators and fans cannot access it. Responses use private, no-store cache headers.

## Directory and account detail

The directory supports name, handle or email search, role and status filters, and inclusive joined-date bounds in the application time zone. Search treats SQL wildcard characters literally. Results show newest joined first, with ID as the tie-breaker, and 25 aces per page. Invalid roles, statuses, dates and reversed date ranges return HTTP 400.

Status filters are mutually exclusive, in this order: suspended, currently muted, previously warned, active. Expired mutes do not count as current mutes. Warned means the ace has at least one recorded warning. It does not expire automatically. Role counts classify admins separately from moderators.

Spent is net credit captured on approved shout-outs minus credit returned after hides. Purchases and reservations do not count as spending. The directory and account detail use the same calculation. An account's last sign-in comes from Devise and is not a last-seen time.

Account detail shows the email, role, sign-in access, current posting mute, warning count, submission count, net spending, account action history and sign-in events. The submission count includes all authored proposals and shout-outs, including unfunded shout-outs. **View as moderator** opens the existing moderator profile with the acting admin's permissions. It does not impersonate another ace.

## Account actions

Every role change, suspension, reactivation and password-reset request requires the acting admin's current password and a reason of 1–2000 Unicode code points after trimming. Role choices are Fan, Moderator and Admin. Selecting a role replaces both existing role flags. New permissions apply on the account's next request.

Self-actions are blocked. Another active admin must act. Account actions serialize through a PostgreSQL transaction advisory lock and reload the acting admin before checking permissions. This prevents reciprocal demotions or suspensions from removing every active admin. Account deletion uses the same lock and cannot delete the last active admin. Unconfirmed accounts do not count as replacement admins. Direct database changes remain outside these application controls.

A target row lock also serializes suspension with new authored submissions. Stale account versions return HTTP 409. A repeated request with the same admin, key, subject, action, reason and chosen role returns the original audit record. A changed request cannot reuse that key. Password-reset requests advance the account version too.

`AccountAction` retains the acting admin, subject name, action, reason, before/after role and suspension state, and time. Records are read-only after creation. Deleting an account nullifies its references while retaining the audit snapshot. Reversing a role or access change requires a new action, password and reason. There is no one-click Undo.

### Suspension and reactivation

Suspension blocks Devise authentication and increments `Ace.session_version`. Existing session and remember-me credentials become invalid, including after reactivation. Existing sessions also encounter a suspended-account guard on application requests. Sessions created before this migration keep their existing authentication salt until the first suspension.

Suspension blocks new authored proposals and shout-outs at the model boundary. Existing content, roles, wallet balances, purchases, goals and decisions stay intact. Paid webhooks and staff review retain normal settlement and full-credit refund behavior. Suspending an account does not hide its content or cancel its payments. Reactivation restores sign-in eligibility; the ace must sign in again and still meet ordinary confirmation requirements.

### Password-reset requests

The audit record queues `AdminPasswordResetJob` after commit. The job uses Devise to send instructions to the account's current email. A repeated HTTP request does not queue a second job. Background-job retries can resend instructions; no exactly-once email delivery is claimed. A deleted target is skipped. The action history records the request, not delivery confirmation.

Resetting a password does not reactivate a suspended account or change its role. Tokens and passwords are not stored in the audit record. Production delivery depends on the application's mail and job configuration and has not been verified by this implementation.

## Sign-in events

Successful password sign-ins through `Aces::SessionsController` create a success event. Warden failures for that sign-in endpoint create a failure event for a recognized email. Warden rewrites the request path before its failure callback, so the hook uses `attempted_path` to identify the endpoint. Unknown emails are not retained.

Events retain the account, time, IP address and browser-supplied user agent, capped at 64 and 512 characters respectively. The browser string is unverified and displayed as text. No geographic lookup or device classification is inferred. Events start after installation, with no fabricated history or backfill. Existing Devise current/previous sign-in fields remain available. Programmatic sign-ins and session fetches do not create these events.

Sign-in events are visible only in Admin People and are read-only. Account deletion removes its sign-in events. Account action history remains private to admins and is separate from moderator notes, warning history, content decisions and public profiles.

## Acceptance decisions

| Boundary | Explicit behavior |
| --- | --- |
| Search, dates and pagination | Literal bounded search, validated filters, inclusive dates, deterministic ordering and 25 rows per page. |
| Authority and privacy | Admin-only email, IP, browser and account action history; password verification; no self-actions or impersonation. |
| Retries and concurrent actions | Immutable audit records, unique request keys, expected versions, serialized authority changes and last-admin deletion protection. |
| Suspension and financial state | Session revocation, sign-in and new-post blocks, preserved credit, payment settlement and normal staff review. |
| Password resets | Audited background requests after commit; no reactivation or delivery guarantee; no audit tokens or passwords. |
| Sign-in history | Real events only from installation onward, known accounts only, bounded request metadata and no invented locations. |

All six boundaries have explicit behavior. Automatic suspension rules, suspension notifications, one-click Undo and richer device/location reports remain outside this build.
