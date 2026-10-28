# Seed schema publishing

October 12, 2026. YAML remains the preferred maintained seed format; JSON contributions use the same contract. Published JSON Schema provides editor assistance and PR structural validation. TOON remains outside the seed format; it may be evaluated separately for LLM prompt payloads.

The shared package has an optional Schematist build tool (`exe/export-seed-schemas`), with no new reader/parser runtime dependencies. It derives envelope fields from Reader declarations and exports self-contained Draft 2020-12 schemas for the shared manifest, sequence registry, and a supplied catalog field contract.

AthleteAce's `Seeds::CatalogContract` exports its live importer allowlist, permitted model columns/types/enums, and reference names. Run `RAILS_ENV=test bundle exec rails seeds:schema_contract`; `CHECK=1` detects drift without writing. Required relationships remain app validations because scopes can supply them. The generated contract represents the local app schema used for export; it is not proof of deployment or installation of pending model changes.

Schema artifacts, contribution instructions, editor associations, and the Python validator live in the data submodule. See [the publication instructions](../db/seeds/athlete_ace_data/schemas/README.md) and [contributor guide](../db/seeds/athlete_ace_data/CONTRIBUTING.md). Its PR workflow requires no private submodule credential, Rails, or database. It checks the maintained `yaml/` manifest tree (including `.json` files), not the separate legacy JSON layout or raw acquisition files.

The standalone check safely loads YAML/JSON, normalizes dates, rejects duplicate keys and unsafe constructs, and validates field shapes with the same published schema. The Ruby reader remains authoritative for normalization and scoped sequence interpretation; the app validates identities, relationships, conflicts, and replay behavior. Passing a schema is not a successful import.

Public schemas are generated artifacts. Regenerate the app contract and schemas together when fields change, review their diffs, and run the shared accepted/rejected fixtures plus contribution tests. The exporter supports `--check` to catch edited/stale output. Ascent can use the shared envelope without finalizing its still-provisional catalog adapter. No new protected-field, timestamp-precedence, or cross-app fetching policy is introduced here.
