# Admin sports data

Admin **Sports data** provides player and team search, editing, correction history, and read-only game and competition inspection. Fans and moderators cannot access these pages. Responses use private, no-store cache headers.

## Directory

The player directory supports name, nickname, and entity-code search, plus league, current team, exact current position, activity, photo, and edit-history filters. Activity is Active, Inactive, or Unknown. Photo presence means at least one nonblank stored URL, without fetching that URL. Team and position filters describe current player fields, not historical rosters.

The team directory supports name, abbreviation, and entity-code search, plus league and edit-history filters. It shows division, current player count, colors, and stadium. Teams have no activity field. **Other sports data** opens the existing catalog for other sports entities.

Search treats SQL wildcards literally and uses at most 80 Unicode code points after trimming. Both directories sort by name with ID as the tie-breaker and paginate 25 records at a time. Invalid filter values return HTTP 400. An unsupported record kind returns HTTP 404.

## Inspect dated number assignments

The player directory shows **Assigned number** for each player's current profile team on **Number on date**. The date defaults to the application's current date and stays explicit in the form and CSV download link. Changing it does not change directory membership or reconstruct historical team assignments.

The column uses `JerseyNumberAssignment` records with inclusive date bounds. In that model, a missing start or end is an open bound. Matching assignments load in one query for the displayed page or export. An unassigned player or a player without a matching number assignment displays Unknown. The column does not substitute another team's number or a number observed only in a roster or appearance.

The linked number opens **Number assignments** in Player history. This tab shows every recorded assignment for that player, including team, number, inclusive date range, entity code, source, and details. Missing bounds display **Open start** or **Open end**. Results sort by start date descending, then ID descending, with open starts last, and paginate 25 records. Number assignments do not establish membership, availability, or an actual appearance.

Player CSV exports append `number_on`, `assigned_jersey_number`, and `number_assignment_code`. The date is always explicit. Missing assignments produce blank number and code fields. String numbers such as `00` remain unchanged in the CSV. Spreadsheet importers need to treat the number column as text to retain leading zeroes. Team exports keep their existing columns.

Malformed number dates or years outside 0001 through 9999 return HTTP 400 for HTML and CSV. An explicit number date on the team directory returns HTTP 400. These views do not edit or infer number assignments.

## Trace a player's recorded history

**Player history** opens from the player edit form or a player's row in an Admin game. The page separates the current profile team from six historical tabs: **Stints**, **Contracts**, **Transactions**, **Rosters**, **Appearances**, and **Number assignments**. Each tab shows its full record count and paginates 25 rows. Only records associated with that player appear.

Stints show recorded team assignments, date bounds, status, linked contract organization, and explicitly linked start and end transactions. An unknown end date does not prove a current assignment. Contracts show the organization, dates, optional legacy team, and recorded details. Neither record establishes game availability.

Transactions show the player's entry in each recorded event, including kind, effective date, organization and team endpoints, event metadata, and player-entry details. Effective dates use the existing day-resolution `effective_on` field. The page does not fabricate exact event times or apply transactions to stints or contracts. A transaction linked from a stint can appear there without a corresponding player-entry record in the Transactions tab.

Rosters show campaign and season, roster kind and coverage, effective date, UTC observation time, availability status, jersey number, and metadata. Roster observations remain separate from actual appearances. Appearances show the recorded game, campaign and season, jersey number, starter status, statistics, and metadata. Game links open the Admin game page. Missing records do not establish absence or eligibility.

Tabs sort by their effective, start, or game date descending, with unknown dates last. Record IDs break ties deterministically. Unknown dates and starter status remain Unknown. Recorded zero statistics and jersey number `00` remain intact. Observation source and detail mappings are escaped JSON inside expandable sections. Contracts have a details field without a separate observation source.

The history route requires an admin and returns private, no-store cache headers. Invalid tabs return HTTP 400, and missing players return HTTP 404. These views do not edit history, infer stints from current teams, replay transactions, or change seed records. **Edit profile data** returns to the existing audited correction form.

## Inspect competitions and title awards

**Competitions** lists stored competitions separately from Games. Search matches names and preferred entity codes, treats wildcards literally, and uses at most 80 code points. Filters cover exact stored kind, participating season, participating team, and presence of recorded title awards. Kind options come from stored competition records. Unknown kinds return no matches.

