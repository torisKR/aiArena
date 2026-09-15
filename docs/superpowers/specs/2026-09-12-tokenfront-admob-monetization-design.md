# Tokenfront Android AdMob Monetization Design

**Status:** Design-only proposal; no production code, credentials, or ad unit IDs are included.
**Version:** 1.0 — 2026-09-12
**Platform:** Android only

## Design intent

Ads should feel like optional support for the command network, never a toll booth
between the player and combat. The player must be able to start, play, lose,
win, hand off, and receive the guaranteed base War Token reward without an ad.
The only monetized advantage is time-to-cosmetic-unlock; combat strength,
faction selection, directives, story progression, and survivability are never
sold or accelerated by ads.

### Design pillars

1. **Combat is sacred.** No ad overlays, interstitials, banners, audio ducking,
   loading waits, or ad callbacks may interrupt active combat, movement, dash,
   handoff, spectating, or the landscape/orientation transition.
2. **Value before ask.** Show a rewarded offer only after a completed result has
   already credited the guaranteed base reward.
3. **Cosmetics only.** Rewarded WT can unlock/equip only the existing cosmetic
   catalog. No ad reward changes damage, speed, AI, directive outcomes, story
   unlocks, or matchmaking.
4. **Offline-first.** Ad failure, no inventory, consent denial, connectivity
   loss, lifecycle interruption, or SDK exception must resolve to a playable
   no-ad state.
5. **Quiet frequency.** A player can dismiss every ad offer and still receive
   the complete game loop.

## Existing safe surfaces and current contracts

| Surface / flow | Existing location | Ad decision |
|---|---|---|
| Command Deck / Lobby | `lib/ui/lobby_screen.dart` via `bannerVisible` and `_SponsorRail` | Optional anchored banner at the existing bottom sponsor rail. Never cover deploy, archive, locker, settings, or scroll content. |
| Operation Briefing | `lib/ui/operation_briefing_screen.dart` | No ad. This is a commitment/readability step immediately before combat. |
| Battle HUD | `lib/ui/battle_screen.dart` | No ad of any format. The current HUD owns joystick, dash, minimap, directive, handoff, and pause affordances. |
| Handoff / spectating | `lib/ui/battle_screen.dart` and game HUD | No ad. Handoff is a high-attention skill moment and must remain uninterrupted. |
| Result / Chronicle Debrief | `lib/ui/result_screen.dart` | Optional banner in existing result rail; one explicit rewarded `DOUBLE REWARD` offer after the base reward panel. |
| Result exit | `TokenfrontRoot._leaveResult` / `_continueFromResult` | Interstitial only at a settled exit boundary and only under the frequency policy below. Never show before the result is readable. Do not show while continuing into the next Chronicle briefing unless the player has explicitly chosen to leave the result flow and the screen is stable. |
| Signal Locker | `lib/ui/armory_sheet.dart` opened from lobby/result | No full-screen ad. A banner is not needed in the modal; do not obscure cosmetic cards or balances. |
| Signal Settings | `lib/ui/settings_sheet.dart` | No ad. Add the provider’s privacy-options entry only when the live consent SDK is actually connected. |
| Privacy policy sheet | `lib/ui/privacy_policy_sheet.dart` | No ad and no ad redirect. Policy remains user-initiated. |

The existing adapter already expresses the important boundary: banners are
limited to lobby/result, rewarded ads are result-only, and interstitials are
`resultClosed` only. The existing runtime already credits base rewards before
rendering the result and makes rewarded claims idempotent by `matchId`.

## Placement specification

### P-01: Lobby anchored banner

**Purpose:** Monetize idle menu time without competing with a decision.

- **Format:** AdMob anchored adaptive banner, Android only.
- **Mount:** Existing `_SponsorRail` location after the rules strip, below the
  primary command controls and inside the lobby scroll content.
- **Trigger:** Request after the lobby frame is stable and after consent allows
  ad requests. Preload may occur outside the visible surface, but must not delay
  lobby rendering.
- **Visibility:** Only while `screen == lobby`; remove immediately when briefing
  or battle begins. Never float above the game surface.
- **Copy/label:** Keep the existing accessibility concept, localized as
  `SPONSOR SIGNAL` / `Sponsor banner area`. The ad SDK must mark the unit as an
  ad using its required disclosure; do not disguise it as a game control.
