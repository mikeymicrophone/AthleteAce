# Admin moderation oversight

`/admin/moderation-oversight` requires an active admin and sends private, no-store responses. **Moderation oversight** opens it from the Admin overview, Content catalog, or Admin search. The page uses the Admin shell with Overview selected. Reading it changes no moderation, content, credit, or escalation records.

## Period and event counts

**From (UTC)** and **Through (UTC)** select inclusive calendar dates. The default is the last 30 days through today. The chart supports up to 366 days. Invalid dates, reversed ranges, future end dates, longer ranges, and unsupported content types return HTTP 400. **Content type** selects a supported moderation type. The page excludes events later than its displayed **As of** timestamp, so today is incomplete.

A review event is one of these recorded transitions:

| Action | Previous state | Next state |
| --- | --- | --- |
| Approved | Pending | Approved |
| Rejected | Pending | Rejected |
| Hidden | Approved | Hidden |
| Reopened | Rejected or hidden | Pending |

Submissions, trusted creation, and content-edit events are excluded. The Admin overview uses the same definition. Counts retain events whose content or actor has since been deleted, and describe events rather than unique submissions or reviewer performance.

The daily chart includes explicit zero days. **Daily values** shows every date and count. The content-type table breaks the counts down by action. Opening a date or count links to the decision log with matching dates, type, action, and **Review transitions only** selected. Its pagination and CSV export preserve the filters. The log's default view still includes other recorded events.

## Pending wait

The median uses approvals and rejections that occur within the selected period. For each decision, the query finds the immediately preceding event for the same subject type, subject ID, and content revision, ordered by timestamp and then event ID.

A pair qualifies when that predecessor records a submission into pending, or a reopening from rejected or hidden into pending. Its timestamp may precede the selected period. Reopening begins another cycle on the same revision. Different revisions, missing starts, intervening decisions, and malformed reopening transitions do not produce a measurement. Equal timestamps can produce a valid zero-second wait.

The page shows matched pairs out of all approval/rejection events. Unmatched events remain in counts but are excluded from the median. With no matched pairs, the median displays **Not recorded**. The displayed duration is rounded with Rails' normal time-distance formatter.

Wait measures elapsed calendar time, including handoffs, rather than active reviewer work. Shout-outs record their submission when credit is reserved; unfunded creation supplies no pending-start event. No review-time target is inferred.

## Later changes and appeal limits

**Later status changes** sums hides and reopenings. These describe publication-state transitions and do not establish that an earlier reviewer was wrong. Formal appeals are not explicitly linked to original decisions, so a formal overturn rate is unavailable. Appeal-linked handling remains separate work under AA-203, and duplicate merging remains deferred under AA-196.
