# Play rounds and learning progress

All six games use saved rounds under `/play/rounds/new`. The selected 10, 20, or 30 questions are a maximum. Smaller pools produce shorter rounds without repeated subjects. Questions and answer choices are saved before play. Refresh, pause, resume, feedback, results, and per-round misses drills use those saved questions. Answers are scored on the server.

## Games and scope

- Team Match uses current team assignments or a selected roster season.
- Guess the Division uses current team classifications.
- Name Ciphers uses current players or a selected roster season.
- Multiple Choice asks about a player's current team, birth city, or birth country. Choose the topic and optional roster season in setup. Team answers use the selected season; birth facts remain biographical. Answer choices come from recorded facts within the selected player scope. At least two different answers are required.
- Image Recognition asks for the name in a recorded player photo. At least two photographed players with distinct displayed names are required. Choose a roster season when current-team assignments are absent. A failed photo disables answers and explains how to pause the round. The question does not show the player's name or initials before feedback.
- Phased Repetition uses due saved questions. It preserves each question's original game, choices, and historical context. Reviews can include team and player subjects. Explicit team filters use the team saved with the question, even after a player transfers.

Empty selections never expand to unrelated players. Multiple Choice and Image Recognition support current-team scope and recorded roster seasons. Image Recognition needs photo URLs in the catalog; the app does not generate or obtain photos at runtime. The catalog includes 17 verified official NBA headshot references from the captured Knicks roster. Standard seeding fills empty photo arrays for those coded players and preserves existing photos. These remote latest headshots can change; they are not historical jersey evidence.

## Player groups

Browse **Player groups** for curated player lists. Admins can create groups, edit their names and descriptions, and select members. Groups are shared public catalog records. Other accounts can browse and practice them but cannot edit membership. Seed imports can also populate groups and memberships using stable codes; see [the seed example](../db/seeds/athlete_ace_data/yaml/player_groups/knicks_names.yaml).

Choose **Player group** in round setup, then choose a game. Inactive members are included. Team, league, location, and roster-season filters further narrow the group; an empty group never expands to unrelated players. Name Ciphers and Image Recognition can use members without current teams. Multiple Choice can use their recorded birth facts. Team Match still requires a recorded team, and seasonal facts require an unambiguous recorded membership in the selected season. Guess the Division uses the current teams of group members. Group reviews include due player questions for members and team questions for their current teams. Normal rules for distinct answers, photos, and due dates still apply.

Saved rounds retain their questions and group label after membership changes or group deletion. Ordinary group replay starts a new round using current membership. Rounds started through an adopted quest achievement retain that achievement's saved member list on replay. A deleted group cannot start a new round.

Groups currently contain explicit player memberships. They do not evaluate database queries or infer membership from starter status, positions, or dates. The seeded Brunson/Hart example is a curated practice list, not a claim about starter status or a complete historical roster.

## Review timing

Each saved answer updates a `PracticeReview` for that account, original game, subject, and target. A miss returns in 10 minutes. Successive correct answers schedule review after 1, 3, 7, 14, and then 30 days. Another miss resets that sequence. Repeated submissions of the same question do not add attempts or change the schedule twice.

Only due questions with existing subjects and answer choices appear. A review round takes the oldest due question for each subject, up to the chosen round size. Other due facts about that subject remain available for later rounds. Older attempts created before this feature do not receive review dates retroactively; unresolved player misses remain available through the home-page drill.

**Quick round** prioritizes due reviews, then unresolved player misses, then teams with positive ratings on the approved Affinity spectrum. If preferred teams have no playable current questions, it uses the general pool and offers recorded seasonal data when available. Follows are not yet connected to this selection.

## Knowledge and history

Names known counts players with at least two correct answers across player games and a correct latest answer. A later miss removes a player from that count until another correct answer. Team-only questions affect accuracy and streaks, but not names known. Round summaries record players who became known on an answer in that round.

