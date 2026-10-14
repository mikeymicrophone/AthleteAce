# Moderation decisions

This implementation holds new fan-created quests, achievements, highlights, and spectrums for review. Existing records and trusted catalog imports stay approved. Admin-created records are approved on creation. AI results remain recommendations until application-specific evaluations justify automatic clearance.

## Acceptance decisions

| Requirement | Edge or prohibition | Resolution |
| --- | --- | --- |
| Visibility | Anonymous users, other authors, JSON, pickers, nested links, and rating submissions can reveal pending content. | Explicit visibility scopes apply to each entry point. Only the author and reviewers can inspect pending content. |
| Related content | An approved highlight can point at an unapproved achievement. | Public quest requirements include only approved highlights and approved achievements. Pending content cannot change another ace's goal requirements. |
| Attribution | Request parameters can forge authorship or approval. | Controllers assign the signed-in author. Strong parameters exclude moderation fields. |
| Review | Two reviewers act on the same revision. | A row lock, expected status, and revision check reject stale decisions without a second action. Reviewers cannot decide their own submissions. |
| Edits | An approval can silently survive changed content. | Content edits increment the revision and return authored content to pending. Each submission and decision retains its snapshot. |
| AI evaluation | Missing credentials, refusals, malformed responses, timeouts, or edits during a request. | Failures remain visible as failed evaluations. Evaluations retain the captured revision and cannot publish or modify content. |
| Cost | Missing usage can masquerade as a free decision. | Missing usage yields an unknown cost. Estimates use the provider's reported input tokens and a stored rate. |
| Sports data | A model can invent a team, date, identity, or number. | The comparison supplies candidates and evidence with an insufficient-evidence outcome. Evaluations never mutate the sports catalog. |
| Repeated requests | A double click can duplicate paid calls. | The submitted comparison key identifies one evaluation per provider. A new comparison uses a new key and retains earlier results. |
| Calibration | Confidence alone can become an automatic publishing threshold. | Judgment: compare labeled examples and review errors before selecting thresholds. Automatic clearance remains disabled. |
| Coverage | A small sample can be mistaken for measured production accuracy. | Judgment: label the bundled cases as smoke examples. Report completed, failed, and skipped evaluations separately. |

Spec probes covered 11 applicable items. Nine have explicit acceptance behavior and two require judgment. Provider availability and live cost measurements depend on credentials.
