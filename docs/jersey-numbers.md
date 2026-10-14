# Jersey-number history

A `JerseyNumberAssignment` belongs to a player and team, with a string number and optional inclusive start/end dates. A period can span several seasons. Missing bounds explicitly mean the assignment is open-ended in that direction. `0` and `00` remain distinct. The model and PostgreSQL exclusion constraint prevent overlapping periods for the same player/team, including duplicate or unbounded periods. Different players may use the same number; numbers are not globally unique.

To record a mid-season change, close the old assignment on its last day and create the new assignment beginning on the next day. Do both writes in a transaction. Assignments validate the player's sport against the team's sport. `source` and `details` preserve supporting evidence.

The YAML/JSON seed adapter accepts `JerseyNumberAssignment`, scoped by `player` and `team`, with a stable entity code. Replays follow the catalog's existing preservation/conflict policy. Close an existing open assignment explicitly before importing a replacement; the importer does not silently rewrite its dates.

```yaml
- type: JerseyNumberAssignment
  code: BKT-NBA-TEAM-EXAMPLE-PLAYER-EXAMPLE-NUMBER_00-2023
  attributes:
    number: "00"
    start_date: "2023-10-01"
    end_date: "2025-01-14"
    source:
      note: Replace this illustrative example with recorded evidence.
  references:
    player: BKT-NBA-PLAYER-EXAMPLE
    team: BKT-NBA-TEAM-EXAMPLE
```

`JerseyNumberLookup` resolves an assignment for an exact date. Existing roster/game observations can supply a number for their recorded day without being promoted to a permanent assignment. Current profiles use today's date and the current team.

Season-only Team Match questions use a number when an assignment covers the full known season (including playoffs when dated), or an unambiguous observation records it for that campaign. Dated observations show a recorded-on caption. Different numbers recorded in the same season cause the number to be withheld; an undated season label cannot establish which dated assignment applies. An explicitly unbounded assignment can also cover an undated season. A partial assignment without an observation is insufficient for a whole-season card.

Saved questions snapshot the resolved number and observation date. Later changes cannot rewrite a resumed round or misses drill. Portraits use a loaded photo, then a numbered jersey, then player initials when the number is unknown. No new tenure assignments are manufactured from the local catalog's isolated observations.

Uniform designs and their nicknames remain separate from number assignments; one uniform can eventually be reused across seasons and composed with the player's applicable number.
