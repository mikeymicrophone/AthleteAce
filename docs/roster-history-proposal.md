# Organization contracts and team participation

October 6, 2026. The approved migrations and accompanying models/importer are implemented. Both migrations were applied to `athlete_ace_development_seedtest_20261005`. That database had zero legacy Contracts, so no historical organization mappings had to be guessed. The test schema includes both migrations as well.

The migration files are:

- [Add organization contracts and team participation](../db/migrate/20261006000000_add_organization_contracts_and_team_participation.rb)
- [Require contract organizations after reconciliation](../db/migrate/20261006000001_require_contract_organizations.rb)

## Record meanings

| Record | What it establishes |
| --- | --- |
| OrganizationAffiliation (existing) | A dated team-to-organization relationship. Its current overlap restriction stays in place; simultaneous affiliations are deferred. |
| Contract | A player's agreement with an Organization. The legacy Team link is retained during transition. |
| Activation (existing) | One player's known membership in a Campaign, which is a Team in a Season. This remains a seasonal summary, not a dated stint or current roster. |
| Stint | A continuous assignment to a Team, with optional known bounds, status, Contract, and initiating/ending Transaction. A return creates another stint. Stints can cross seasons. |
| Roster | An established list for a Campaign and roster category, with an effective date, observation time, source, and completeness label. |
| RosterEntry | A player included in that particular list, optionally linked to an independently established Stint. Its status and jersey number are facts about that roster observation. |
| Appearance | A player's participation for a particular Contestant in a game. It carries game statistics and facts; an optional Stint provides assignment context. |
| Transaction / TransactionPlayer | An event and its player movements. One trade can have several players moving in different directions. Organization movement and team assignment movement can be recorded independently. |

A RosterEntry is an observation, not automatically a denormalized copy of a Stint. A source can establish a roster without establishing assignment dates, and a player can be listed without appearing in a game. A cached current-roster view can be built later from these facts with an explicit selection policy.

Roster categories and transaction kinds are strings rather than fixed sport-specific enums. Coverage labels are `unknown`, `partial`, and `complete`. Completeness applies only to the list's stated category and effective date; absence from a partial list is not evidence of removal.

## Existing contests

The [competition/game extension](competition-games.md) adds JSONB format rules, a Game subclass preserving existing game identities, per-competition game metadata and explicit title awards. It supports cross-league cup entries without duplicating team-season Campaigns. The original participation semantics below still apply.

Contest and Contestant model an event/competition and its participating Campaigns. `Contest.kind` distinguishes games from series, tournaments, and other aggregates. Existing kinds remain unknown rather than being guessed. An Appearance references Contestant, which identifies both its game and team-season; two games on the same day remain distinct.

Appearances require `kind: game`. A Contest with appearances cannot be reclassified, or moved outside linked known stint dates. Changes to a Stint, Roster, or Contestant also check their linked participation. Scheduled fixtures, game outcomes, and sport-specific statistical validation still need their own model rules.

`Appearance.statistics` is a flexible JSONB mapping for sourced game statistics. Published season totals cannot establish individual appearances and must not be expanded into invented games or copied to every appearance. Unknown starter status stays NULL. Jersey numbers are strings, preserving `0` and `00`.

## Contract transition

The first migration adds nullable `contracts.organization_id`, makes the legacy Team link optional, and temporarily requires at least one counterparty link. The second migration requires Organization for every Contract. New application writes require an Organization; the optional legacy Team link remains available for compatibility. Removing a legacy Team nullifies that link instead of deleting the Organization's Contract. Contract pages display the Organization, and support filtering by it.

Verified organization mappings must be supplied before the second migration requires Organization for every Contract. Do not infer the contracting party from today's Team affiliation, corporate ownership, or an appearance. The follow-up migration refuses unresolved contracts. It retains the legacy Team column as historical information; removal can be reviewed after its facts have been preserved.

The existing seasonal Activation rows, their preferred codes, and their one-player-per-Campaign uniqueness remain untouched. Do not turn a coarse season membership into a Stint, roster snapshot, or Appearance without evidence establishing that finer fact.

## Implemented model and importer rules

- A Stint's Contract identifies the same Player. A linked Stint matches a RosterEntry's Player and roster Team, or an Appearance's Player and contestant Team. Known stint dates agree with the roster's effective date or game's begin date; observation timestamps are not substituted for unknown effective dates.
- A loan's borrowing Team need not belong to the contracting Organization. Organization affiliations and contractual/assignment facts remain distinct.
- The importer supports all newly coded types, resolves Contest's polymorphic context through typed codes, persists inherited source metadata on tables with a `source` column, and preserves edits during replay. Codes remain nullable for uncoded application records.
- TransactionPlayer calls its Transaction association `event`, avoiding Active Record's existing `transaction` method. Its database foreign key is still `transaction_id`.
- Importing a Transaction does not derive Stints, contract terms, or roster changes. All new types participate in core reset classification; ordinary `db:seed` never resets them.

No date bounds are fabricated. Stint bounds are inclusive dates and do not claim ordering within a day. Multiple observed same-day moves can remain separate events, with exact times preserved in source/details until an explicit timestamp policy is adopted. An unknown end date alone does not assert that a Stint is current. Exact-date roster and assignment queries must acknowledge unknown bounds.

The first migration's rollback refuses organization-only Contracts rather than inventing Team links. Dropping the new tables would remove their data.

## Core seed coverage

`yaml/participation/` adds 114 sporting-club Organizations and primary-team affiliations without asserting corporate ownership or historical affiliation dates. It has 82 NBA/NFL/EPL roster observations and 279 listed players from the existing coverage capture. NHL's archived season participant lists remain Activations, not roster observations.

A sourced Leddy example adds his March 21, 2022 trade, an assignment starting that day with unknown end, a July 13 contract-extension announcement, a March 22 game and appearance, and two players from the Blues' published October opening-night roster. The extension's precise legal date bounds stay unknown. It is not linked as the original contract for the earlier assignment. The trade's TransactionPlayer coverage is explicitly partial. No appearances are fabricated for the other seasonal memberships.

The October 6 bundle had 21 manifests, 1,649 definitions, and 1,654 code bindings. The later Play supplement and current totals are recorded in [the seed library guide](yaml-seed-library.md#coverage-and-remaining-launch-work). It preserves the existing 114 Teams and 361 Players, with 126 Campaigns and 384 Activations. Seed import added 606 records; replay created zero records with zero conflicts.

October 6 verification: the full local Rails suite passed 373 examples with zero failures. Rails eager loading and lint for the 14 new Ruby files passed. Offline organization/roster regeneration was byte-for-byte identical. All 1,654 code bindings resolve to their records in the development seed-test database.
