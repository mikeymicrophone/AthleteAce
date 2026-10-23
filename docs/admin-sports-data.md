# Admin sports data

Admin **Sports data** provides player and team search, editing, and correction history. Fans and moderators cannot access these pages. Responses use private, no-store cache headers.

## Directory

The player directory supports name, nickname, and entity-code search, plus league, current team, exact current position, activity, photo, and edit-history filters. Activity is Active, Inactive, or Unknown. Photo presence means at least one nonblank stored URL, without fetching that URL. Team and position filters describe current player fields, not historical rosters.

The team directory supports name, abbreviation, and entity-code search, plus league and edit-history filters. It shows division, current player count, colors, and stadium. Teams have no activity field. **Other sports data** opens the existing catalog for other sports entities.

Search treats SQL wildcards literally and uses at most 80 Unicode code points after trimming. Both directories sort by name with ID as the tie-breaker and paginate 25 records at a time. Invalid filter values return HTTP 400. An unsupported record kind returns HTTP 404.

## Save and explain a correction

Player edits support first name, last name, nicknames, birthdate, current position, debut year, draft year, activity, biography paragraphs, and photo URLs. Team edits support territory, mascot, abbreviation, founded year, website URL, logo URL, and primary and secondary colors. Entity codes, associations, jersey assignments, and historical participation are not editable through these forms.

Optional blank values clear the field. Blank array input becomes an empty array. Array fields accept one nonblank entry per line, with up to 30 entries. Nicknames allow 100 code points per entry, biography paragraphs 4000, and photo URLs 2048. Names and position allow 100 code points, abbreviations 16, and other URLs 2048. URLs require an HTTP or HTTPS scheme and host. Years require four digits starting at 1000, birthdates require a valid `YYYY-MM-DD` date, and colors require six-digit hex values. At least one name component must remain present.

**Save changes** immediately updates the record and creates one `CatalogEdit` in the same PostgreSQL transaction. The next page shows the saved before/after values and asks **Why did you make this change?** The catalog update survives navigation away from that prompt. **Skip for now** leaves **Reason not supplied** in correction history.

The original admin can open that exact edit later and submit a reason. The form updates the `CatalogEdit` ID in its URL, even if another catalog save has happened in the meantime. Reasons allow 1–2000 Unicode code points after trimming. The first submitted reason and its timestamp stay fixed. Repeating that same explanation succeeds without changing its timestamp. Another explanation returns HTTP 409. Other admins can inspect the edit but cannot supply its author's reason.

## Audit and concurrent saves

Each edit captures the original record type, numeric ID, entity code, name, editor name and handle, changed before/after values, and creation time. These captured fields are read-only through the model. The current editor reference can become null after account deletion. Deleting the player or team retains the correction snapshot. Team edits also capture derived text-color changes.

The save service locks the acting account and catalog record, reloads their state, and requires an active admin. A digest of the loaded record detects stale forms. A stale save returns HTTP 409 with a reload link. A repeated request with the same admin, key, record, and normalized submitted values returns the original edit. A changed request cannot reuse that key. A save with no changed values produces no audit entry. An audit failure rolls back the catalog update.

Recent corrections and the directory's **Has edit history** filter match records by stable entity code. Uncoded records fall back to numeric ID. That fallback cannot identify the original subject after a reset reuses the ID. Their global audit snapshots remain available, but an operator must resolve uncoded identities manually. Edit history means a change occurred, not that it is still absent from the seeds.

## Export and seed maintenance

Run the export against the database whose corrections you need:

```sh
mise exec -- ruby -S bundle exec rails catalog_edits:export > /tmp/athleteace-catalog-edits.jsonl
```

A nonzero exit means export failed. Standard output contains one JSON object per edit, ordered by audit ID. Standard error reports `Exported N catalog edits`. Zero is valid for an empty log. The task does not update audit rows, seed files, or catalog records.

Each `athlete_ace/catalog_edits/v1` object contains the edit ID, creation time, captured editor identity, captured record identity, exact changed `before` and `after` mappings, reason, and reason timestamp. A missing reason is JSON null. Embedded newlines stay escaped inside a single JSONL line. The captured numeric ID is local to that database. Use the entity code for seed maintenance when available.

Review the log and apply accepted corrections to the seed source manually. For generated manifests, update the generator's input and regenerate the manifest. Keep the export outside the seed library. It is an audit format, not an importable seed manifest. Exporting a row does not acknowledge incorporation. There is no automatic replay, approval gate, per-field override, or GitHub publishing service.

The [existing seed pipeline](yaml-seed-library.md#running-and-replay) remains unchanged. The YAML importer preserves existing differing values and reports conflicts. Photo enrichment fills empty photo arrays. Palette enrichment can overwrite edited team colors. A destructive rebuild loses catalog corrections that have not been incorporated into the seed sources. Core-only resets leave the audit table intact, but a full database reset drops it. The existing `ugc:backup` does not include this log. Retain the JSONL export or a database backup before such operations.

## Acceptance boundaries

Input lengths, empty arrays, unknown activity, literal search, deterministic ordering, and pagination have explicit behavior above. Transactional saves, stale forms, concurrent retries, separate edits on the same subject, missing reasons, and concurrent explanations have automated checks. Audit snapshots remain separate from approval decisions and seed replay. Automatic incorporation status, bulk editing, creation, and additional catalog entity editors remain outside this build.
