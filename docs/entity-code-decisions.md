# Entity-code and seed-library decisions

October 5, 2026. These decisions supersede conflicting language in the broader proposal. This is also the decision record for a future Linear handoff; it does not indicate that Linear issues or access grants have been created.

## Catalogs and compatibility

`ASC` (Ascent), `SPD` (Spindrift), and `STC` (Stickers Club) are settled catalog tokens. Tokens, numeric assignments, and recipe scopes can still change before launch and publication of a usage guide while all consumers can be synchronized. Assigning numbers now is low-stakes; exhaustive advance scope planning is unnecessary. Launch plus published usage guidance establishes the compatibility commitment.

The current manifest envelope is `micharisma-seeds/v1` for YAML and JSON. All current examples use that format. The former `mic-seed-proposal/1` envelope is historical, unsupported by the installed reader, and should not be used for new manifests.

Evidence links use document-relative paths within AthleteAce and GitHub branch links for other repositories. Mac-only paths are removed. References not published on the linked branch are labeled as unpublished audit sources rather than given broken GitHub links.

Sequence choices accept a string, two integers, or a family selected first and its member later. Names for those numbers live in YAML terminology and can also configure the parser. Ruby filenames use `micharisma_`; class spelling retains `MICharisma`.

## Ascent identities

- **Fusion voting:** one `Candidacy` per person, office, and election, with multiple parties attached. Approval voting treats that as one candidacy. Printed party lines do not receive separate coded `BallotLine` entities in this design.
- **Person coverage:** the same Person identity scheme covers candidates, voters, appointed officials, pundits, and foreign officials. Roles are separate from person identity. This does not make voter accounts or other private records public seed data.
- **Person usernames:** prefer the person's Instagram handle. For someone without one, use AI to propose a username absent from the available Instagram data and check uniqueness in our own registry. A generated username is a local identity label, not an assertion that the person owns an Instagram account. Display names remain ordinary attributes; common surnames do not establish uniqueness.
- **Handle changes:** process an update request rather than treating the changed handle as a different person. Preserve the Person binding; retaining previous code spellings as aliases is the proposed mechanism. Handle encoding, verification, reassignment, and conflicting requests still need implementation rules. Absence from captured Instagram data does not guarantee global availability.
- **Other identity options raised:** legal address, Social Security number, and email address were mentioned for the Linear discussion. No decision was made to put these in public codes or public manifests.
- **Election amendments:** amended certifications update the same Election and keep its identity. For the launch's mirrored 2026 slate, withdrawn candidacies or those removed by a complete superseding certification become inactive by default, retaining their records/history. Ordinary partial seed files do not imply deactivation by omission. Amendment storage and source-precedence rules remain to be designed.
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

## Fan lookup

Jev stays in the plan for interpreting fan-constructed codes, including shorthand and flexible league spellings. Its exact integration remains to be designed. Fan interpretation must resolve to a validated entity reference; deterministic seed replay does not depend on an online interpretation service.

## Remaining discussion, one topic at a time

The naming concern, default handling of withdrawals, and portable evidence links are resolved. The username decision addresses common-name identity collisions. The next topic is cross-catalog references. Remaining topics include:

- Cross-catalog adapters and how to represent links until they exist.
- Mapping the NY/MA/CT/VA raw captures into the manifest envelope through generators.
- A small Ascent pilot with Person, Office, Election, and Candidacy; the earlier BallotLine proposal is superseded.
- Amendment authoring and conflicts-file workflow; source precedence and update rules.
- Required source metadata, certification status as observation metadata, and an Ascent adapter sketch.
- Publication of the registry/usage guide and the final fan-facing person lookup details.

See [the broader proposal](entity-codes-and-seed-library-proposal.md) and [the implemented AthleteAce contract](yaml-seed-library.md) for scope and implementation details.
