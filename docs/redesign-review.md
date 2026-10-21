# AthleteAce redesign review

First comparison: October 2, 2026. Discussion notes; no decisions have been approved through this review yet.

## Sources and current state

- [Claude Design: AthleteAce redesign](https://claude.ai/artifact/56obpGb9QbbbwxihZeeh5f), viewed in the signed-in Claude desktop app. Six pages, 39 artboards.
- [Linear: Redesign: Play, Feed, Moderate, Admin](https://linear.app/clank-j/project/redesign-play-feed-moderate-admin-de21d5b15b4d). All 44 project issues were read; all currently show Backlog.
- Six project issues are assigned to Mike. Four are explicit product decisions; two request further design work. All six currently have no comments.
- Linear descriptions contain implementation proposals and mock values. Their presence in an issue does not establish approval or implementation.
- The workspace already contains application and design changes. This review adds only this document.

## Design-to-issue map

| Design page | Artboards | Captured work |
| --- | ---: | --- |
| Shell | 2 | Role visibility, landing side, persistent side context, mobile navigation, account menu and theme (AA-177); contextual search (AA-178). |
| Play | 12 | Stats (AA-173), rounds (AA-174), following (AA-175), home (AA-181), scope picker (AA-179), game flow (AA-180), history (AA-182), quest progress (AA-183), player page (AA-184), rating slider (AA-186), anonymous preview (AA-194), unfinished Browse designs (AA-185). |
| Feed | 9 | Composer and model (AA-189), card tiers/reactions (AA-190), checkout and review state (AA-197), feed/filtering (AA-198), team wall (AA-199), leaderboard (AA-200), receipts (AA-204). Pricing and payment choices remain in AA-164 and AA-165. |
| Moderate | 7 | Approval states (AA-187), queue (AA-195), duplicate proposals/merges (AA-196), reports (AA-202), warnings/mutes (AA-188), decision log/escalations (AA-203). Policy remains in AA-166. |
| Admin | 6 | People/roles (AA-191), sports data editing (AA-192), seeds/backups (AA-193), revenue (AA-205), tiers/rules (AA-201), overview (AA-206), unfinished oversight/content catalog designs (AA-207). Data preservation remains in AA-167. |
| Components & tokens | 3 | Theme/type/color tokens (AA-168), icons (AA-169), shared components (AA-176), team colors/jersey data (AA-172). Identity and moderator foundations are AA-171 and AA-170. |

The existing project milestones propose: Foundations & shell → Play → Moderate → Feed & shout-outs → Admin. This order is recorded in Linear; it has not been reconfirmed in this discussion.

## Mike's six review issues

| Issue | Choices to work through |
| --- | --- |
| [AA-164: Shout-out pricing](https://linear.app/clank-j/issue/AA-164/decide-shout-out-pricing-the-dollar1-tier-loses-about-a-third-to-card) | Final tier prices/names; per-post payment, credits or bundles; pin duration; occupied pin slots; whether player pins appear on a team's feed. The $1/$5/$20 prices and fee calculations are mock assumptions, not verified provider pricing. |
| [AA-165: Payment setup](https://linear.app/clank-j/issue/AA-165/decide-the-payment-setup-for-shout-outs-provider-holds-receipts-terms) | Provider; hold/capture or charge/refund; unreviewed hold expiry; receipt formats; email or push notifications; payment terms and other launch requirements. Stripe is proposed, not chosen in the recorded issue. |
| [AA-166: Moderation rules](https://linear.app/clank-j/issue/AA-166/decide-moderation-rules-queue-order-self-review-review-target-refunds) | Queue priority; self-review; content types requiring approval; practical review target; refunds after hiding a live post; auto-hide; reject reasons; mute lengths; admin-only suspension; possible trusted contributors. |
| [AA-167: Edits and reseeding](https://linear.app/clank-j/issue/AA-167/decide-how-admin-edits-to-seeded-sports-data-survive-reseeding) | Record locks, field overrides, edits committed to seed JSON, or editing only unseeded fields; web versus rake operations; production backup storage; seed versioning and full reseed behavior. |
| [AA-185: Browse](https://linear.app/clank-j/issue/AA-185/restyle-the-browse-pages-with-the-new-components-not-mocked-yet) | Confirm which resources remain publicly browsable and which move to Admin. Browse landing/index screens still need designs. |
| [AA-207: Oversight and content catalog](https://linear.app/clank-j/issue/AA-207/moderation-oversight-and-content-catalog-needs-design) | Define and design the escalation/oversight screens and the content catalog. They appear in navigation but do not have their own artboards. |

## Findings to reconcile

1. **Moderation queue priority conflicts.** Shell desktop says paid shout-outs first; Moderate Queue says reports first, then paid shout-outs, then other content. AA-166 already captures this conflict.
2. **Released holds are sometimes called refunds.** Feed receipts and the decision log use refund wording for rejected posts despite describing a released authorization. The project and AA-204 already flag the distinction. No payment was captured in that modeled rejection flow.
3. **Hold expiry is populated in the current artboard.** Admin → Tiers & rules shows 72 hours. AA-165 says the mock leaves the hours blank. The artboard value is still a proposal to confirm.
4. **The $6 Spotlight price demonstrates an unsaved edit.** Tiers & rules shows $6, “was $5.00,” and “2 unsaved changes.” AA-164 correctly treats this as a UI state example.
5. **Offline syncing is an implied feature.** The light/dark component pages say answers are saved offline and sync later. AA-176 includes that message example; none of the 44 project issues specifically defines storage, replay, duplicate prevention or conflict behavior. Decide whether to implement offline play or change the example copy.
6. **Seed failure wording promises no changes.** Components and AA-193 say a failed seed changes nothing. Confirm how that guarantee will be achieved before shipping the wording.
7. **Profiles and other screens remain undesigned.** AA-171 explicitly notes that the Profile page is not mocked; AA-183 notes the quests index; AA-180 notes four other game variants lack individual mocks. These are additional gaps beyond AA-185 and AA-207.

## Decisions embedded in implementation issues

These should be discussed, even though they are not in the six assigned review issues.

- **Front door and anonymous access (AA-177, AA-194):** visitors land on Feed; signed-in fans land on Play; visitors get one anonymous question. Is that the desired introduction to AthleteAce?
- **Learning stats (AA-173):** “names known” requires a correct latest answer and at least two correct answers overall; streaks count days with one answered question; seven-day accuracy and unresolved misses use proposed definitions. Confirm what these measures should mean to a learner.
- **Spaced review (AA-173, AA-179):** “due for review” requires a per-person, per-player schedule. The scheduling rules are not defined by the visual example.
- **Round selection (AA-174, AA-175):** rounds have 10/20/30 names; Quick round blends follows, high Affinity and recent misses. The weighting and fallback behavior need definition.
- **Following versus Affinity (AA-175):** +5,000 is the proposed high-Affinity threshold. Confirm whether that rating should implicitly personalize Feed and Play, and how player follows affect team feeds.
- **Quest completion (AA-183):** decide whether partial achievement progress counts unique players, correct attempts, mastery, or another rule; the “7 of 10” visual does not define this.
- **Rating precision (AA-186):** proposed coarse/fine steps are 1,000/100 across −10,000 to +10,000. Confirm that these preserve the intended rating experience.
- **Leaderboard meaning (AA-200):** counts live shout-outs, uses Monday–Sunday weeks, and proposes counting only direct team shout-outs on the Teams board. Player-to-team aggregation and week timezone need a call.
- **Public identity (AA-171):** handles, display names, rename rules and the onboarding of existing aces need definition.
- **Moderated content scope (AA-187):** the issue mentions existing user-created highlights, but its proposed status fields list quests, achievements and spectrums. Confirm whether highlights also require review.

## Suggested discussion order

1. Shell: entry point, role visibility, shared page context, and public Browse boundary.
2. Play: the learning loop, round selection, stats, mastery and quest progress.
3. Feed: its purpose, following and leaderboard meaning, then pricing and payment choices.
4. Moderate: review workload and rules, reconciling queue order and payment outcomes.
5. Admin: seed edit preservation, operations, and the missing oversight/catalog designs.

First question to resolve: should signed-out visitors land on Feed, as the design proposes, or on Play with a free preview?

## Decisions made in this discussion

None recorded yet.
