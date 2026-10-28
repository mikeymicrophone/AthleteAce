# Entity-code and seed-library decisions

October 5, 2026. These decisions supersede conflicting language in the broader proposal. This is also the decision record for a future Linear handoff; it does not indicate that Linear issues or access grants have been created.

## Catalogs and compatibility

`ASC` (Ascent), `SPD` (Spindrift), and `STC` (Stickers Club) are settled catalog tokens. Tokens, numeric assignments, and recipe scopes can still change before launch and publication of a usage guide while all consumers can be synchronized. Assigning numbers now is low-stakes; exhaustive advance scope planning is unnecessary. Launch plus published usage guidance establishes the compatibility commitment.

The current manifest envelope is `micharisma-seeds/v1` for YAML and JSON. All current examples use that format. The former `mic-seed-proposal/1` envelope is historical, unsupported by the installed reader, and should not be used for new manifests.

Evidence links use document-relative paths within AthleteAce and GitHub branch links for other repositories. Mac-only paths are removed. References not published on the linked branch are labeled as unpublished audit sources rather than given broken GitHub links.

Sequence choices accept a string, two integers, or a family selected first and its member later. Names for those numbers live in YAML terminology and can also configure the parser. Ruby filenames use `micharisma_`; class spelling retains `MICharisma`.

## Cross-catalog scope

Defer cross-catalog fetching/import adapters until a concrete feature will use them. The first planned crossover is **Mile Pace Tracks ↔ Spindrift**. Its design should follow the user's actual primitives when that feature is defined; this decision does not specify those primitives or an adapter today.

Until support exists, importable manifests remain self-contained within their catalog. Qualified cross-app references may appear as documentation examples only. AthleteAce ↔ Stickers Club teaching/practice claims remain future examples rather than the first crossover implementation.

## Ascent identities

- **Fusion voting:** one `Candidacy` per person, office, and election, with multiple parties attached. Approval voting treats that as one candidacy. Printed party lines do not receive separate coded `BallotLine` entities in this design.
- **Person coverage:** the same Person identity scheme covers candidates, voters, appointed officials, pundits, and foreign officials. Roles are separate from person identity. This does not make voter accounts or other private records public seed data.
- **Person usernames:** prefer the person's Instagram handle. For someone without one, use AI to propose a username absent from the available Instagram data and check uniqueness in our own registry. A generated username is a local identity label, not an assertion that the person owns an Instagram account. Display names remain ordinary attributes; common surnames do not establish uniqueness.
- **Handle changes:** process an update request rather than treating the changed handle as a different person. Preserve the Person binding; retaining previous code spellings as aliases is the proposed mechanism. Handle encoding, verification, reassignment, and conflicting requests still need implementation rules. Absence from captured Instagram data does not guarantee global availability.
- **Other identity options raised:** legal address, Social Security number, and email address were mentioned for the Linear discussion. No decision was made to put these in public codes or public manifests.
- **Election amendments:** amended certifications update the same Election and keep its identity. For the launch's mirrored 2026 slate, withdrawn candidacies or those removed by a complete superseding certification become inactive by default, retaining their records/history. Ordinary partial seed files do not imply deactivation by omission. Amendment storage and source-precedence rules remain to be designed.
- **Certification status:** `certified`, `tentative`, or `unofficial` is an updateable attribute, excluded from the Election's EntityPath. A change in certification status does not create a new Election identity. The exact storage location and implementation remain to be designed.
- **Clerk access:** Ascent Clerk is approved to have read access to private `micharisma_seeders`. Provisioning and verification of that access remain separate operational work.
- **Initial sequences:** start with `10_01` for Ascent Person lookup and `10_02` for Ascent Office lookup. These are approved starting assignments, editable before launch. The installed registry remains the authority for executable recipes; these Ascent entries and their persistence adapter are not installed yet. Their exact parser slot arrays must match the adapter when added.
- **Lookup and optional registry:** parse structured codes into components and resolve those components against scoped fields on entity models. A separate EntityCode/CatalogCode binding table is not required for the initial Ascent design; reconsider it at greater volume or when explicit alias bindings warrant it. Similarity to the legal-citation name `OfficialCode` is not a concern, and no naming change is required merely to avoid that similarity. AthleteAce's existing EntityCode table remains implemented; this decision does not request removing it. Storage for historical handle aliases remains to be designed.
- **Naming option:** `EntityPath` is another candidate name, emphasizing the structured components followed to resolve an entity. The user has not selected a final name or requested renaming AthleteAce's existing model.
- **URI model:** think of the reference as a URI: namespace, catalog, and a structured path resolved to an entity. A future public address can expose that identity; no URI scheme or public route has been implemented by this decision.