- **Frequency:** One anchored banner session at a time. No reload loop more often
  than the SDK’s recommended refresh; do not manually refresh on every rebuild,
  mode toggle, or scroll.

### P-02: Result anchored banner

- **Format:** Same banner class as P-01.
- **Mount:** Existing `_ResultSponsorRail`, below result actions and outside the
  reward panel. It must never push the `DOUBLE REWARD` action off-screen without
  scroll access.
- **Trigger:** Request only after the result is visible and the result reward
  has been committed locally.
- **Frequency:** May reuse the already-loaded banner, but never create a second
  visible banner simultaneously with the lobby banner.
- **Chronicle exception:** If a debrief has a continue/retry action layer, the
  banner remains below the readable debrief and must not intercept the action
  layer.

### P-03: Result rewarded offer — existing `DOUBLE REWARD`

**Purpose:** Let an interested player accelerate cosmetic unlocks without
changing gameplay power.

- **Format:** Opt-in rewarded video.
- **Trigger:** The result is fully rendered, `baseReward` is already credited,
  the player has not claimed this `matchId`, consent/network gates pass, and
  the player taps the existing `double-reward-button`.
- **Reward:** Credit exactly `baseAmount` as the second half of the existing
  2× result reward. The displayed total becomes `+baseAmount * 2`.
- **Scope:** Applies to the base match reward only. Never doubles Chronicle
  directive bonuses, medal rewards, unlocks, story progression, or any combat
  stat.
- **Claim rule:** At most once per `matchId`; dismissal or failure gives zero
  bonus; the base reward remains untouched. Replays and already-claimed results
  show the existing claimed/disabled state.
- **Frequency hypothesis:** `[PLACEHOLDER]` cap of 3 earned rewarded ads per
  rolling 24 hours, plus the hard one-claim-per-match rule. The product owner
  should tune this against cosmetic unlock time and retention; never silently
  remove the per-match guarantee.
- **No cooldown copy:** Do not show a timer that implies the player is being
  punished. If the cap is reached, replace the action with a clear non-blocking
  message: `REWARD OFFER UNAVAILABLE // BASE REWARD SECURED`.

### P-04: Result-exit interstitial

**Purpose:** A low-frequency full-screen impression at a natural break.

- **Format:** Interstitial; never rewarded and never required.
- **Eligible boundary:** After the player taps a result exit action and the
  result has been readable. The game must be in result state, not battle,
  handoff, briefing, or an orientation transition.
- **Current policy baseline:** First eligible completed match is 2; then at most
  every 2 completed matches (`2, 4, 6...`) as expressed by
  `PolicyAdService(firstInterstitialMatch: 2)`.
- **Recommended player-friendly refinement:** Suppress the interstitial on
  Chronicle `CONTINUE` into the next briefing, after a rewarded ad was just
  watched, after a failed ad attempt, and when the player has not yet had 30
  seconds of settled result time. The exact suppression window is
  `[PLACEHOLDER]` and should be playtested.
- **Hard prohibitions:** Never show on match start, before a result, on rematch
  while the battle orientation is being acquired, during active combat, during
  player elimination spectating, or over a modal sheet.
- **Failure:** Skip silently and continue navigation. Do not retry synchronously
  or hold the player on a spinner.

## Exact UI state contract

### Banner states

1. **Not eligible:** No rail is rendered; no blank reserved ad block remains.
2. **Loading:** Render a compact labeled rail with `SPONSOR SIGNAL` and a
   non-animated/accessible `Loading sponsor signal` state only if the layout
   needs reserved height. Do not show an indefinite progress spinner.
3. **Available:** Render the SDK banner in the rail with safe-area padding and
   a minimum touch-safe separation from nearby buttons.
4. **No fill / offline / consent denied / failed:** Remove the rail or render the
   existing neutral sponsor placeholder; never show an error dialog and never
   block navigation.
5. **Returning from background:** Destroy or revalidate stale banner instances
   according to the SDK lifecycle contract; do not duplicate the banner.

### Rewarded states

1. **Offer:** `DOUBLE REWARD`; supporting text must say `Watch an optional ad to
   secure +{baseReward} extra War Tokens. Combat power is unchanged.`
