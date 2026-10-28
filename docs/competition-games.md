# Competitions, games and titles

`Campaign` remains one Team in one league Season. A `Contest` represents a competition edition such as a league table, playoffs, or a standalone cup. Its `Contestant` rows identify the Campaigns entered in that competition. A cross-league cup leaves `season` unset and accepts Campaigns from different league Seasons. Its context can be a League, Conference, Division, Sport, Federation, or Organization.

`Game` represents an individual fixture. It is a Rails single-table-inheritance subclass of Contest, stored in `contests` with `type: Game` and `kind: game`. The migration converts existing game rows without changing their IDs, contestant IDs, entity codes, or appearance links. New imports can use `type: Game`; legacy definitions using `type: Contest` and `kind: game` still resolve to the same Game. The STI `type` attribute is protected from seed attributes. EntityCode's polymorphic record type stays `Contest` for both classes.

Public `/contests` lists competition editions and `/games` lists individual games. Existing `/contests/:id` links still resolve games. Competition detail shows the declared rounds, included games and awarded titles. Game detail shows its competition memberships and round information. These are read-only catalog pages; no manual format editor or scheduling UI is added.

## Flexible rules and game metadata

`Contest.format_rules` is a JSONB object. Unknown keys are retained without a universal sport-specific schema. When present, `rounds` is an ordered array of objects with unique `key` values. Keys use 1–80 lowercase ASCII letters, digits, underscores or hyphens, beginning with a letter or digit. Optional `name` is text of at most 200 Unicode code points. Optional `best_of` is a positive integer. The app does not interpret additional advancement, home advantage, seeding or tiebreaker settings yet.

For example, this format describes a competition with two named rounds:

```json
{
  "rounds": [
    {"key": "first_round", "name": "First round", "best_of": 3},
    {"key": "final", "name": "Cup final", "best_of": 1}
  ],
  "source_format_version": "2026"
}
```

`ContestGame` links a competition to a Game, uniquely per pair. Its JSONB `metadata` describes the game's role in that competition. A shared game can have different metadata in its league and cup memberships. Games and appearances are stored once. The membership metadata has a GIN index for containment queries.

```json
{"round": "first_round", "series": "eastern-1", "game_number": 2}
```

Recognized metadata fields have modest validation. `round` uses the same key syntax as format rounds and must match a declared round when the competition supplies a round list. `game_number` and `leg` are positive integers. `group` and `series` are strings of at most 100 code points. Unknown keys remain unrestricted. Empty format and metadata objects are valid; unknown facts can be omitted. JSON null, scalar values and arrays are rejected as the top-level object.

Round definitions used by stored game memberships cannot be removed. Other format fields can be corrected through normal model writes. This is not a versioned rules engine or an automatic bracket generator. Operators should retain the source and edition-specific rules when making corrections. Cross-record consistency checks run through Rails validation; bulk SQL writes bypass those application checks.

## Entries and awards

A game can be linked before its participants are known. Every known participating Campaign must already be entered in each linked competition. Adding or changing a game's contestants checks existing memberships too. An entry used by a competition's games cannot be reassigned or removed independently. A Contest with a Season requires entries from that Season; cross-league competitions and games leave it unset.

`TitleAward` identifies a named title, its deciding Contest, and its winning Contestant. `key` is stable within that competition, uses the same lowercase ASCII key syntax as rounds, and has an 80-character maximum. `name` has a 200-code-point maximum. The winning entry determines the team and Campaign. Optional `awarded_on`, source and details retain supporting facts. A composite PostgreSQL foreign key ensures the winner belongs to the awarding competition. One winner is supported per title key per competition; shared titles need distinct explicit awards or a future model extension.

The MLS table and playoffs can therefore award the Supporters' Shield and MLS Cup independently. A standing, qualification or advancement does not automatically create a title. Existing `Season.champion`, `Season.championship_contest` and `Contest.champion` fields remain available for old data; the migration does not infer awards from them. Deleting a competition removes its memberships, entries and awards while preserving shared games.

## Automated imports

The seed adapter and published schemas accept `Game`, `ContestGame`, `TitleAward` and Federation definitions. Existing Contest, Contestant and Appearance definitions remain supported. New records use semantic reference codes, never database IDs. Federation and Organization contexts allow cup editions to sit outside a single participating league. The new records participate in core catalog resets.

Import the competition and its entries, the game and its participants, then memberships and awards. Definitions can reference later records and the importer resolves missing dependencies in subsequent passes. Replay uses the existing preserve-and-report-conflicts policy. Memberships adopt an existing competition/game pair; awards adopt an existing competition/title-key pair. Changing a source definition does not silently overwrite existing rules or results. A failed import rolls back its library transaction.

This build does not import full fixture lists, derive the current team of a player, calculate series winners, generate brackets, or ingest player appearances. Existing appearances remain functional and linked to their original games. Player-by-game participation and its source/seed policy are the next step.

## Verification boundaries

Automated checks cover flexible and malformed JSON, unique round keys, positive numeric settings, cross-league entries, shared-game metadata, protected round references and entries, distinct title awards, foreign-key winner integrity, legacy game identities, semantic-code imports and replay, and public mobile navigation. Remaining sports policies are explicit metadata, not silently inferred facts.
