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

## Review timing

Each saved answer updates a `PracticeReview` for that account, original game, subject, and target. A miss returns in 10 minutes. Successive correct answers schedule review after 1, 3, 7, 14, and then 30 days. Another miss resets that sequence. Repeated submissions of the same question do not add attempts or change the schedule twice.

Only due questions with existing subjects and answer choices appear. A review round takes the oldest due question for each subject, up to the chosen round size. Other due facts about that subject remain available for later rounds. Older attempts created before this feature do not receive review dates retroactively; unresolved player misses remain available through the home-page drill.

**Quick round** prioritizes due reviews, then unresolved player misses, then teams with positive ratings on the approved Affinity spectrum. If preferred teams have no playable current questions, it uses the general pool and offers recorded seasonal data when available. Follows are not yet connected to this selection.

## Knowledge and history

Names known counts players with at least two correct answers across player games and a correct latest answer. A later miss removes a player from that count until another correct answer. Team-only questions affect accuracy and streaks, but not names known. Round summaries record players who became known on an answer in that round.

History and its game filter cover all six games. Team history uses saved team identities for the new modes. Legacy Team Match and division attempts retain their recorded target and subject attribution.

Set your time zone in **Edit profile**. Daily streaks, today's players, and history day boundaries use that setting. An unset preference uses the application time zone.

## Quest completion

Adopting a quest saves the recorded player roster for each supported achievement. Answer every player in that saved roster correctly at least once after adoption to complete the achievement. Repeated answers for one player do not advance roster coverage. A later wrong answer does not remove earned quest progress. Required achievements determine quest completion; optional achievements do not block it.

A player target requires that player. Team, division, conference, league, sport, city, and state targets use their recorded player scope, including inactive players. When current assignments are empty, the snapshot uses the first playable recorded season, checking up to ten recent seasons. Country and federation targets remain manual. Empty rosters do not complete automatically.

The roster and its practice scope stay fixed after adoption. Catalog additions do not change an existing goal's denominator. The UI identifies this as recorded coverage because source lists can be partial. Completion does not certify knowledge of players missing from the catalog. Achievement progress shows completed dates and the next unfinished practice link.

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
mise exec -- ruby -S bundle exec rspec spec/models/play_learning_spec.rb spec/requests/play_learning_spec.rb spec/system/play_learning_spec.rb
```

A nonzero build exit means CSS generation failed. A nonzero RSpec exit, any failed example, or zero examples means acceptance failed. Browser checks require local PostgreSQL and Chrome.
