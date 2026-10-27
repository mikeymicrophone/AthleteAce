# Import and refresh the 2026 seed library

Run these commands from the AthleteAce checkout with its pinned Ruby. The data repository remains mounted at `db/seeds/athlete_ace_data`.

## Import the captured catalog

```sh
mise exec -- bundle exec rails db:migrate
mise exec -- ruby db/seeds/athlete_ace_data/scripts/build_visual_assets.rb --download
mise exec -- bundle exec rails seeds:validate db:seed
mise exec -- bundle exec rails seeds:coverage seeds:assets:verify
```

The catalog contains current-season source listings for NBA, NFL, MLB, NHL, MLS, EPL, and Champions League, plus NBA regular-season and playoff participant unions for 2023/24, 2024/25, and 2025/26. See the [source boundaries](../db/seeds/athlete_ace_data/sources/coverage_2026/README.md) before interpreting a roster as an eligibility or current-team claim.

Champions League uses UEFA as its federation jurisdiction. Clubs retain their existing domestic identity, and a recorded competition Campaign makes their number history available to that competition's seasonal lookup.

`seeds:validate` must print positive record and file counts. `seeds:assets:verify` raises on missing, empty, resized, or changed files and also raises if no representations were imported. It prints the number of verified canonical files on success. Image and 3D files are local under the data repository's ignored `media/` directory. The download command creates them on another checkout.

The visual sample contains sourced logos and uniform photographs alongside explicitly illustrative SVG and GLB geometry. The meshes demonstrate representation storage and loading. They are not accurate garment reconstructions. The importer stores file references and checksums; it does not upload files or publish a media endpoint.

## Refresh public sources

```sh
mise exec -- bundle exec ruby db/seeds/athlete_ace_data/scripts/capture_2026.rb --refresh --as-of 2026-10-26
mise exec -- bundle exec ruby db/seeds/athlete_ace_data/scripts/build_2026.rb
mise exec -- bundle exec rails seeds:validate db:seed
```

The capture targets the named 2026 seasons. `--as-of` identifies the observation date, not a different target season. Use the actual observation date when making a new capture. `--leagues nba,nhl` limits a capture to selected datasets. Omit `--refresh` to reuse the ignored HTTP cache. The historical NBA datasets are named `nba_2023`, `nba_2024`, and `nba_2025` by starting year.

Review `sources/coverage_2026/report.json` and the manifest differences before importing a refresh. Player identity bindings record each provider player ID, catalog code, and reconciliation basis, including reused official NHL IDs. Unambiguous existing catalog names are reused during generation. Same-provider homonyms remain distinct, ambiguous matches fail, and the database importer does not match records by names. Soccer clubs shared by EPL and Champions League use ESPN's club ID, not their abbreviations.

Current roster captures seed a number assignment starting on the observation date, with an open end until explicitly superseded. This records current knowledge without asserting the number's actual introduction date. Historical participant lists and MLB full-season inventories do not manufacture number periods. A later capture with the same number reuses an existing period covering that observation date and reports differing source or date fields. It never rewrites the period. Before importing a changed number, close the old assignment explicitly. Number disagreements within a capture appear in the report and generate no assignment.

Ordinary seed replay preserves existing values and reports differences. Omitted memberships are not deletions. Rebuild or explicitly reconcile stale roster observations when exact replacement is needed.

## Apply NHL rescheduling

After recapturing the NHL feed, regenerating its manifest, and reviewing differences:

```sh
mise exec -- bundle exec rails seeds:refresh_nhl_schedule
```

This explicit task updates dates and scheduling details on the 1,344 existing 2026/27 NHL games. It requires the original home and away participants to agree, uses stable NHL game IDs, and leaves scores, lineups, and appearances alone. A rerun against the same capture prints `changed: 0`. Ordinary `db:seed` does not apply these updates automatically.

## Preview and verify local assets

```sh
mise exec -- ruby db/seeds/athlete_ace_data/scripts/preview_visual_assets.rb
python3 -m http.server 8127 --bind 127.0.0.1 --directory db/seeds/athlete_ace_data/media
```

Open [the local asset gallery](http://127.0.0.1:8127/). The gallery must report five rendered 3D files and show the downloaded images. Stop the server after reviewing it.

To check offline reproducibility, run each generator with `--check`. A differing or missing output raises an error and returns a nonzero exit status:

```sh
mise exec -- bundle exec ruby db/seeds/athlete_ace_data/scripts/build_2026.rb --check
mise exec -- ruby db/seeds/athlete_ace_data/scripts/build_visual_assets.rb --check
mise exec -- ruby db/seeds/athlete_ace_data/scripts/build_pseudo_games.rb --check
```

The simulated basketball library now stores persistent number assignments in `pseudo/hbl_numbers.yml`. Adjacent same-number periods merge across seasons. Its game roster entries and appearances no longer repeat those numbers.
