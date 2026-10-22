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

## Group learning progress

Play home shows up to three groups from your most recently updated group rounds, with one card per group. Deleted groups and rounds dated in the future do not contribute to this selection. Another account's rounds cannot place a group on your home page. **All groups** opens the paginated group browser, which shows personal progress for every group on the page. Before you have any group rounds, the home panel links to group discovery.

Each signed-in card shows current membership, lifetime coverage, and latest-answer misses. **Practice remaining** and **Practice misses** use the same personalized filters as the group detail page. Fully covered groups retain **Practice group**; empty groups show no practice actions. Visitors can browse group names without seeing another account's progress. The same player can contribute to coverage in several groups; you do not have to relearn a shared member in each group. Quest completion still uses its own adopted roster and post-adoption answers.

Signed-in group pages show how many current members you have answered correctly at least once across player games. This is lifetime coverage, including answers before the group existed. Later wrong answers do not remove that coverage. Your names-known count still requires two correct answers and a correct latest answer. Per-member labels distinguish **Not practiced**, **Answered correctly**, **Known**, and **Needs practice**. Needs practice means the latest player answer was wrong or skipped. Team-only questions do not establish player coverage. Visitors cannot see another account's progress.

**Practice remaining** selects members with no correct player answer. **Practice misses** selects members whose latest player answer was wrong or skipped. In setup, **Members to practice** switches between these filters and **All members**. Personalized filters require sign-in and a group. They select practice questions without changing the group's explicit membership. Group, team, season, and explicit-player filters still intersect.

For Name Ciphers, Image Recognition, and Multiple Choice, other eligible members in the selected scope can supply answer choices without becoming questions. One remaining member can therefore produce a one-question round when the full scope supplies at least two distinct valid answers. Existing name, photo, and fact requirements still apply; the app does not add outside players to fill choices. Team Match and division choices retain their existing league/team rules. Due reviews retain their saved choices and normal schedule.

An adopted quest's remaining filter uses its saved roster and answers credited since adoption, rather than lifetime coverage. Its practice link retains the owned achievement reference through setup and mode changes. Saved rounds keep their questions after progress changes. Replay recomputes a new round's eligibility, so finishing every remaining member can leave replay with no questions. Choose **All members** to keep practicing. Group-page totals always describe current membership; quest totals continue to use the adopted roster.

## Round summaries and continuing practice

Completed group rounds show **Current group progress** with lifetime coverage for the current members. **Practice remaining** opens the members without a correct answer; fully covered groups offer **Practice group**. These totals can change after a round ends. The saved score and question results remain unchanged.

Rounds started through an adopted group achievement show that achievement's current post-adoption coverage instead. **Continue achievement** opens the remaining saved members in Name Ciphers. When the achievement is complete, **Next achievement** opens the next unfinished playable requirement. Group requirements retain their adopted roster and remaining filter; other target types keep their usual practice scope. A completed quest offers **Explore quests**. If the next requirement has no available target, the summary links to the quest instead.

Quest progress appears only for the account that owns the adopted goal, while its quest, achievement, and requirement remain approved. If that progress is unavailable, an existing group can still show ordinary lifetime coverage. After a group is deleted, saved results remain readable and **Play again** is omitted because the group cannot start a new round.

## Review timing

Each saved answer updates a `PracticeReview` for that account, original game, subject, and target. A miss returns in 10 minutes. Successive correct answers schedule review after 1, 3, 7, 14, and then 30 days. Another miss resets that sequence. Repeated submissions of the same question do not add attempts or change the schedule twice.

Only due questions with existing subjects and answer choices appear. A review round takes the oldest due question for each subject, up to the chosen round size. Other due facts about that subject remain available for later rounds. Older attempts created before this feature do not receive review dates retroactively; unresolved player misses remain available through the home-page drill.

**Quick round** prioritizes due reviews, then unresolved player misses, then followed players, followed teams and teams rated at least +5,000 on the approved Affinity spectrum. It tries recorded seasonal data for the preferred teams when current-team questions are unavailable, then falls back to the general pool.

For followed players, Quick round considers your 30 most recent player follows, including inactive players. It starts Team Match with playable current-team questions, or tries a recorded season if current-team data is absent. If neither works, it offers Name Ciphers when at least two distinct followed names can form puzzles. It never fills a followed-player round with unrelated subjects. When no followed-player round is playable, it moves on to preferred teams and then the general pool.

A Quick round uses up to 30 preferred teams, with recent team follows before Affinity ratings.

## Following teams and players

Use **Follow** on a team or player page while signed in. The button becomes **Following** and updates in place; selecting it again unfollows. Guests see **Sign in to follow**. Your profile has a paginated **Following** list for your account. Each team or player can be followed once, and deleting that entity removes its follows.

Followed players and teams help choose Quick rounds after due reviews and unresolved misses. Existing saved rounds retain their selected players and questions when your follows change; replay uses their recorded scope. Following and Affinity ratings are separate preferences, so unfollowing a team does not remove its high Affinity rating.

Feed's **My teams** view lists followed teams and teams with active ratings of at least +5,000 on the approved Affinity spectrum. A team that qualifies through both appears once with both labels. Player follows do not add their current team. Choose **Sport** and **League**, then select **Search posts** to narrow the list and stream. Pagination retains the selected view, search and filters in the URL. **Clear filters** removes sport and league while keeping My teams and the search query. Guests receive a sign-in prompt, and empty preferences never expand to unrelated teams. The view also shows approved shout-outs for qualifying teams, plus your own funded posts in review. Shout-outs use bid-weighted order and separate pagination from the team list. See [shout-out payments](shout-out-payments.md) for bidding, review, and refund behavior.

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
mise exec -- ruby -S bundle exec rspec spec/models/play_learning_spec.rb spec/requests/play_learning_spec.rb spec/system/play_learning_spec.rb spec/models/player_groups_spec.rb spec/requests/player_groups_spec.rb spec/system/player_groups_spec.rb spec/services/history_mixups_spec.rb spec/models/player_pair_practice_spec.rb spec/requests/history_mixups_spec.rb spec/system/history_mixups_spec.rb spec/models/group_learning_spec.rb spec/requests/group_learning_spec.rb spec/system/group_learning_spec.rb spec/services/group_practice_overview_spec.rb spec/requests/group_overviews_spec.rb spec/system/group_overviews_spec.rb spec/requests/round_learning_summary_spec.rb spec/system/round_learning_summary_spec.rb spec/requests/follows_spec.rb spec/requests/quick_round_preferences_spec.rb spec/system/follows_spec.rb spec/requests/quick_round_players_spec.rb spec/system/quick_round_players_spec.rb spec/requests/feed_preferences_spec.rb spec/system/feed_preferences_spec.rb
```

A nonzero build exit means CSS generation failed. A nonzero RSpec exit, any failed example, or zero examples means acceptance failed. Browser checks require local PostgreSQL and Chrome.
