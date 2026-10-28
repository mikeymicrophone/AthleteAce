# Admin content catalog

`/admin/content-catalog` lists quests, achievements, and rating spectrums in one paginated directory. It requires an active admin and sends private, no-store responses. Admin navigation, the overview, and the Admin search destination named **Content catalog** open this directory. Public Browse remains available separately.

## Records and filters

The directory includes pending, approved, rejected, and hidden records, including the viewing admin's own content. The three totals show all records of each type across all statuses. The matching-record count and rows reflect the selected filters.

The filters combine:

- **Search content** matches names and descriptions without case sensitivity. Search accepts up to 80 characters and treats percent signs and underscores literally.
- **Content type** selects quests, achievements, or spectrums. The default includes all three.
- **Status** selects one recorded moderation state. The default includes all states.
- **Creator** selects a recorded creator. **System or deleted account** selects records without a current creator reference; it does not identify why that reference is absent.
- **Sort** defaults to recently updated first. **Name** sorts without case sensitivity. Both sorts use type and record ID to break ties.

Pages contain up to 25 records. Pagination retains the filters and sort. **Clear** resets them. Rows show the type, name, description, status, revision, creator, and UTC update time. Spectrum endpoints and achievement targets appear when applicable. On phones, table rows become labeled cards.

## Existing editing and review workflows

The name opens the existing detail page in the Admin shell. **Edit** opens the existing editor. **New quest**, **New achievement**, and **New Spectrum** open their existing creation forms. These links retain the existing posting, editing, and resubmission rules.

**Review & history** opens the record in Moderate with its current status and type selected. Review still forbids deciding one's own submission. An open escalation links to its case only when the admin can view it. Resolution restrictions and immutable decision history remain in the existing moderation services.

Quest, achievement, and spectrum records do not currently have alias fields or a merge model. This directory adds no alias or merge controls. Duplicate merging remains deferred under AA-196. [Moderation oversight](admin-moderation-oversight.md) provides recorded transition counts and pending-wait measurements. Formal appeal-linked overturn analytics remain separate work under AA-207 and AA-203.
