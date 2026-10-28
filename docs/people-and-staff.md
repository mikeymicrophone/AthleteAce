# People, coaches, staff, and broadcasters

`Person` identifies someone across their athletic career, coaching work, organizational staff roles, and broadcasting appointments. Its optional `player` association links one athletic profile. A person can exist without a Player or an Ace account. Admin People continues to manage Ace accounts.

## Identity and athletic profiles

The migration creates one Person for each existing Player. New Players create their person identity in the same transaction. Player IDs, entity codes, names, ratings, positions, and game references retain their meanings. The Person name is an independent career display name. Editing an athletic profile does not overwrite it.

`people.player_id` has a unique index and a foreign key that sets the reference to null when a Player is deleted. The Person and its appointments survive. Recreating a coded Player reattaches the person by the original generated person code under a row lock. An occupied identity causes the Player creation to fail rather than reassign another athletic profile.

Generated person codes use `PERSON-` followed by the Player's entity code. Uncoded Players receive a UUID-based person code. A transfer or name change does not change that code. Names are display attributes, never merge keys. Rebuilding an uncoded profile cannot recover its previous identity automatically.

This first slice keeps the optional profile reference on Person. It avoids moving identity fields out of Player or changing existing athletic queries. Adding staff fields directly to Player would require every non-athlete to have an athletic profile.

## Appointments

`StaffTenure` records a person, an Organization, an optional Team, a role, a title, dates, an entity code, source metadata, and optional details. Its role is `coach`, `staff`, or `broadcaster`. The title preserves a specific job, such as Assistant coach, Performance director, or Color commentator.

The Organization is the employer or appointing organization. The Team is the appointment's explicit sporting context. A broadcaster can work for a media organization and cover a team without that media organization owning the team. A tenure without a Team is labeled Organization-wide and appears only on the organization and person pages.

Concurrent roles, same-day transitions, and return tenures are allowed. Each appointment has its own entity code. Different source records about the same appointment must reuse that code or declare aliases. A different code does not automatically merge appointments by name or dates.

`start_date` and `end_date` store text at the source's precision:

| Value | Meaning |
| --- | --- |
| `2025` | Only the year is known. |
| `2025-07` | The year and month are known. |
| `2025-07-07` | The calendar day is known. |
| null | The date is unknown. |

Validation rejects invalid dates and a start range entirely after the end range. An exact end day is inclusive. Partially known ranges may overlap. A missing end date means Unknown end. Only an affirmative `ongoing: true` displays Present, and an ongoing appointment cannot have an end date. This slice does not infer current membership or a season from incomplete dates.

Appointments sort by start-date text descending, with undated rows last and IDs as a stable secondary key. Public lists include historical appointments. Person, Organization, and Team deletion is restricted while appointments refer to them.

## Browsing

Organization pages list coaches, staff, and broadcasters. Team pages have a **Coaches, staff & broadcasters** tab that shows appointments with an explicit reference to that Team. Each row links its person, organization, optional team, and available source URL. Person pages link their athletic profile and list their appointments. Athletic profiles link back to career history.

These are public catalog views. There are no new public write endpoints or changes to account permissions. Staff records enter through the seed importer or existing trusted Rails maintenance access. A source records where an appointment claim came from, rather than proving employment, ownership, or consent.

## Seeds and rebuilds

The existing `micharisma-seeds/v1` importer accepts `Person` and `StaffTenure`. Person can reference a Player. StaffTenure can reference a person, organization, and team through record references or inherited scope. A staff appointment requires nonempty source metadata. Replays preserve differing values and report conflicts through the existing importer.

An explicit Person definition that references a Player adopts that Player's existing Person and registers the supplied code as an alias. It does not create another person. Existing aliases retain their canonical binding. Unique indexes reject duplicate person codes, duplicate athletic-profile links, and duplicate appointment codes, including concurrent writes.

The people and appointments are core catalog records in `UgcResetService`. A full catalog reset deletes them with the other core records. Portable Person and StaffTenure definitions are required to recreate sourced staff history after such a reset. UUID identities for uncoded Players are local identities, not portable cross-rebuild matches.

The sourced Steve Kerr example in `yaml/people/steve_kerr.yaml` links an athletic profile, a TNT broadcasting appointment, and a Warriors coaching appointment. Its [NBA Coaches Association biography](https://nbacoaches.com/steve-kerr/) supplies the facts. The broadcasting end date stays unknown because that source does not specify it.

Organization remains the common entity for sporting organizations and media organizations. No Business or brand model is added here. Typed ownership, investment, and promotion relationships remain separate future work, as do sourced practices, values, teachings, and team comparisons.
