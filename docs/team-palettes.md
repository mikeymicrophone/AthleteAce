# Team palettes

`rails db:seed` runs `seeds:import`, then enriches existing coded teams with the primary and secondary colors recorded in `athlete_ace_data/sports`. This pass currently reads the NBA, NFL, and NHL team JSON catalogs. It does not create teams or match them by name or abbreviation alone; it resolves their league-qualified entity codes through the seed adapter. Retired catalog entries without a matching team are skipped.

Palette metadata follows the recorded JSON values on replay. Other team attributes retain the YAML importer's preservation policy. A custom `SEED_LIBRARY_ROOT` uses its own sibling `sports` directory, if present.

Teams save `text_color` as white or near-black, choosing whichever gives greater contrast against the primary color in linear sRGB. Changing the primary color recalculates the stored text color. Views use the saved value; incomplete or malformed palettes render the neutral fallback. Saved rounds snapshot all three colors so later team edits do not change an existing question.

Team colors appear on identity blocks and portraits. Answer buttons and correctness states retain the shared interface palette. Secondary colors appear as portrait bands and badge corners, with a theme-aware border on colored blocks.

The current catalog supplies palettes for 93 of 114 local teams: all NBA and NFL teams, and 31 NHL teams. The 20 EPL teams and Utah retain neutral blocks pending recorded palette data. Seasonal jersey numbers remain a separate follow-up.