2. **Loading/showing:** Disable the button, expose `REQUESTING AD…`, preserve
   scroll position, and prevent duplicate taps. The result remains in the
   navigation stack.
3. **Earned:** Button becomes `REWARD DOUBLED` and disabled. Show a live-region
   announcement such as `War Tokens secured: {credited}` and update the wallet
   balance.
4. **Dismissed before reward:** Re-enable the offer if the per-match/cap policy
   still permits it, or show `The optional reward was not claimed. Your base
   reward remains secured.`
5. **Offline:** `No connection. The match and base reward remain complete.`
6. **Consent off:** `Ad requests are off. Enable them in Settings; the base
   reward is safe.` The setting is opt-in and must not be toggled automatically.
7. **No inventory / load failure / show failure:** `No rewarded ad is available.
   The base reward remains credited.` Do not deduct WT or replay the match.
8. **Lifecycle interruption:** Treat as not earned unless the SDK has delivered
   the earned callback; return to the result screen without duplicating credit.

### Interstitial states

- **Before request:** No visible modal; navigation intent is retained.
- **Loading:** Do not show a blocking in-app loading screen. Continue with the
  requested result exit if no ready ad exists.
- **Shown:** AdMob owns the full-screen surface. On dismissal, complete the
  already-requested navigation exactly once.
- **Failed/offline/consent/frequency blocked:** Navigate immediately, with no
  toast, retry loop, or reward change.

## Economy and balance hypotheses

The current match reward is `40 + casualtyRelays * 8 + floor(playerKills / 5)`
and the existing catalog costs are 90, 110, 130, 140, and 160 WT. These are
design inputs, not new values. The rewarded ad adds one additional base reward,
so the maximum ad-assisted cosmetic income is bounded by the match cadence and
the proposed rolling cap.

| Variable | Current / proposed value | Tuning note |
|---|---:|---|
| Base match WT | Existing formula | Do not reduce for ad users. |
| Rewarded bonus | `+baseAmount` | Existing 2× contract; cosmetics only. |
| Rewarded claims | 1 per `matchId` | Required for idempotency. |
| Rewarded daily cap | `[PLACEHOLDER]` 3 / rolling 24h | Playtest against cosmetic unlock pacing; persist only if product accepts local-device clock limitations. |
| Interstitial cadence | Existing every 2 completed matches after first eligible match | Consider skipping Chronicle Continue and immediately-after-reward cases. |
| Banner refresh | SDK-controlled / one visible unit | No rebuild-triggered refresh. |

**Broken economy definitions:** ads may not be the only practical path to a
cosmetic; a player who never watches ads must still unlock cosmetics through
normal matches; a rewarded callback may never credit more than once; directive
bonuses may never be doubled; and no ad failure may reduce the guaranteed base
reward.

## Consent, privacy, and Android release implications

The current Android release is explicitly offline/NoOp: no ad SDK, no network
permission, no ad identifier, and no off-device collection. Adding AdMob changes
that release contract and requires a fresh source/dependency/manifest/AAB/network
audit before Play submission. The existing `adRequestsAllowed` toggle is an app
choice gate, not a substitute for Google’s consent requirements.

Implementation must use the current Google Mobile Ads consent flow appropriate to
the deployed SDK (including EEA/UK consent where applicable), request ads only
after the consent result permits it, and request non-personalized ads when
personalized consent is unavailable. Do not invent a live unit ID in source or
documentation; use Google test IDs in development and inject approved release
configuration outside this design document.

Required legal/release follow-up:

- Update the in-app English/Korean/Japanese/Chinese privacy copy and hosted
  policy to describe AdMob processing, device/ad identifiers as applicable,
  personalized/non-personalized ads, retention/controls, and the consent/privacy
  options path.
- Reconcile Google Play Data Safety and the “Contains ads” declaration against
  the exact signed AAB. The current “no data collected/shared” declaration is
  invalid for a live ad build until re-audited.
- Preserve the Android-only 13+ direction. Confirm target-age/Families handling
  with the publisher/legal owner; do not make an unsupported “child-directed”
  claim in code.
