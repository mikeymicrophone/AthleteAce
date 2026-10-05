# Entity-code and seed-library decisions

October 5, 2026. These decisions supersede conflicting language in the broader proposal. This is also the decision record for a future Linear handoff; it does not indicate that Linear issues or access grants have been created.

## Catalogs and compatibility

`ASC` (Ascent), `SPD` (Spindrift), and `STC` (Stickers Club) are settled catalog tokens. Tokens, numeric assignments, and recipe scopes can still change before launch and publication of a usage guide while all consumers can be synchronized. Assigning numbers now is low-stakes; exhaustive advance scope planning is unnecessary. Launch plus published usage guidance establishes the compatibility commitment.

The current manifest envelope is `micharisma-seeds/v1` for YAML and JSON. All current examples use that format. The former `mic-seed-proposal/1` envelope is historical, unsupported by the installed reader, and should not be used for new manifests.

Sequence choices accept a string, two integers, or a family selected first and its member later. Names for those numbers live in YAML terminology and can also configure the parser. Ruby filenames use `micharisma_`; class spelling retains `MICharisma`.

## Ascent identities

- **Fusion voting:** one `Candidacy` per person, office, and election, with multiple parties attached. Approval voting treats that as one candidacy. Printed party lines do not receive separate coded `BallotLine` entities in this design.
- **Person coverage:** the same Person identity scheme covers candidates, voters, appointed officials, pundits, and foreign officials. Roles are separate from person identity. This does not make voter accounts or other private records public seed data.
- **Person usernames:** prefer the person's Instagram handle. For someone without one, use AI to propose a username absent from the available Instagram data and check uniqueness in our own registry. A generated username is a local identity label, not an assertion that the person owns an Instagram account. Display names remain ordinary attributes; common surnames do not establish uniqueness.
- **Handle changes:** process an update request rather than treating the changed handle as a different person. Preserve the Person binding; retaining previous code spellings as aliases is the proposed mechanism. Handle encoding, verification, reassignment, and conflicting requests still need implementation rules. Absence from captured Instagram data does not guarantee global availability.
- **Other identity options raised:** legal address, Social Security number, and email address were mentioned for the Linear discussion. No decision was made to put these in public codes or public manifests.
- **Election amendments:** amended certifications update the same Election and keep its identity. The user has not yet chosen the amendment ledger, source-precedence rules, or handling of removed/withdrawn candidacies.
- **Clerk access:** Ascent Clerk is approved to have read access to private `micharisma_seeders`. Provisioning and verification of that access remain separate operational work.
- **Initial sequences:** start with `10_01` for Ascent Person lookup and `10_02` for Ascent Office lookup. These are approved starting assignments, editable before launch. The installed registry remains the authority for executable recipes; these Ascent entries and their persistence adapter are not installed yet. Their exact parser slot arrays must match the adapter when added.
- **Lookup and optional registry:** parse structured codes into components and resolve those components against scoped fields on entity models. A separate EntityCode/CatalogCode binding table is not required for the initial Ascent design; reconsider it at greater volume or when explicit alias bindings warrant it. Similarity to the legal-citation name `OfficialCode` is not a concern, and no naming change is required merely to avoid that similarity. AthleteAce's existing EntityCode table remains implemented; this decision does not request removing it. Storage for historical handle aliases remains to be designed.

## Seed update policy

Many attributes should be filled or refreshed during seed replay, including fields initially left blank by an official source. Update behavior is configurable per attribute; some attributes will remain protected. Filling a permitted field does not require a manual amendment on every replay.

The protected-field list, clearing behavior for incoming nulls, source precedence, and stale-source handling remain to be specified. Do not infer that every field is updateable or that the last file wins. AthleteAce's current pilot still preserves differing existing values and reports conflicts; per-attribute update behavior is an approved next capability, not implemented behavior.

## Fan lookup

Jev stays in the plan for interpreting fan-constructed codes, including shorthand and flexible league spellings. Its exact integration remains to be designed. Fan interpretation must resolve to a validated entity reference; deterministic seed replay does not depend on an online interpretation service.

## Remaining discussion, one topic at a time

The naming concern is resolved: similar names to `OfficialCode` are acceptable, and a separate Ascent binding table is optional. The next topic is superseded certifications and withdrawals. Remaining topics include:

- Superseded certifications, withdrawals, amendment authoring, and conflicts-file workflow.
- Public person lookup and the limits of common-name fan constructions under the username decision.
- Portable repository links in the proposal's evidence section.
- Cross-catalog adapters and how to represent links until they exist.
- Mapping the NY/MA/CT/VA raw captures into the manifest envelope through generators.
- Publishing the live sequence table separately from candidate recipes.
- A small Ascent pilot with Person, Office, Election, and Candidacy; the earlier BallotLine proposal is superseded.
- Required source metadata, certification status as observation metadata, and an Ascent adapter sketch.

See [the broader proposal](entity-codes-and-seed-library-proposal.md) and [the implemented AthleteAce contract](yaml-seed-library.md) for scope and implementation details.