## Election simulation and participation

Ascent simulates approval-voting elections. Users should be able to set up experiments with their chosen slates, including people outside the official ballot. Mirroring the 2026 slate is the launch default, rather than a permanent restriction on experiments.

Three candidacy participation options are approved (labels and enum implementation are still to be designed):

| Option | Approval behavior |
| --- | --- |
| Active | Included and approvable in the selected slate. The launch default mirrors the official slate. |
| Inactive | Deactivated for that slate; records and prior history remain available. |
| Off-ballot, approvable | Included and approvable, with voters clearly informed that the person is currently off the official ballot. |

Administrators can use the third option to include other pertinent names. Experiments can select withdrawn/off-ballot people without presenting them as officially on the ballot. Official ballot facts and experiment inclusion must remain distinguishable; a seed refresh of the official slate should not erase an experiment's chosen membership. These are candidacy/experiment options, not global Person activation, and are unrelated to AthleteAce's roster Activation model. Exact schema and transitions remain implementation work.

## Seed update policy

Many attributes should be filled or refreshed during seed replay, including fields initially left blank by an official source. Update behavior is configurable per attribute; some attributes will remain protected. Filling a permitted field does not require a manual amendment on every replay.

The protected-field list, clearing behavior for incoming nulls, source precedence, and stale-source handling remain to be specified. Do not infer that every field is updateable or that the last file wins. AthleteAce's current pilot still preserves differing existing values and reports conflicts; per-attribute update behavior is an approved next capability, not implemented behavior.

## Discrepancies and candidate inclusion

Name discrepancies should use a disambiguation layer following the pattern seen in Spindrift. Track source spellings and resolve their person associations explicitly; do not treat every spelling difference as another person or silently merge ambiguous people. The specific Ascent layer remains to be designed.

When the discrepancy concerns whether an entire candidate belongs in the slate, default to adding all potentially valid options. Preserve the uncertainty/source distinctions for judgment rather than silently selecting one source's candidate list. Inclusion does not by itself establish certified official-ballot status. This is compatible with the off-ballot-but-approvable simulation option; confirmed withdrawals still follow the mirrored-slate defaults above.

These decisions belong in the conversion task. They do not select an automatic `conflicts.csv` → amendment-draft workflow for every discrepancy; other attribute conflicts and source-precedence rules remain open.

## Raw captures and the Linear follow-up

Preserving everything is not a universal default. Retention and update policies should follow the data's purpose. The current NY/MA/CT/VA CSV captures are acceptable where they are, outside the repository; no move into the seed repo or blanket archival requirement is approved.

Convert those captures into `.yml` seeds using `micharisma-seeds/v1` and catalog `ASC`, specified as completely as the evidence permits. Conversion should surface additional inconsistencies, ambiguous mappings, and judgments for discussion rather than silently settle them. This work is intended for later today, October 5, 2026; continue the design questions before implementing it.

Ready-to-post Linear task: **Convert NY/MA/CT/VA captures into Ascent YML seeds and surface judgments**.

