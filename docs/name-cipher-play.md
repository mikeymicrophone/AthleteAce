# Name Ciphers

Name Ciphers is a saved 10/20/30-question round under `/play/rounds/new?game_type=name_ciphers`.
Each question shows a scrambled player name and up to four original-name choices.
Two distinct names are required. Names with no rearrangeable letters are omitted,
and identical displayed names are deduplicated. Letter counts, spaces and punctuation
are retained; the scrambled letters are saved with the choices before play begins.

The mode shares Team Match's answer feedback, keyboard shortcuts, pause/resume,
summary, replay and per-round misses drill. Answers are scored against the saved
choices on the server. The standalone attempts endpoint does not accept cipher
attempts without a saved round.

Without scope filters, players can participate even without current-team links.
Team, league and location filters require current-team assignments unless a roster
season is chosen. Seasonal pools use the same recorded memberships and ambiguity
exclusions as Team Match. A single selected team is sufficient if it has two names;
historical players need not be active today. No broader pool silently replaces an
empty selection.

Accuracy, day streaks, game history and today's players include cipher attempts.
Team history uses the team saved with each puzzle, preserving historical attribution
after a transfer. Unassigned players contribute to overall history without a team.
The Play home names-known metric and cross-round misses list remain Team Match
measures, labeled as such. Cipher misses can be drilled from their round summary.

Multiple Choice, Phased Repetition and Image Recognition remain outside saved rounds.