History and its game filter cover all six games. Team mix-ups combine wrong player-to-team answers from Team Match, Multiple Choice, and Phased Repetition. Player mix-ups combine wrong name answers from Name Ciphers, Image Recognition, and Phased Repetition. Each list combines both directions of a pair, shows up to five pairs ranked by count, and respects the selected game filter. Correct answers, skips, future attempts, other accounts, and pairs with deleted entities do not contribute. Counts are all-time totals, so correcting an answer does not erase an earlier mix-up.

Use **Drill** on a team pair for Team Match. Use **Drill names** on a player pair for Name Ciphers, then optionally choose another game. Player drills retain only the selected player IDs as you change modes, submit setup, and replay. Inactive and unassigned players are allowed where the mode has the necessary data. Setup lists the focused names; **Any players** removes that selection. Other filters narrow it. Missing/deleted IDs, duplicate IDs, and selections larger than 30 are rejected rather than replaced by unrelated players.

Team history uses saved team identities for the new modes. Legacy Team Match and division attempts retain their recorded target and subject attribution.

Set your time zone in **Edit profile**. Daily streaks, today's players, and history day boundaries use that setting. An unset preference uses the application time zone.

## Quest completion

Adopting a quest saves the recorded player roster for each supported achievement. Answer every player in that saved roster correctly at least once after adoption to complete the achievement. Repeated answers for one player do not advance roster coverage. A later wrong answer does not remove earned quest progress. Required achievements determine quest completion; optional achievements do not block it.

A player target requires that player. A player-group target snapshots every explicit member, including inactive players, without inferring a season. Team, division, conference, league, sport, city, and state targets use their recorded player scope, including inactive players. When current assignments are empty, the snapshot uses the first playable recorded season, checking up to ten recent seasons. Country and federation targets remain manual. Empty rosters do not complete automatically.

The required player IDs and saved practice filters stay fixed after adoption. An adopted group achievement's practice link uses its saved member IDs, even after an admin changes the group. The link is scoped to the signed-in account that adopted the quest. Catalog additions do not change an existing goal's denominator. The UI identifies this as recorded coverage because source lists can be partial. Completion does not certify knowledge of players missing from the catalog. Achievement progress shows completed dates and the next unfinished practice link.

Existing goals prepare missing roster snapshots on their next correct saved answer. Their roster snapshot therefore reflects that upgrade-time catalog, rather than their original adoption date. Existing answers are not replayed into the new per-achievement coverage.

## Anonymous preview and mail

Visitors can answer one Team Match question at `/play/preview`, linked from Feed and Play. The signed session holds the question and its first answer for 30 minutes. The preview does not create a round, attempt, streak, or quest progress. Sign in or create an account to continue saved play.

Production confirmation mail requires an actual SMTP provider and verified sender. Configure the variables in `config/production-mail.env.example` using the deployment's secret storage. `APP_HOST` controls HTTPS confirmation links; `MAIL_FROM` controls the sender. Setting `SMTP_ADDRESS` enables authenticated SMTP with STARTTLS on `SMTP_PORT`, default 587, and requires `SMTP_USERNAME` and `SMTP_PASSWORD`. Without those settings, the existing placeholder mail configuration remains. No production delivery is established by these code changes.

## Apply and verify

Apply the migrations before running this version:

```sh
mise exec -- ruby -S bundle exec rails db:migrate
```

A nonzero exit means the migration failed.

Build styles and run the Play acceptance checks:

```sh
mise exec -- ruby -S bundle exec rails tailwindcss:build
mise exec -- ruby -S bundle exec rspec spec/models/play_learning_spec.rb spec/requests/play_learning_spec.rb spec/system/play_learning_spec.rb spec/models/player_groups_spec.rb spec/requests/player_groups_spec.rb spec/system/player_groups_spec.rb spec/services/history_mixups_spec.rb spec/models/player_pair_practice_spec.rb spec/requests/history_mixups_spec.rb spec/system/history_mixups_spec.rb
```

A nonzero build exit means CSS generation failed. A nonzero RSpec exit, any failed example, or zero examples means acceptance failed. Browser checks require local PostgreSQL and Chrome.