- Map the existing captures to the shared envelope, scoped references, and approved Ascent identities; file names do not determine identity.
- Consolidate fusion-party rows into one Candidacy with multiple parties, following the decisions above.
- Generate well-specified `.yml` records and flag missing evidence, conflicting official values, ambiguous people/offices, unmapped fields, and policy decisions still needed.
- Use a Spindrift-style name-disambiguation layer for source spelling discrepancies. When sources disagree on an entire candidacy, provisionally include all potentially valid options and expose their uncertainty instead of silently discarding one.
- Apply the approved mirrored-slate and experiment distinctions; do not silently erase experiment choices or guess the protected/updateable field policy.
- Treat certification status as an updateable attribute rather than an Election identity component; changing that status keeps the same EntityPath.
- Start from the [quick Ascent adapter sketch](ascent-seed-adapter-sketch.md), then iterate on real captures to resolve additional schema nuance. Its recipes and field names are provisional, not a finalized import contract.
- Keep capture location/retention a separate decision. Moving raw CSVs into the repo is not an acceptance requirement.
- Use a broader New York validation pilot: statewide contests plus multiple Assembly, state Senate, and U.S. House races, prioritizing competitive races or races with multiple candidates where practical. No particular contest list or competitiveness metric has been selected yet. Keep the converter suitable for the available four-state capture set.

Posting status: saved here for the handoff, **not created in Linear**. Rechecked on October 5 after the user asked about newly available Ascent access: the tool metadata still lists five accounts, and their full team inventories expose Magicbook, Athlete Ace, Spindrift, Mile Pace Tracks, and Stickers-club, with no Ascent team. Post this task when the intended Ascent connection is exposed to this chat.

## Optional source URLs

Citation URLs are not required on seed records. The public catalog data, including obscure clubs and DJs, does not need a mandatory per-record citation field. The optional manifest `source` mapping can still carry URLs when useful, and shared metadata can be inherited from file/group scope.

A URL log is a possible place to retain acquisition references. As Spindrift's scrape/parse skills develop, consider persisting families of URLs in their respective buckets. This is a future workflow idea, not a selected bucket layout, storage implementation, or requirement to preserve every URL. Absence of a citation URL should not itself block conversion or import.

Capture/import timestamps belong in the replay discussion and can be recorded in run logs without repeating them on every record. The user expects timestamps may become a major factor in rerunning the full seed library. Git timestamps might be sufficient, or explicit timestamps may need to go into `.yml`; experiments will determine the storage and interpretation. There is no fixed per-record timestamp requirement or universal newest-timestamp-wins rule selected now. Timestamp-based freshness/precedence remains future design work alongside the per-attribute update policy.

## Fan lookup

Jev stays in the plan for interpreting fan-constructed codes, including shorthand and flexible league spellings. Its exact integration remains to be designed. Fan interpretation must resolve to a validated entity reference; deterministic seed replay does not depend on an online interpretation service.

## Remaining discussion, one topic at a time

The naming concern, default handling of withdrawals, portable evidence links, deferral of cross-catalog work, raw-capture conversion direction, broader New York pilot scope, name-disambiguation direction, inclusive handling of candidate-list discrepancies, optional citation URLs, experimental approach to timestamps, and separation of certification status from identity are resolved. A [quick Ascent adapter sketch](ascent-seed-adapter-sketch.md) is approved as a starting point; iterate on real data to work out additional schema nuance. Remaining implementation/design topics include:

- Amendment authoring and conflicts-file workflow; source precedence and update rules.
- Refining the provisional Ascent adapter recipes and schema through actual capture conversion and replay.
- Timestamp storage/interpretation during experiments, alongside source-precedence and per-attribute update rules.
- Publication of the registry/usage guide and the final fan-facing person lookup details.

See [the broader proposal](entity-codes-and-seed-library-proposal.md) and [the implemented AthleteAce contract](yaml-seed-library.md) for scope and implementation details.
