# Moderation decisions

This implementation holds new fan-created quests, achievements, highlights, spectrums, and funded shout-outs for review. Existing records and trusted catalog imports stay approved. Admin-created records are approved on creation, except shout-outs, which always require funding and another reviewer. AI results remain recommendations until application-specific evaluations justify automatic clearance.

## Acceptance decisions

| Requirement | Edge or prohibition | Resolution |
| --- | --- | --- |
| Visibility | Anonymous users, other authors, JSON, pickers, nested links, and rating submissions can reveal pending content. | Explicit visibility scopes apply to each entry point. Only the author and reviewers can inspect pending content. |
| Related content | An approved highlight can point at an unapproved achievement. | Public quest requirements include only approved highlights and approved achievements. Pending content cannot change another ace's goal requirements. |
| Attribution | Request parameters can forge authorship or approval. | Controllers assign the signed-in author. Strong parameters exclude moderation fields. |
| Review | Two reviewers act on the same revision. | A row lock, expected status, and revision check reject stale decisions without a second action. Reviewers cannot decide their own submissions. |
| Edits | An approval can silently survive changed content. | Content edits increment the revision and return authored content to pending. Submitted shout-out messages, bids, and targets are immutable; authors edit their private draft and submit a new funded version. Each submission and decision retains its snapshot. |
| AI evaluation | Missing credentials, refusals, malformed responses, timeouts, or edits during a request. | Failures remain visible as failed evaluations. Evaluations retain the captured revision and cannot publish or modify content. |
| Cost | Missing usage can masquerade as a free decision. | Missing usage yields an unknown cost. Estimates use the provider's reported input tokens and a stored rate. |
| Sports data | A model can invent a team, date, identity, or number. | The comparison supplies candidates and evidence with an insufficient-evidence outcome. Evaluations never mutate the sports catalog. |
| Repeated requests | A double click can duplicate paid calls. | The submitted comparison key identifies one evaluation per provider. A new comparison uses a new key and retains earlier results. |
| Calibration | Confidence alone can become an automatic publishing threshold. | Judgment: compare labeled examples and review errors before selecting thresholds. Automatic clearance remains disabled. |
| Coverage | A small sample can be mistaken for measured production accuracy. | Judgment: label the bundled cases as smoke examples. Report completed, failed, and skipped evaluations separately. |

Spec probes covered 11 applicable items. Nine have explicit acceptance behavior and two require judgment. Provider availability and live cost measurements depend on credentials.

## Decision-log acceptance decisions

| Requirement | Edge or prohibition | Resolution |
| --- | --- | --- |
| Date range | Midnight boundaries, invalid dates, missing inputs and future end dates. | Explicit: inclusive UTC dates, 30-day defaults, requests through the current instant and HTTP 400 for invalid ranges. |
| Filters | Unknown values, malformed inputs, deleted actors and empty matches. | Explicit: intersect validated filters, distinguish unattributed events, retain empty states and allow header-only exports. |
| Ordering | Equal timestamps, more than 100 records and page links. | Explicit: descending timestamp then ID, 25 events per page, matching totals across all pages and retained filters. |
| Export | The current page, oversized results and spreadsheet-sensitive text can change the apparent evidence. | Explicit: export all matches up to 10,000, reject larger exports and prefix sensitive text with an apostrophe. Preserve commas and line breaks through CSV quoting. |
| Privacy | An audit export can silently include unrelated account, report or provider data. | Explicit: moderator or admin access, no-store responses and fixed export fields. No emails, original report notes, financial records or provider input. |
| Interpretation | Event counts can silently become reviewer rankings or unique-post totals. | Explicit: label counts as events, include trusted creation and resubmissions, and exclude performance claims. Read/export actions never change content, funding or immutable history. |

The decision-log probes cover six applicable items, all explicitly resolved. No backstop or judgment items remain in this increment. [Escalations](moderation-escalations.md) retain private handoffs separately. Content decisions made through an escalation also enter this log. Specialized admin overturns and broader reviewer analytics remain separate work.