Team and season filters match the same entrant campaign. A cross-league cup can match several participating seasons while its own assigned season remains unset. The assigned season column reports the stored field only. Results show recorded entrant, linked game, and title-award counts without loading every entrant. Competitions sort by start date descending, then ID descending, with unknown dates last. Each page contains up to 25 competitions. Invalid filter shapes, IDs, or title filters return HTTP 400.

Competition detail shows context, dates, assigned season, format rounds, and all stored format rules. Custom JSON fields remain visible in **All recorded rules**. **Entrants** shows campaign names and seasons, placing, wins, and losses. Unknown standings remain Unknown; recorded zeroes stay zero. **Title awards** shows each recorded title's name, key, code, winning campaign, season, and award date. Both tabs paginate 25 records at a time.

Title records are the source for award counts and winners. Standings, legacy champion fields, and missing records do not create implied awards. **View games** opens the Games directory with this competition selected. Game membership links return to the Admin competition page, including round and game-number summaries.

These pages require an admin, return private, no-store cache headers, and do not change competition, award, game, or seed records. Editing competitions, generating schedules, and assigning title awards remain outside this view.

## Inspect games and participation

**Games** opens the schedule directory. Search matches game names and preferred entity codes, with literal wildcard handling and an 80-code-point limit. Filters cover competition, participating season, participating team, inclusive start-date bounds, and presence of recorded appearances. Team and season must match the same participating campaign. This supports cross-league games without relying on a game-level season or the teams' current league assignments.

Each game appears once, even with multiple participants or competition memberships. Results show campaign names, season names, competition round summaries, and recorded appearance counts. Games sort by start date descending, then ID descending, with unknown dates last. Each page contains up to 25 games. Invalid filters or inverted date ranges return HTTP 400.

A game detail page separates **Appearances** from **Roster entries**, with 25 entries per page. Appearances show recorded player, campaign, jersey number, starter status, and statistics. Unknown starter status stays Unknown. The directory's appearance filter checks for any recorded appearance, not complete participation coverage.

Roster entries come from observations whose `details.game_code` exactly matches the game's preferred `entity_code` and whose campaign participated in that game. The page shows roster kind, coverage, effective date, observation time, entry status, jersey number, and entry details. A game without an entity code has no matched roster observations. Alias-code resolution and a normalized roster-to-game association remain outside this view.

Same-day rosters, contracts, and current player team fields do not establish game availability or actual participation. Missing appearances do not establish that nobody played. Missing roster entries do not establish absence. These pages read existing records without creating, repairing, or reseeding them. All routes require an admin and return private, no-store cache headers.

## Download filtered catalog data

**Export filtered CSV** downloads every matching player or team, regardless of the current table page. The download preserves the directory's filters and name/ID ordering. Empty results produce a header-only CSV. Exports above 10,000 records return HTTP 400 with a request to narrow the filters; they never silently truncate. Access and private cache rules are the same as the HTML directory.

Player columns include local record ID, entity code, names, JSON-encoded nicknames, birthdate, current position, activity, sport code/name, current team and league codes/names, JSON-encoded photo URLs, debut/draft years, and UTC update time. Team columns include local record ID, entity code, identity fields, league/division codes and names, colors, current player count, stadium code/name, website/logo URLs, founding year, and UTC update time. Missing scalar values are blank, including unknown activity or missing entity codes. Activity otherwise uses `true` or `false`. Array values retain JSON `null` versus `[]`. Codes are the stored preferred codes; aliases are not exported.

These exports describe current fields and associations. They do not infer assignments from contracts or historical rosters. Local numeric IDs cannot identify records across rebuilt databases. Use entity codes for matching when present. Account identities, correction reasons, biographies, and arbitrary model fields are excluded.

CSV text that starts with a spreadsheet formula marker or leading tab/newline receives an apostrophe prefix, including markers after whitespace. Embedded commas and newlines use CSV quoting. The download does not modify stored values or correction history. This spreadsheet-safe review format is not an importable seed manifest, complete backup, or automatic correction-replay format. The JSONL correction export below retains exact audited changes for seed maintenance.

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
