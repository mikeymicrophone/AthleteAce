# YAML seed library pilot

October 5, 2026. The shared reader/parser and AthleteAce database adapter are implemented on `codex/yaml-seasonal-seeding`. The data branch is `codex/yaml-seasonal-rosters`.

## Repositories and responsibilities

- [athlete_ace_data](https://github.com/mikeymicrophone/athlete_ace_data): committed catalog facts and sources, mounted at `db/seeds/athlete_ace_data`. The new `yaml/` library is independent of the existing JSON seed layout.
- [micharisma_seeders](https://github.com/mikeymicrophone/micharisma_seeders): private shared Ruby repository, mounted at `lib/micharisma_seeders`. It reads safe YAML/JSON, merges scopes, normalizes sequences, and parses constructions. It contains no Rails models or database writes. Ascent can reuse it with its own persistence adapter and catalog.
- AthleteAce: the model allowlist, relationship checks, code/alias registry, dependency resolution, and preservation policy in `Seeds::LibraryImporter` and `Seeds::EntitySequenceResolver`.

Filenames and directory names only select input files and identify errors. Renaming or moving a manifest has no effect on fetching. A file can contain several teams, seasons, leagues, or nested groups.

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

Definition codes and aliases are local, uppercase references. `MIC-ALA` is supplied once by the envelope. References may be qualified with `MIC-ALA-...`. Each coded model stores its preferred local `entity_code`; `EntityCode` enforces catalog-wide code uniqueness and binds aliases to that preferred identity. Codes remain bound when display facts change. Cross-catalog fetching needs a future catalog adapter; the pilot rejects foreign references.

## Optional lookup sequences

The standalone `yaml/entity_sequences.yaml` registry accepts the exact requested layout:

```yaml
01:
  10: [Sport, League, Conference, Division, Year, Team]
```

Quoted decimal keys are equally valid. Both normalize to `"01_10"`; normalized collisions fail. Sequences select slot order, not identity and not database IDs. Slots have variable widths, and underscores remain inside each supplied component.

Installed recipes:

| ID | Slots | Result |
| --- | --- | --- |
| `01_10` | Sport, League, Conference, Division, Year, Team | Team in that annual hierarchy |
| `01_11` | Sport, League, Year, Team | Team in that league/year |
| `01_12` | Sport, League, Year | Year, with resolved Sport/League |
| `01_13` | Sport, League, Team | Team using current league context |
| `05_22` | Sport, League, Team, Year, Player | Player on that team-season roster |

The last slot determines the returned entity. `01_12` does not imply Season: it returns Year. The adapter resolves parents in dependency order even when Year occurs after Team. Annual Team lookup uses the Campaign abbreviation/hierarchy, so `OAK` in 2019 can resolve the same franchise as `LV` in 2020. Player shorthand matches surname or `LAST_FIRST` within the requested roster; multiple matches fail.

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

Use strings in Ruby: bare `05_22` is an octal number. A Context belongs to one caller/file; a block restores prior selection. There is no global parser state.

YAML can set `entity_sequence: "05_22"` once at file/group/row scope. Existing exact references resolve directly. When a string reference is unresolved and its expected type is the selected sequence's final slot, the adapter applies that recipe. To select a different recipe for one reference, use:

```yaml
references:
  team:
    code: MIC-ALA-BKT-NBA-2022-NYK
    entity_sequence: "01_11"
```

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

The pilot uses one transaction and reads the selected bundle into memory. Streaming/chunking and a persistent amendment/provenance ledger are future work for very large catalogs. Source metadata is committed with the manifests and included in conflict reports.

The new tasks do not invoke the legacy `db:seed` scripts. For a clean rebuild, load the new schema and use `seeds:import`; mixing both libraries requires explicit reconciliation of legacy entities that lack codes. The importer only adopts uncoded rows through strong Year/Season/Campaign/Activation keys; it does not guess that matching player names or team abbreviations identify the same entity.

## Coverage and remaining launch work

The first sample supplies 89 definitions and 94 code bindings: four Sports, two Countries, five Leagues, ten Years, 41 Seasons, eight Teams, three Players, ten Campaigns, and six Activations. It covers the 2016–2025 starting-year window for NBA/NFL/NHL/EPL, plus a Championship season for Fulham. The three sampled transfers, Raiders relocation, and Fulham promotion test the contract. They are not complete rosters.

Next work is sourced complete annual team snapshots and roster unions for each league, reusable source generators, coverage/completeness checks, and seasonal filters in browsing/quizzes. Existing current-team player queries do not become historical roster queries automatically. The pilot reserves stadium/logo/division fields but does not fabricate their facts. Games played, statistics, within-season team history, public fan search, and Ascent's adapter remain outside this initial implementation.

Validation covers the shared core and focused Rails model/import/profile tests, including replay after file renaming, changed numeric IDs, edited values, transfers, loans, and league changes. Tests use the local test database; development and deployed data are unchanged.

The complete local Rails suite passed: 346 examples, zero failures. An additional complete catalog wipe/rebuild case passed in the 15-example importer/sequence suite. The shared core passed 20 tests / 89 assertions across Ruby 3.1 / JSON 2.6 and Ruby 4.0 / JSON 2.18 and 3.0. Brakeman 8.0.6 reported zero warnings. The read-only task validated 14 manifests / 89 definitions / 94 code bindings; actual CLI import created 89 records, and its second run created zero with zero conflicts. Remote AthleteAce CI still requires the private-submodule credential described above.