- Add a Settings entry that opens the provider privacy-options form only when
  `adInventoryAvailable` is true and the form is actually supported. It must be
  user-initiated, keyboard/screen-reader reachable, and never open an account or
  sensitive page automatically.
- Keep analytics independently consent-gated. AdMob integration must not turn
  on gameplay analytics or attach match IDs to ad requests.

## Accessibility and player control

- Every ad rail has a localized semantic label, identifies itself as sponsored,
  and is reachable in logical order after gameplay actions rather than before
  deploy/continue controls.
- Rewarded and interstitial lifecycle changes are announced once, not on every
  SDK callback. Focus returns to the triggering result action after dismissal or
  failure.
- Touch targets remain at least the app’s existing button minimum and do not
  overlap the result action layer, landscape controls, or safe-area insets.
- Reduced Motion disables decorative ad-entry animation; it cannot disable the
  required ad disclosure. Low-spec mode must not make the ad a gameplay overlay.
- If TalkBack is enabled, the player can reach `Not now`/close behavior in the
  SDK ad and return to the result; QA must confirm no focus trap.

## Offline and failure matrix

| Condition | Banner | Rewarded | Interstitial | Game/economy outcome |
|---|---|---|---|---|
| Offline | Hidden/placeholder | Disabled with offline copy | Skip | Match and base WT unchanged |
| Ad requests off | Hidden/placeholder | Disabled with consent copy | Skip | No gameplay impact |
| Consent unresolved | Hidden until resolved | Do not request | Skip | Continue normally |
| No fill | Hide rail | Show unavailable copy | Navigate | No reward loss |
| SDK load/show exception | Hide/skip | Failure copy | Navigate | No crash, no retry loop |
| App backgrounded | Revalidate/destroy stale view | Return to result unless earned callback arrived | Resume navigation safely | No duplicate credit/navigation |
| Double tap | N/A | One in-flight request | One exit request | Idempotent by match ID / navigation guard |

## Acceptance criteria

### Functional

- [ ] Android build renders banners only on Lobby and Result; no banner exists on
  Briefing, Battle, Handoff, Spectating, Locker, Settings, or Privacy sheets.
- [ ] No interstitial or rewarded ad can be requested or shown while battle,
  movement, dash, handoff, spectating, orientation lock, or result construction
  is active.
- [ ] A completed match always credits and displays the base WT before any ad
  request; ad failure/dismissal/offline/consent denial leaves it intact.
- [ ] A successful rewarded callback credits exactly one `baseAmount` bonus for
  one `matchId`; a second tap/re-entry/replay credits zero additional WT.
- [ ] Directive bonuses, medals, story progress, cosmetics themselves, and all
  combat values are unchanged by ads.
- [ ] Interstitial frequency is deterministic and at most every two completed
  matches, with all proposed Chronicle/reward suppression cases tested.
- [ ] Navigation completes once whether interstitial load/show succeeds, fails,
  or times out.

### Privacy/release

- [ ] Google test ads are used in debug/integration tests; no live IDs or secrets
  are committed.
- [ ] Consent is resolved before an ad request; denied/unresolved consent makes
  the adapter no-op or non-personalized according to the approved policy.
- [ ] Privacy options are available from Settings when required and are not
  opened automatically.
- [ ] Privacy policy, Play Data Safety, ads declaration, manifest permissions,
  dependency inventory, exact AAB hash, and observed network traffic are
  re-audited and consistent.

### Accessibility/QA

- [ ] TalkBack can identify, skip, activate, dismiss, and return from every ad
  state without a focus trap.
- [ ] Large text, narrow landscape, safe-area insets, reduced motion, and
  low-spec mode preserve gameplay controls and readable reward copy.
- [ ] Offline, airplane-mode, no-fill, consent-denied, SDK exception, app
  background, rotation/orientation, and duplicate-tap cases are covered.
- [ ] QA records screenshots/video proving no ad during active combat and a
  clean result-to-lobby/briefing transition at the configured cadence.
- [ ] Test evidence uses only Google test ads and explicitly labels production
  inventory as untested until the release candidate is audited.

## Changelog

- **1.0 — 2026-09-12:** Initial Android-only AdMob design based on the current
  lobby, briefing, battle, result, settings, privacy, ad-policy, and War Token
  contracts.
