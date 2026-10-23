# Moderation escalations

Moderators and admins can hand a submission or account case to an admin through **Escalate to admin** on its review page or moderator profile. The required reason is private to reviewers who can view the case. Escalation does not send a notification.

## Case access and resolution

**Moderate → Escalations** lists open cases oldest first and resolved cases by most recent resolution, with 25 cases per page. Fans and guests cannot read cases. Reviewers cannot view cases about their own submissions or accounts.

Only an admin can resolve a case. An admin cannot resolve their own requested escalation or a case about their own submission or account. An admin with an open report against the shout-out must leave resolution to another admin.

An open content case leaves the ordinary queue, including its counts and Moderate search results. Ordinary review and report decisions are blocked for all reviewers, including admins. Admins must use the case's resolution form. Reports remain visible in the reports inbox.

Available content decisions follow the captured status:

| Captured status | Decisions |
| --- | --- |
| Pending | Approve or Reject |
| Approved | Hide |
| Rejected or hidden | Reopen for review, except refunded shout-outs |

Every case also allows **Close without changes**. This closes the handoff without deciding content or reports. Pending content returns to the ordinary queue. Open reports still require a separate decision.

Account cases allow only **Close without changes**. Account roles, warnings, mutes and sign-in access stay unchanged. Any warning or mute is a separate action on the moderator profile.

## Captured context and credit

The case retains the original subject name, snapshot, revision, status, requesting reviewer and escalation reason. Shout-outs also capture funding status. The snapshot remains available after content edits or subject deletion. Resolved cases retain the resolution, reason, admin and time and cannot be edited through the application.

A content decision requires the current revision, status and shout-out funding status to match the captured case. Changed or deleted subjects allow only closing without changes. Reviewers can inspect the current subject and create a new case after closing the old one.

Content decisions use the existing moderation transaction. Approval captures reserved credit, rejection releases it, and hiding a live shout-out returns its full bid as credit. Refunded posts cannot be reopened for free. Unfunded shout-outs cannot be escalated.

The original escalation reason stays outside owner pages and decision-log CSV exports. A resolution that approves, rejects, hides or reopens content records its reason in normal content history and the global decision log. That reason can be visible to the content author. Closing without changes records only the private case resolution.

## Request and concurrency rules

`ModerationEscalation` stores one open case per subject, enforced by a partial unique index. `Moderation::Escalate` locks the subject before capturing its context. Repeated requests with the same reviewer, request key, subject and reason reuse the case. Changed or competing requests return HTTP 409.

`Moderation::ResolveEscalation` locks the subject before the case and checks its version. The content decision, credit entries, report resolution on hide and case resolution commit together. An identical retry by the same admin returns the completed case. Competing or changed resolutions return HTTP 409.

## Acceptance decisions

| Boundary | Accepted behavior |
| --- | --- |
| Privacy and conflicts of interest | Reviewer access only, private no-store responses, no own-subject visibility, no requester or own-report resolution. |
| Repeated or concurrent actions | One open case per subject, idempotent retries, subject-before-case lock order and one refund. |
| Stale or missing subjects | Preserve the captured snapshot, block content mutations and allow closing without changes. |
| Funding | Reuse the normal credit transaction and prohibit free reopening after a refund. |
| Account handoff | Preserve roles and access. Warnings and mutes remain explicit separate actions. |
| Queue routing | Exclude open content cases from queue rows and counts. Block ordinary review and report decisions until resolution. |

All six boundaries have explicit behavior. [Account suspension](admin-people.md) is a separate admin-only action. Specialized admin overturns and broader reviewer analytics remain separate work.
