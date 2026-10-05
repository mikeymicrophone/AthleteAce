# YAML seed library pilot

October 5, 2026. The shared reader/parser and AthleteAce database adapter are implemented on `codex/yaml-seasonal-seeding`. The data branch is `codex/yaml-seasonal-rosters`.

The [decision record](entity-code-decisions.md) captures the October 5 review and future Linear handoff. The broader proposal now uses this same `micharisma-seeds/v1` envelope. Approved cross-app behavior is distinguished below from the currently implemented AthleteAce adapter.

## Repositories and responsibilities

- [athlete_ace_data](https://github.com/mikeymicrophone/athlete_ace_data): committed catalog facts and sources, mounted at `db/seeds/athlete_ace_data`. The new `yaml/` library is independent of the existing JSON seed layout.
- [micharisma_seeders](https://github.com/mikeymicrophone/micharisma_seeders): private shared Ruby repository, mounted at `lib/micharisma_seeders`. It reads safe YAML/JSON, merges scopes, normalizes sequences, and parses constructions. It contains no Rails models or database writes. Ascent can reuse it with its own persistence adapter and catalog.
- AthleteAce: the model allowlist, relationship checks, code/alias registry, dependency resolution, and preservation policy in `Seeds::LibraryImporter` and `Seeds::EntitySequenceResolver`.

Filenames and directory names only select input files and identify errors. Renaming or moving a manifest has no effect on fetching. A file can contain several teams, seasons, leagues, or nested groups.

The shared package loads through its explicit entry point. Its complete submodule directory is excluded from Rails' application autoloader, so Rails does not interpret the package's nested `lib/` and `test/` directories as application namespaces. Custom constant spelling such as `MICharismaSeeders` is preserved by the package's own requires.

Brand class filenames use `micharisma_`, including the parser's `micharisma_entity_parser.rb` entry point. AthleteAce registers `MICharisma` as an inflection acronym so brand filenames map to the intended capitalized constants.

## Seasonal data model

`Team` identifies the continuing franchise/club. Its current associations remain available to existing app features. `Season` identifies a league and starting calendar `Year`, with an explicit league-specific label such as `2022_2023` or `2019`.

`Campaign` joins a Team to a Season. Its annual snapshot stores display name, territory, mascot, abbreviation, logo URL, colors, stadium, city, conference, and division. Its league comes from its Season; changing `Team.league` does not move old Campaigns. Its optional `details` mapping allows additional annual metadata. Missing fields are unknown; legacy display fallback to the current Team is convenience, not evidence of historical attributes.

`Activation` directly joins a Player to a Campaign, uniquely per player/campaign. A Contract and exact dates are optional. A traded player can have both teams' whole-season memberships. These records do not assert opening-day presence or appearances in specific games. A loan can retain the parent team's Contract while membership belongs to the borrowing team's Campaign.

`Player.sport` can be known without a current Team. A player's debut-team code is an identity anchor; a later-season roster import does not assign that team as current. Profiles accept these players and show their known Seasons.

Campaign checks prevent a division/conference from a different league entering an annual snapshot. Activation checks reject a conflict with a player's independently recorded Sport. A team's current league is allowed to differ from its historical Campaign league.

## Manifest contract

```yaml
format: micharisma-seeds/v1
namespace: MIC
catalog: ALA
source:
  url: https://www.nba.com/knicks/news/new-york-knicks-acquire-josh-hart
  published_on: "2023-02-09"
scope:
  sport: SPORT-BKT
  league: BKT-LEAGUE-NBA
  year: YEAR-2022
groups:
  - scope: {team: BKT-NBA-TEAM-NYK}
    records:
      - type: Campaign
        code: BKT-NBA-SEASON_2022_2023-TEAM-NYK
        attributes:
          display_name: New York Knicks
          abbreviation: NYK
      - type: Activation
        code: BKT-NBA-SEASON_2022_2023-TEAM-NYK-PLAYER-HART_JOSH
        references:
          player: BKT-NBA-LAL-2017-HART_JOSH
```

The complete bundle must also supply Sport, League, Year, Season, Team, and Player. JSON uses the same structure. Scope merges file → nested groups → row; explicit references override scope. Configuration never enters model attributes. Database IDs and foreign-key attributes are rejected; relationships use codes.

The envelope's `source` mapping is optional, and a citation URL is not required on each record. The example's URL is useful metadata rather than a mandatory field. Source metadata can be shared through file/group inheritance. Acquisition URLs may instead be kept in logs; URL-family buckets are a possible future Spindrift scrape/parse workflow.

Capture/import timestamps can be kept per run in logs. Git metadata may provide the chronology needed for repeated seeding, or explicit `.yml` timestamps may be needed; experiments will settle the storage and replay rules. There is no mandatory per-record timestamp or timestamp-based overwrite behavior implemented by this pilot. The current reader can retain optional date metadata, but timestamp precedence remains future adapter work.

Definition codes and aliases are local, uppercase references. `MIC-ALA` is supplied once by the envelope. References may be qualified with `MIC-ALA-...`. Each coded model stores its preferred local `entity_code`; `EntityCode` enforces catalog-wide code uniqueness and binds aliases to that preferred identity. Codes remain bound when display facts change. Cross-catalog fetching needs a future catalog adapter; the pilot rejects foreign references.

Cross-catalog work is explicitly deferred until a concrete feature needs it. The first planned crossover is Mile Pace Tracks ↔ Spindrift; its primitives and adapter will be defined then. Keep current importable manifests self-contained in their catalog and qualified cross-app references in documentation examples only. AthleteAce/Stickers Club practice links are a later possible use case.

The EntityCode binding table is part of AthleteAce's implemented adapter, rather than a requirement for every consuming app. Ascent's initial direction is parsed constructions plus scoped fields on its models, with a separate binding table optional later. The similarity between the name EntityCode and Ascent's legal-citation OfficialCode is acceptable.

## Optional lookup sequences

The standalone `yaml/entity_sequences.yaml` registry accepts the exact requested layout:

```yaml
01:
  10: [Sport, League, Conference, Division, Year, Team]
```

Quoted decimal keys are equally valid. Both normalize to `"01_10"`; normalized collisions fail. Sequences select slot order, not identity and not database IDs. Slots have variable widths, and underscores remain inside each supplied component. Optional `terminology` names the family/member numbers alongside those numeric recipes:

```yaml
terminology:
  families:
    hierarchy: 1
    athletes: 5
  sequences:
    "01":
      season_team: 11
    "05":
      season_roster: 22
```

Installed recipes:

| ID | Slots | Result |
| --- | --- | --- |
| `01_10` | Sport, League, Conference, Division, Year, Team | Team in that annual hierarchy |
| `01_11` | Sport, League, Year, Team | Team in that league/year |
| `01_12` | Sport, League, Year | Year, with resolved Sport/League |
| `01_13` | Sport, League, Team | Team using current league context |
| `05_22` | Sport, League, Team, Year, Player | Player on that team-season roster |

The last slot determines the returned entity. `01_12` does not imply Season: it returns Year. The adapter resolves parents in dependency order even when Year occurs after Team. Annual Team lookup uses the Campaign abbreviation/hierarchy, so `OAK` in 2019 can resolve the same franchise as `LV` in 2020. Player shorthand matches surname or `LAST_FIRST` within the requested roster; multiple matches fail.

This installed table is the authority for executable selections. Ascent's `10_01` (Person) and `10_02` (Office) are approved starting assignments, but their exact slot arrays and Ascent adapter are not installed. `ASC`, `SPD`, and `STC` are settled catalog tokens. Tokens, assignments, and recipe scopes remain editable before launch and publication of a usage guide while consumers can be kept synchronized; numeric allocation need not wait for exhaustive scope planning.

```ruby
registry = MICharismaSeeders::SequenceRegistry.read(sequence_path)
adapter = Seeds::EntitySequenceResolver.new
parser = MICharismaEntityParser.select_entity_sequence(
  "01_10", registry: registry, catalog: "ALA", adapter: adapter
)
parser.resolve("FTB-NFL-AFC-WEST-2019-OAK") # when that annual hierarchy is seeded

context = MICharismaSeeders::Context.new(registry: registry, catalog: "ALA", adapter: adapter)
context.sequence_is "01_11"
context.resolve("NYK", scope: {Sport: "SPORT-BKT", League: "BKT-LEAGUE-NBA", Year: "YEAR-2022"})
```

Ruby accepts strings, integer pairs, or staged choices:

```ruby
parser = MICharismaEntityParser.select_entity_sequence("05_22", registry: registry)
parser = MICharismaEntityParser.select_entity_sequence(5, 22, registry: registry)
parser = MICharismaEntityParser.select_entity_sequence(5, registry: registry)
parser = parser.select_entity_sequence(22)

context = MICharismaSeeders::Context.new(registry: registry)
context.sequence_is 5
context.sequence_is 22
context.sequence_is :athletes, :season_roster
```

The first single integer/name selects the family; later single choices select a member of that family. Use `sequence_family_is` on a Context or `select_entity_sequence_family` on a parser to switch families explicitly and clear the previous member. Parts are 0–99. A combined integer is rejected; bare `05_22` is octal 338. A Context belongs to one caller/file; blocks restore family and member. There is no global parser state. Incomplete choices cannot resolve codes.

YAML can set `entity_sequence: "05_22"` once at file/group/row scope. Existing exact references resolve directly. When a string reference is unresolved and its expected type is the selected sequence's final slot, the adapter applies that recipe. To select a different recipe for one reference, use:

```yaml
references:
  team:
    code: MIC-ALA-BKT-NBA-2022-NYK
    entity_sequence: "01_11"
```

YAML/JSON also accepts `entity_sequence: [5, 22]` or `[athletes, season_roster]`. A file can set `entity_sequence: 5` (or `athletes`) and select `22` (or `season_roster`) in its groups. A member must be selected before defining records. Siblings inherit the file's family independently. Named choices are resolved from the supplied registry; the reader produces the same normalized `05_22` metadata for all these forms.

Canonical definitions are independently issued references, not positional lookup strings. Whole scoped references such as `SPORT-BKT` remain atomic when filling omitted slots. A fully supplied positional construction supplies its own complete context.

## Running and replay

```sh
git submodule update --init --recursive
mise exec -- bundle exec rails db:migrate
mise exec -- bundle exec rails seeds:validate
mise exec -- bundle exec rails seeds:import
```

Use `SEED_LIBRARY_ROOT=/absolute/library` to select another bundle with `entity_sequences.yaml`. `seeds:validate` is read-only: it checks structure, model attribute/reference names, selected sequences, duplicate identities, and contradictory definitions. Reference existence, model constraints, and preserved database differences are checked during import. It is not a complete database dry run.

AthleteAce's CI test job checks out the pinned private submodules using repository secret `SEED_LIBRARY_READ_TOKEN`. Provision a GitHub credential with Contents read access to AthleteAce, athlete_ace_data, athlete_ace_ugc, and micharisma_seeders, then set that secret in AthleteAce. The workflow fails clearly if the secret is absent. No personal CLI credential is copied into CI. The shared repository tests itself on Ruby 3.1 and 4.0.

`seeds:import` creates missing records, adds compatible aliases, preserves existing values/links, and reports differences. Omitted rows never remove existing memberships. Conflicting aliases, incompatible types, invalid hierarchies, ambiguous lookups, or unresolved parents abort the transaction. File order need not follow parent order. Code bindings verify both numeric ID and preferred code; stale caches cannot attach to an unrelated row that reuses an ID. Missing rows and memberships are reconstructed on subsequent runs.

The approved next policy permits filling and refreshing selected attributes during replay while protecting other attributes. That configuration is not implemented in this pilot; do not add an unsupported `replay_policy` field to manifests or assume the last file wins. Attribute lists, source precedence, null handling, and stale-source behavior remain to be specified.

The pilot uses one transaction and reads the selected bundle into memory. Streaming/chunking and a persistent amendment/provenance ledger are future work for very large catalogs. When supplied, source metadata is committed with the manifests and included in conflict reports; citation URLs are optional.

The new tasks do not invoke the legacy `db:seed` scripts. For a clean rebuild, load the new schema and use `seeds:import`; mixing both libraries requires explicit reconciliation of legacy entities that lack codes. The importer only adopts uncoded rows through strong Year/Season/Campaign/Activation keys; it does not guess that matching player names or team abbreviations identify the same entity.

## Coverage and remaining launch work

The first sample supplies 89 definitions and 94 code bindings: four Sports, two Countries, five Leagues, ten Years, 41 Seasons, eight Teams, three Players, ten Campaigns, and six Activations. It covers the 2016–2025 starting-year window for NBA/NFL/NHL/EPL, plus a Championship season for Fulham. The three sampled transfers, Raiders relocation, and Fulham promotion test the contract. They are not complete rosters.

Next work is sourced complete annual team snapshots and roster unions for each league, reusable source generators, coverage/completeness checks, and seasonal filters in browsing/quizzes. Existing current-team player queries do not become historical roster queries automatically. The pilot reserves stadium/logo/division fields but does not fabricate their facts. Games played, statistics, within-season team history, public fan search, and Ascent's adapter remain outside this initial implementation.

For Ascent, the approved direction is one multi-party Candidacy per person/office/election, amended certifications on the same Election, and one Person identity scheme for candidates, voters, appointed officials, pundits, and foreign officials. Person usernames prefer Instagram handles, with generated names when absent; verification, encoding, and handle updates still need implementation. Ascent Clerk is approved for read access to private `micharisma_seeders`; access provisioning is not confirmed by this document. Jev remains in the fan-resolver plan, with integration still to be designed. See the decision record for the identity alternatives and unresolved topics to carry to Linear.

The NY/MA/CT/VA raw CSV captures should be converted into well-specified ASC `.yml` seeds, surfacing inconsistencies and judgment calls. Their existing location outside the repo is acceptable; universal capture preservation or copying into the repo is not required. This is later-today follow-up work, not implemented by the AthleteAce pilot. The decision record contains the ready-to-post Linear task and the unavailable Ascent connection status.

The first Ascent validation pilot is New York statewide contests plus multiple Assembly, state Senate, and U.S. House races, preferably competitive contests or races with multiple candidates. The exact selection and competitiveness metric remain preparation work.

Ascent name discrepancies should use a Spindrift-style disambiguation layer. Disagreement about an entire candidate defaults to inclusion of all potentially valid options, with uncertainty/source distinctions visible. These are future Ascent conversion/adapter policies, not changes to AthleteAce's current ambiguity checks.

The mirrored 2026 Ascent slate should deactivate withdrawn/removed candidacies by default while retaining history. Election experiments can choose other slates. Approved participation options are active, inactive, and off-ballot but approvable; the third must clearly show voters that the person is off the official ballot and supports administrative additions. Official ballot updates and experiment membership remain distinguishable. These options are future Ascent adapter/schema work, separate from AthleteAce's roster Activation model.

Validation covers the shared core and focused Rails model/import/profile tests, including replay after file renaming, changed numeric IDs, edited values, transfers, loans, and league changes. Tests use the local test database; development and deployed data are unchanged.

The initial pilot's complete local Rails suite passed: 346 examples, zero failures. The current importer/sequence suite passed 16 examples, including complete catalog wipe/rebuild and numeric, staged, and named YAML/JSON configuration. The shared core passed 28 tests / 146 assertions across Ruby 3.1 / JSON 2.6 and Ruby 4.0 / JSON 2.18 and 3.0. Rails' `zeitwerk:check` passed with the brand inflection. The pilot's Brakeman 8.0.6 check reported zero warnings. The read-only task validated 14 manifests / 89 definitions / 94 code bindings; actual CLI import created 89 records, and its second run created zero with zero conflicts. Remote AthleteAce CI still requires the private-submodule credential described above.
