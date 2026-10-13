# Round variety and pool limits

The chosen 10/20/30 length is a maximum. Normal rounds use each eligible subject
once, stopping when the scope runs out of players or teams. Setup shows the actual
question count and explains shorter rounds; replay retains the requested maximum.
Old saved rounds preserve their original questions and can still be resumed.

For explicit multi-team Team Match and Name Cipher selections, the sampler draws
one unique player from each represented team per pass, then shuffles question order.
It never repeats a player to equalize the team counts. If four teams have pools of
18, 2, 2 and 2 players, a ten-question round contains 4, 2, 2 and 2 respectively.
If two teams both have enough players, a ten-question round contains five each.

The setup's pool breakdown exposes recorded player counts, including selected teams
with zero eligible players. Counts describe the selected filters and season, not a
guarantee of complete rosters. Broader selections can provide more variety, but a
two-player sample will still offer the same two names across separate rounds until
the source data is expanded. No new roster facts are invented by the sampler.

## Local source expansion — October 13, 2026

The full captured NBA and NHL lists now supplement the original sample manifests
under `yaml/play_roster_expansion/` in the data repository. The standard `db:seed`
entry point reads these files. The local catalog has 1,766 players. The four-team
Knicks/Nets/Heat/Cavaliers pool has 71 names; Columbus has 27 unambiguous eligible
cipher names after seasonal multi-team exclusions. Counts are for this capture.

The data repository also contains pre-existing uncommitted seed work. Its broader
publication remains separate from the application sampler commit.
