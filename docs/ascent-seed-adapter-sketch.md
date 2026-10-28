# Ascent seed adapter sketch

October 5, 2026. A provisional starting point for iteration on real captures. The shared reader supports this envelope; the Ascent recipes, fields, and persistence adapter below are not installed. This sketch does not finalize the schema.

## Lookup recipes

Keep the approved `10_01` and `10_02` assignments. The additional numbers and all slot arrays below are proposals, editable before launch and publication of the usage guide.

```yaml
"10":
  "01": [Person]
  "02": [Country, State, Chamber, Office]
  "03": [Office, Election]
  "04": [Election, Candidacy]
terminology:
  families:
    politics: 10
  sequences:
    "10":
      person: 1
      office: 2
      election: 3
      candidacy: 4
```

| Selection | Construction | Resolution |
| --- | --- | --- |
| `10_01` | `PERSON_USERNAME` | Person by issued username, independent of roles or residence. |
| `10_02` | `USA-NY-ASSEMBLY-AD_125` | Office for that Assembly seat; `AD_125` is the Office slot's local seat label. |
| `10_03` | `2024_GENERAL`, with Office supplied in scope | Election for that Office and contest key. |
| `10_04` | `PERSON_USERNAME`, with Election supplied in scope | Resolve the Person, then their single Candidacy in that Election. |

Whole Office/Election references supplied through scope remain atomic. Canonical paths include type markers; they are distinct from positional constructions selected by a recipe. Explicit row references override inherited scope. Statewide and federal offices will reveal whether the Office recipe needs other shapes; no need to settle those before trying actual records.

## Small manifest shape

This reuses the historical Anna Kelles example to illustrate consolidation. New York's 2024 certification lists her for Assembly District 125 on Democratic and Working Families lines. [Official amended certification, page 127](https://elections.ny.gov/certification-november-5-2024-general-election).

`PERSON_USERNAME` is an unissued template variable, not Kelles's Instagram handle or a proposed username. Replace it consistently after identity verification. Names below are real; the example does not claim anything about the 2026 slate. Country, State, Chamber, and Year references require a separate foundation manifest. Proposed attribute names such as `username`, `seat_code`, `contest_key`, `certification_status`, `parties`, and `participation` are adapter design candidates.

```yaml
format: micharisma-seeds/v1
namespace: MIC
catalog: ASC
scope:
  country: COUNTRY-USA
  state: STATE-USA-NY
  chamber: CHAMBER-USA-NY-STATE_LEGISLATURE-ASSEMBLY
records:
  - type: Person
    code: PERSON-PERSON_USERNAME
    attributes:
      username: PERSON_USERNAME
      first_name: Anna
      last_name: Kelles
  - type: Office
    code: OFFICE-USA-NY-ASSEMBLY-AD_125
    attributes:
      seat_code: AD_125
  - type: Election
    code: ELECTION-USA-NY-ASSEMBLY-AD_125-2024_GENERAL
    attributes:
      contest_key: "2024_GENERAL"
      election_date: "2024-11-05"
      certification_status: certified
    references:
      office: OFFICE-USA-NY-ASSEMBLY-AD_125
      year: YEAR-2024
groups:
  - scope:
      election: ELECTION-USA-NY-ASSEMBLY-AD_125-2024_GENERAL
    records:
      - type: Candidacy
        code: CANDIDACY-USA-NY-ASSEMBLY-AD_125-2024_GENERAL-PERSON_USERNAME
        attributes:
          parties: [Democratic, Working Families]
          participation: active
        references:
          person: PERSON-PERSON_USERNAME
```

The `participation` value illustrates inclusion in a chosen simulation; it is not a claim of present-day official ballot status. Final participation field/enum names remain open. Party affiliations belong to the Candidacy, not the global Person. There is no coded BallotLine row. Citation URLs and timestamps are optional; neither is necessary to demonstrate this shape. Filenames have no identity role.

## Adapter behavior to try

Parse paths and query scoped model fields. Person resolution uses issued usernames and explicit disambiguation; a separate binding table is optional. Election resolution combines Office and contest key. Candidacy resolution combines Election and Person, with a database uniqueness constraint considered when implementing that relationship. Resolve dependencies independently of file order and reconstruct missing records after a rebuild.

On replay, fill or refresh attributes permitted by the chosen policy, retaining protected values and reporting unresolved conflicts. Certification changes update the same Election. Consolidate printed party lines before applying updates; a partial capture must not accidentally clear another party. Whole-candidate disagreements provisionally include all potentially valid options, with uncertainty visible. Only a declared complete superseding slate or a confirmed withdrawal drives the mirrored slate's deactivations. Preserve experiment membership independently. Timestamp storage and precedence remain experiments, not a last-write-wins assumption.

## Nuances the first real imports should expose

The local Ascent models/schema were inspected for this sketch:

- Person currently requires a unique email and has no username field. Public people without known emails need a deliberate schema adjustment; do not invent email addresses to satisfy validation.
- Office requires Position and a polymorphic jurisdiction; Chamber/GoverningBody are available. Map the actual district/jurisdiction representation and foundation records before importing. The proposed `seat_code` is not an existing column.
- Election requires Year, Office, date, lifecycle status, and boolean flags. Its current `status` means `upcoming`, `active`, `completed`, or `cancelled`; certification status is a separate concept. The proposed contest key/certification fields are absent, and this partial sample omits some required current fields.
- Candidacy currently has one `party_affiliation` string, requires an announcement date, and uses `announced`, `active`, `withdrawn`, or `disqualified` statuses. Multi-party storage, unknown announcement dates, and simulation participation need iteration. The three approved participation options should not silently replace official candidacy facts.
- Test a real fusion candidacy, a missing email/date, a name discrepancy, an amended list, and an off-ballot experiment. Follow with statewide, Assembly, Senate, and House examples. Let those cases determine party storage, contest-key precision, district editions, and update rules.

The shared registry/reader accepted all four proposed recipes and all four records; scope inheritance and the consolidated party array were checked. This does not establish that Ascent can persist the sample, and no Ascent import was run. See [the decision record](entity-code-decisions.md) for approved directions and [the implemented pilot](yaml-seed-library.md) for the shared contract.
