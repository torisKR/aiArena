# Tokenfront Echo Cycle — post-ending progression

**Status:** Implementation contract  
**Date:** 2026-09-18  
**Product:** Tokenfront: Orbital Signal War  
**Surface:** campaign progression after an ending is chosen (`StoryProgress`, `CampaignController`, lobby deploy enablement). Recovery combat and HUD rails are unchanged.  
**Owner of this file:** design. A separate engineering worker implements it. Do not treat this document as Dart.

---

## 1. Decision

**Primary direction: (A) Echo Cycle — New Game+ over the existing five operations.**

After the player chooses `EndingChoice.claimRelay` or `EndingChoice.openRelay`, Chronicle stays playable. The five scripted operations (`wake` → `echo` → `split` → `crown` → `lastInstruction`) run again as **echo cycles**. The canonical campaign record is never wiped by this loop. Difficulty escalates only by shortening the recovery clock and offsetting the catalog seed. Occupancy feel stays the playtested 8 s / 5 s / radius 64 / 100 units.

**(B) and (C) lose.** See §3. This is not a hybrid of those systems. Two small residues ride on (A) and are not a second loop:

1. `bestClearSeconds` — one `Map<StoryOperationId, double>` so the Archive can show a personal best. Not a grade matrix.
2. Two cost-0 cosmetics granted on first echo-cycle clear and on dual-ending completion. Existing `CosmeticCatalog` + `WarTokenWallet.unlock` path. Not a mastery layer.

Those residues exist so the locker and the Archive still change after War Token income is bounded. They do not add screens, verbs, or authored operations.

---

## 2. One-screen loop (what the player sees)

Cycle 1 is today's Chronicle: five recoveries, then the two ending buttons. That does not change.

After either ending is chosen:

```text
COMMAND DECK                          ECHO 2
locked core (same faction)
OP-01 // WAKE                         [canonical ending chip]

The Last Relay still calls.
Residual nodes 1 / 2 / 3 must be recovered.

[ ARCHIVE ]                           sticky bar unchanged
                                      [ Recover the echo ]   ← chronicle-deploy ENABLED
```

1. Player sees the Command Deck, not `CHRONICLE UNAVAILABLE`.
2. Player taps the existing sticky `chronicle-deploy` button (same key, same bar, new label).
3. One recovery match runs (destination 1/2/3, 8 s occupancy, cycle-scaled clock).
4. Result: continue to the next of the five operations, or retry. Action row layout unchanged.
5. After echo OP-05: result may offer a **residual ending choice** (same two buttons, does not overwrite the canonical ending). Continue returns to the Command Deck with `ECHO 3` queued at OP-01.
6. Tomorrow they tap the same deploy button because there is always a current echo operation, the clock is meaner than yesterday's cycle, the other ending is still unrecorded (until they pick it), and the Archive best-time can still fall.

Target session: **one operation ≈ 2 minutes** (≤ 90 s battle + result). A full echo cycle of five operations is an optional ~10–12 minute sitting. That is a mobile session, not a 15-minute Skirmish.

---

## 3. Why the other directions lose

### (B) Endless / escalating operations after OP-05 — rejected

The campaign spine is five fragments of one instruction. Procedural OP-06+ has no transmission, no catalog seed, and no `StoryOperationId`. Recovery already has only three nodes and one verb; an infinite directive-target curve either becomes unfair or becomes Skirmish wearing a Chronicle label. Skirmish already is the detached endless mode. A solo developer cannot author a live-service treadmill, and this contract forbids one.

### (C) Mastery layer over the existing five — rejected as primary

Archive replay already exists (`onReplay`, `retryDirective`). In recovery, the win condition **is** all three nodes, and `alliesLost` **is** a fail, so “no-loss” and “all-three-nodes” grades are tautological. A completion matrix does not re-enable `chronicle-deploy`: `StoryProgress.currentOperation` still returns `null` once five operations are concluded, and the lobby still disables the button. Mastery is a spreadsheet, not a tomorrow tap. Time-to-recover is kept only as `bestClearSeconds` under (A).

---

## 4. Product calls (do not re-ask)

| Call | Decision |
|---|---|
| Force the opposite ending on cycle 2? | **No.** Canonical `ending` is never mutated except by explicit `restart()`. Cycle 2 offers the same two buttons as a residual choice into `echoEnding`. Same choice is allowed. Skipping is allowed; deploy stays enabled. |
| Change campaign core for echo? | **No.** `campaignFaction` stays locked. Changing core remains `RESTART CHRONICLE` (full wipe of story progress, not of wallet/ledger). |
| Does doctrine change combat? | **No.** `SignalDoctrine` stays descriptive. Escalation is cycle clock + seed only. |
| Does echo repay directive WT? | **No.** `ProfileRewardLedger` remains lifetime. |
| Schema version bump? | **No.** `_TokenfrontLocalState._version` stays **3**. New keys are optional inside `story`. |

---

## 5. Data model delta

All names below are the names to implement. Do not invent parallel types.

### 5.1 `StoryProgress` — new fields

Add to the constructor, `copyWith` (using the existing `_unset` sentinel), `==`, `hashCode`, `toJson`, and `fromJson`.

| Field | Type | Default | JSON key | Notes |
|---|---|---|---|---|
| `echoCycle` | `int` | `1` | `echoCycle` | 1-based. Cycle 1 is the scripted campaign. Minimum 1. |
| `echoConcludedOperations` | `Set<StoryOperationId>` | `{}` | `echoConcludedOperations` | Ordered with existing `_orderedStoryIds`. Operations recovered **this echo cycle**. |
| `echoSignalRoutes` | `Map<StoryOperationId, RelayRoute>` | `{}` | `echoSignalRoutes` | Ordered with existing `_orderedSignalRoutes`. Keys ⊆ `echoConcludedOperations`. |
| `echoEnding` | `EndingChoice?` | `null` | `echoEnding` | Residual choice. Never overwrites `ending`. |
| `bestClearSeconds` | `Map<StoryOperationId, double>` | `{}` | `bestClearSeconds` | Lowest successful recovery elapsed per operation. Values finite and `> 0`. |

Existing fields **do not change meaning**:

- `campaignFaction`, `concludedOperations`, `medals`, `recoveredTransmissions`, `ending`, `signalRoutes` remain the canonical first-run record.
- `medals` may still gain a missed cycle-1 medal from echo play or Archive replay (today's replay rule).
- `ProfileRewardLedger` is unchanged.

### 5.2 `fromJson` — old saves

A save written by today's build has no echo keys. Decode must succeed.

```text
echoCycle:
  if json['echoCycle'] is int >= 1 → use it
  else if missing:
    ending == null ? 1 : 2
  else → FormatException → existing StoryProgress.fromJson failure

echoConcludedOperations: missing → []
echoSignalRoutes: missing → {}
echoEnding: missing or null → null; present string → _decodeEndingChoice
bestClearSeconds: missing → {}
  present map: keys via _decodeStoryOperationId;
  values must be num, finite, > 0; ignore non-positive / non-num entries
```

Coerce: if `ending != null` and decoded `echoCycle < 2`, set `echoCycle = 2`. This is how a completed today's save becomes immediately playable.

Do **not** bump `_TokenfrontLocalState._version`. `story` already round-trips through `StoryProgress.fromJson` / `toJson`. Extra keys are ignored by the current decoder; missing keys default as above.

`toJson` **always writes** the five new keys so a post-ship save is explicit.

### 5.3 `isSemanticallyValid` — additional clauses

Keep every existing clause. Then also require:

1. `echoCycle >= 1`.
2. `_isPrefix(echoConcludedOperations)` is true.
3. `echoSignalRoutes.keys.every(echoConcludedOperations.contains)`.
4. If `ending == null`: `echoCycle == 1` AND `echoConcludedOperations.isEmpty` AND `echoSignalRoutes.isEmpty` AND `echoEnding == null`.
5. If `ending != null`: `echoCycle >= 2` AND `campaignFaction != null` AND `concludedOperations` contains every `StoryOperationId` (existing ending clause already requires this).
6. If `echoEnding != null`: `ending != null`.
7. `bestClearSeconds` keys are `StoryOperationId` values; every value is finite and `> 0`.

Existing medal / transmission / route / prefix rules on the canonical fields stay exactly as they are. Echo fields never need to equal `recoveredTransmissions`.

### 5.4 `currentOperation` — this is the lobby-enable fix

Replace the getter with:

```dart
StoryOperationId? get currentOperation {
  if (ending == null) {
    for (final operation in StoryOperationId.values) {
      if (!concludedOperations.contains(operation)) return operation;
    }
    return null; // OP-05 done, ending not chosen: keep today's ending panel
  }
  for (final operation in StoryOperationId.values) {
    if (!echoConcludedOperations.contains(operation)) return operation;
  }
  return StoryOperationId.wake; // echo cycle complete: queue next cycle at OP-01
}
```

Invariants:

- After canonical OP-05, before ending: `currentOperation == null` (unchanged). Lobby shows `_EndingChoicePanel`, hides deploy. Correct.
- After `chooseEnding`: `currentOperation == StoryOperationId.wake`. Lobby deploy **enabled**.
- After echo OP-05 recovered: `echoConcludedOperations` contains all five, `currentOperation == wake`, deploy **enabled**.
- `currentOperation` is **never** null when `ending != null`.

Add:

```dart
int get displayCycle {
  if (ending == null) return 1;
  if (echoConcludedOperations.length == StoryOperationId.values.length) {
    return echoCycle + 1;
  }
  return echoCycle;
}

bool get echoActive => ending != null;
```

`displayCycle` is what the lobby chip and recovery rules use. After echo OP-05, the player is looking at the **next** cycle.

### 5.5 `BattleReport` — one optional field

```dart
final double? recoveryElapsedSeconds; // default null
```

Set only when `recoveryOutcome == RecoveryOutcome.recovered`. Legacy reports leave it null; `bestClearSeconds` is not updated. Include it in `==` / `hashCode`.

### 5.6 `RecoveryRules` — new class in `lib/game/recovery.dart`

```dart
final class RecoveryRules {
  const RecoveryRules({
    required this.requiredSeconds,
    required this.midwaySeconds,
    required this.matchLimitSeconds,
    required this.radius,
    required this.unitsPerFaction,
  });

  static const cycle1 = RecoveryRules(
    requiredSeconds: 8.0,
    midwaySeconds: 5.0,
    matchLimitSeconds: 90,
    radius: 64.0,
    unitsPerFaction: 100,
  );

  static RecoveryRules forCycle(int cycle) { /* §6 */ }

  BattleConfig get battleConfig; // world 1200×800, units + matchLimit from this
}
```

`RecoveryState.config` **remains** the cycle-1 `BattleConfig` (`unitsPerFaction: 100`, `worldWidth: 1200`, `worldHeight: 800`, `matchLimitSeconds: 90`). Add `RecoveryState.configForCycle(int cycle) => RecoveryRules.forCycle(cycle).battleConfig`. Cycle 1 must be `==` to `RecoveryState.config`.

`RecoveryState.requiredSeconds`, `midwaySeconds`, `radius` stay **static const** at 8.0 / 5.0 / 64.0. They do **not** become per-cycle. HUD `/8` labels stay `/8`.

### 5.7 `CampaignController` behavior

#### `conclude`

Keep the recovery-fail early return (non-`recovered` does not move any pointer). Keep Archive replay (`replay: true`) on canonical `concludedOperations` exactly as today, plus `bestClearSeconds` min-update when `recoveryElapsedSeconds` is non-null.

New branch, **before** the `alreadyConcluded && !replay` observational return, when `progress.ending != null && replay == false`:

1. `operationId` must equal `progress.currentOperation` or throw `StateError`.
2. If `echoConcludedOperations` contains all five IDs: **roll** first — `echoCycle += 1`, `echoConcludedOperations = {}`, `echoSignalRoutes = {}`. Do not clear `echoEnding`, `ending`, medals, transmissions, canonical routes, or `bestClearSeconds`.
3. Add `operationId` to `echoConcludedOperations`.
4. If `report.relayRoute != null`, write `echoSignalRoutes[operationId]`.
5. If recovered (always true in this branch) and `operationId` not in `medals`, add it (same medal-restore as replay).
6. `paysBonus = succeeded && !ledger.claimedDirectiveBonusIds.contains(operation.bonusClaimId)` — same IDs (`chronicle-directive-${id.name}`). Echo almost always pays 0.
7. If `report.recoveryElapsedSeconds` is a finite `> 0`: `bestClearSeconds[id] = min(existing, elapsed)`.
8. Do **not** mutate `concludedOperations`, `recoveredTransmissions`, `signalRoutes`, `ending`, `campaignFaction`.
9. `firstConclusion` is true iff this `operationId` was not in `echoConcludedOperations` before step 3.

Canonical first-run path (`ending == null`) is unchanged, except the same `bestClearSeconds` min-update.

#### `chooseEnding`

```text
if lastInstruction not in concludedOperations → StateError (existing)
if ending == null → copyWith(ending: choice)  // existing; echoCycle becomes 2 via decode coerce or explicit copyWith(echoCycle: 2)
if echoEnding != null → StateError('echo ending has already been chosen')
if lastInstruction not in echoConcludedOperations → StateError('echo OP-05 must conclude before residual ending')
return copyWith(echoEnding: choice)
```

When setting the **canonical** ending, also set `echoCycle: 2` if it is still 1. Do not clear anything else.

#### `restart`

Unchanged: `StoryProgress.initial()`. `initial()` defaults the new fields (`echoCycle: 1`, empty maps/sets, `echoEnding: null`). Wallet, cosmetics, settings, and `ProfileRewardLedger` still survive because `TokenfrontRuntime.restartChronicle` only replaces `_storyProgress`.

### 5.8 Runtime / battle wiring (names only)

- `TokenfrontRuntime.chooseChronicleEnding` / `concludeChronicle` / `restartChronicle` stay the public API. No new runtime method is required. After `chooseEnding`, persist via existing `_schedulePersist`.
- `TokenfrontRoot._openChronicleBriefing` already no-ops when `currentOperation == null`. After an ending it must **not** no-op, because the getter returns `wake`.
- `TokenfrontRoot._continueFromResult`: if `echoActive` and `echoConcludedOperations` contains all five, return to lobby **without** auto-starting the next battle. Otherwise keep today's auto-continue to the next operation. This is a branch in `_continueFromResult`, not a result-screen layout change.
- Chronicle battle start (`_startBattle` in `lib/main.dart`):
  - `recoveryMode: true` unchanged.
  - `config:` use `RecoveryState.configForCycle(progress.displayCycle)` when `replay == false`; use `RecoveryState.config` (cycle 1) when `replay == true`.
  - `seed:` `operation.seed + (displayCycle - 1) * 1000` when `replay == false`; `operation.seed` when `replay == true`.
- Grant cosmetics in `TokenfrontRuntime` after a successful conclude / chooseEnding (§8). `notifyEconomyChanged` + persist.

### 5.9 Surfaces — content only, layout frozen

| Surface | Allowed | Forbidden |
|---|---|---|
| Lobby sticky `_LobbyDeployBar` | Change **label** and `onPressed` nullability of `Key('chronicle-deploy')`. Show echo chip + briefing banner in the scroll body. | New buttons, moving the bar, changing padding. |
| Result `_ChronicleActionRow` | `showEndingChoices` also true for residual echo ending (same two buttons). Continue label may use existing `continueToOperation`. | New row structure, new third action. |
| Recovery HUD rails | None. `/8` occupancy labels unchanged. | Any rail / dest / pause move. |
| Archive | Subtitle for echo cycle, per-op best time, residual epilogue if `echoEnding != null`. Restart still wipes. | Removing restart, adding a second timeline widget. |

Lobby `pendingEnding` today is `operation == null && ending == null`. After this change that remains true **only** for canonical OP-05-done-no-ending. It is false once `ending` is set, so `_EndingChoicePanel` hides and deploy shows. Do not reuse `chronicleUnavailable` for post-ending; that string stays the catalog-failure notice.

`chronicleAvailable` in `TokenfrontRoot` remains catalog-load health. Do not set it false because the campaign ended.

---

## 6. Difficulty / escalation (numbers)

Cycle 1 **must** remain the device-validated constants. Tests that read `RecoveryState.requiredSeconds` / `midwaySeconds` / `radius` / `RecoveryState.config.matchLimitSeconds` / `unitsPerFaction` stay green without edits to those literals.

| `displayCycle` | `requiredSeconds` | `midwaySeconds` | `matchLimitSeconds` | `radius` | `unitsPerFaction` | seed |
|---:|---:|---:|---:|---:|---:|---|
| 1 | **8.0** | **5.0** | **90** | **64.0** | **100** | `StoryOperation.seed` |
| 2 | 8.0 | 5.0 | **78** | 64.0 | 100 | `seed + 1000` |
| 3 | 8.0 | 5.0 | **66** | 64.0 | 100 | `seed + 2000` |
| ≥ 4 | 8.0 | 5.0 | **54** | 64.0 | 100 | `seed + (displayCycle - 1) * 1000` |

`RecoveryRules.forCycle`:

```text
final n = cycle < 1 ? 1 : cycle;
requiredSeconds = 8.0          // never per-cycle
midwaySeconds   = 5.0          // never per-cycle
radius          = 64.0         // never per-cycle
unitsPerFaction = 100          // never per-cycle
matchLimitSeconds = n == 1 ? 90
                  : n == 2 ? 78
                  : n == 3 ? 66
                  : 54         // clamp for n >= 4
```

World size stays 1200×800. Destinations stay `(300,240)`, `(900,240)`, `(600,600)`. Node count stays 3.

**Per-cycle knobs (explicit):** only `BattleConfig.matchLimitSeconds` and the battle `seed`.  
**Not per-cycle:** `RecoveryState.requiredSeconds`, `midwaySeconds`, `radius`, `unitsPerFaction`, `StoryOperation.duration` (catalog 180 s is unused by recovery; do not change it), `Directive.target` (45 / 2 / 3 / 2 / 1). Recovery medal remains `recoveryOutcome == recovered`. Do not retarget directives for echo.

**Archive replay** (`replay: true`) always uses cycle-1 rules and the catalog seed, so a missed medal can be hunted on the original operation.

**Why the clock shrinks and occupancy does not:** playtest P1 moved occupancy 10 s → 8 s because 10 s felt slow inside a 90 s match. Echo must not reintroduce that wait. Cycle 4 is 24 s of occupancy inside 54 s of clock (44 % vs cycle 1's 27 %). Slack is the escalation. Seed offset changes the swarm without adding units on SM-F741N.

---

## 7. Narrative continuity

The Last Relay is a damaged authorization loop. The 2026-08-05 Chronicle design already states that the loop “repeats the war whenever the surviving memory becomes unstable.”

- **CLAIM THE RELAY** — one core inherits Orbit 00. The other three remain checksum scars. Those scars still contest the administrator slot. Echo is the residual contest. Canonical epilogue stays on the Archive.
- **OPEN THE RELAY** — the human-origin signal opened every channel. Residual authorization packets still fire while the loop dies. Echo is recovery of those dying nodes, not a contradiction of “the war ends.” Label sequential echo play `archiveSimulation` in the briefing banner so it does not overwrite the canonical open.

Echo is **canonical-adjacent residual traffic**, not a second plot. Transmissions already recovered are not rewritten. Operation titles stay. One banner line flavors the briefing. Doctrine is a subtitle, not a combat modifier.

Residual ending choice after echo OP-05: same two options. Picking the other records `echoEnding` and unlocks `trail_checksum_scar`. Picking the same is allowed. The canonical `ending` field does not move.

`RESTART CHRONICLE` remains the only way to unlock a new campaign core. It destroys faction, medals, transmissions, routes, both endings, echo fields, and best times. Wallet and ledger remain.

---

## 8. Reward and economy

War Tokens buy cosmetics only. Combat power never changes.

| Source | Cycle 1 | Cycle 2 | Cycle 3 | Cycle ≥ 4 |
|---|---:|---:|---:|---:|
| Recovery match WT on success (`recoveredCount == 3`) | **60** (`max(40, 3×20)`, existing `RecoveryState.reward`) | 60 | **40** | **20** |
| Recovery match WT on fail | 0 | 0 | 0 | 0 |
| Directive `oneTimeBonus` (15/20/25/30/40) | once, via `ProfileRewardLedger` | 0 if already claimed | 0 | 0 |
| Rewarded-ad double | existing, base match only | same | same | same |

Implement match WT as:

```text
if (!succeeded) return 0;
final base = recoveredCount * 20 < 40 ? 40 : recoveredCount * 20; // existing
if (displayCycle <= 2) return base;
if (displayCycle == 3) return 40;
return 20;
```

Cycle 1 must hit the existing 60-on-success path (do not replace the formula with a constant 60 in `RecoveryState.reward` for cycle 1; keep the current getter for cycle-1 / Archive replay). Cycle 2+ may apply the table after that getter, in `TokenfrontRoot` when assigning `baseReward`, using `displayCycle` of the match that just ran (the cycle **before** a post-OP-05 roll; pass `echoCycle` from the transition's `nextProgress` carefully: sequential echo OP-05 does not roll until the next wake deploy, so `echoCycle` is still the cycle that was played).

**Farming bound:** directive bonuses cannot be farmed. Match WT decays to 20 and stays there. The locker catalog is finite (~630 WT of paid cosmetics). Ads stay consent-gated and optional; do not add placements, caps, or new formats.

**Cosmetic grants (cost 0, unlock, never sell for power):**

| id | category | When |
|---|---|---|
| `color_echo_orbit` | `CosmeticCategory.factionColor` | First time `echoCycle` becomes `>= 3` after a roll **or** first time `echoConcludedOperations` fills all five while `echoCycle == 2` (first echo cycle cleared). Idempotent `wallet.unlock`. |
| `trail_checksum_scar` | `CosmeticCategory.movementTrail` | `{ending, echoEnding}` as a set equals `{EndingChoice.claimRelay, EndingChoice.openRelay}`. Idempotent. |

Add both to `CosmeticCatalog.items` with English names `ECHO ORBIT` and `CHECKSUM SCAR`. Localized locker names may reuse the English instrument labels in this pass (catalog names are not ARB today); do not block on that.

---

## 9. Session length honesty

| Beat | Wall clock |
|---|---|
| One recovery match | ≤ `matchLimitSeconds` (90 / 78 / 66 / 54) plus 1.5 s handoffs |
| Result + lobby | ~20–40 s |
| **Target session** | **one operation, ~2 minutes** |
| Full echo cycle (5 ops) | ~10–12 minutes |
| Skirmish (unchanged) | 15 minutes |

The lobby CTA deploys **one** operation, not five. A commute session is one echo recovery. A sitting session is a full cycle. Both fit a phone. Do not chain five battles without a lobby return after echo OP-05 (§5.8).

---

## 10. New ARB keys (English source)

Author `ko` / `ja` / `zh` in the same change as `en`. Korean and Japanese are the longest; every **button** string must fit `TokenfrontSizes.buttonSize` (124×50) or the existing expanded sticky bar. Do not put cycle flavor on destination rails.

| Key | English source | Where | Length budget |
|---|---|---|---|
| `echoDeploy` | `Recover the echo` | Lobby `chronicle-deploy` label when `echoActive` | ≤ current `recoveryTitle` (`Recover three signals` / ko `신호 세 개 회수하기`) |
| `echoCycleChip` | `ECHO {cycle}` | Lobby instrument chip | short; ko target `에코 {cycle}` |
| `echoBannerClaim` | `Orbit 00 still crowns one core. Residual scars contest the slot. Recover the three nodes.` | Lobby briefing when `ending == claimRelay` | body, 3 lines max |
| `echoBannerOpen` | `The relay is open. Residual packets still fire. Recover the three nodes before the loop forgets itself.` | Lobby briefing when `ending == openRelay` | body, 3 lines max |
| `echoDoctrinePreserve` | `Canonical doctrine: CONTINUITY. The residual loop tests whether pressure would have held.` | Optional briefing subtitle when `signalDoctrine == preserve` | 2 lines |
| `echoDoctrineForce` | `Canonical doctrine: PRESSURE. The residual loop tests whether continuity would have held.` | `signalDoctrine == force` | 2 lines |
| `echoDoctrineBalanced` | `Canonical doctrine: ADAPTIVE. The residual loop no longer agrees with itself.` | `signalDoctrine == balanced` | 2 lines |
| `echoResidualHeading` | `RESIDUAL CHOICE` | Result ending panel when setting `echoEnding` | instrument |
| `echoBestClear` | `BEST {seconds}s` | Archive row | instrument |
| `echoArchiveCaption` | `ECHO CYCLE {cycle} // CANONICAL ENDING PRESERVED` | Archive header when `echoActive` | instrument, ellipsis OK |
| `echoCosmeticOrbit` | `ECHO ORBIT unlocked` | Optional result/locker toast; may be unused if unlock is silent | — |
| `echoCosmeticScar` | `CHECKSUM SCAR unlocked` | same | — |

Update existing `restartDisclosure` English to:

> Campaign core, progress, transmissions, medals, echo cycles, and ending reset. Wallet, settings, and cosmetics remain. Previously awarded operation bonuses cannot be earned again.

Keep the key. Translate ko/ja/zh to match. `chronicleUnavailable` is **not** used for post-ending.

`StoryLocalizations` maps the new keys with exhaustive switches where they depend on `EndingChoice` / `SignalDoctrine`. Skip the doctrine subtitle when `signalDoctrine == undecided`.

---

## 11. Observable acceptance (mechanically checkable)

Engineer converts each row into a unit or widget test. Cycle-1 literals in `recovery.dart` must not be edited.

### A. Lobby is playable after an ending

| ID | Check | Pass if |
|---|---|---|
| A1 | Progress with all five `concludedOperations`, `ending: EndingChoice.openRelay`, missing echo keys | `StoryProgress.fromJson` succeeds; `echoCycle == 2`; `currentOperation == StoryOperationId.wake`; `isSemanticallyValid == true` |
| A2 | Pump `LobbyScreen` with that progress | `Key('chronicle-deploy')` exists; `tester.widget<ButtonStyleButton>(...).onPressed != null` (or `TacticalButton` equivalent); label is `echoDeploy`, not `chronicleUnavailable` |
| A3 | Same lobby, `ending == null`, all five concluded | Deploy hidden or disabled; `_EndingChoicePanel` / `claim-ending` visible (today's behavior) |
| A4 | `chronicleAvailable: false` still disables the **mode rail** via existing key `chronicle-deploy-disabled`; this flag is not set by choosing an ending | Catalog-failure path unchanged |

### B. Record is not destroyed

| ID | Check | Pass if |
|---|---|---|
| B1 | `chooseEnding` on a completed campaign | `ending` equals the choice; `campaignFaction`, `medals`, `recoveredTransmissions`, `signalRoutes` identical to pre-choice |
| B2 | Full echo cycle then `chooseEnding` residual | `ending` unchanged; `echoEnding` equals the new choice; `echoEnding` may equal `ending` |
| B3 | Second `chooseEnding` after `echoEnding` set | throws `StateError` |
| B4 | `restart()` | `== StoryProgress.initial()` including `echoCycle == 1` and empty echo fields; runtime wallet/ledger unchanged (existing test) |

### C. Old saves decode

| ID | Check | Pass if |
|---|---|---|
| C1 | Schema 3 fixture from `test/runtime_test.dart` with story JSON **as written today** (no echo keys), ending `openRelay` | restore succeeds; `currentOperation == wake`; wallet/ledger intact |
| C2 | Same fixture, `ending: null`, `concludedOperations: [wake, echo]` | `currentOperation == split`; `echoCycle == 1`; echo sets empty |
| C3 | Schema 3 encode after echo play still has `'version': 3` | `_TokenfrontLocalState._version == 3`; no version 4 |
| C4 | Invalid `echoCycle: 0` | `fromJson` throws `FormatException` |

### D. Cycle-1 difficulty unchanged

| ID | Check | Pass if |
|---|---|---|
| D1 | `RecoveryState.requiredSeconds == 8.0` | literal |
| D2 | `RecoveryState.midwaySeconds == 5.0` | literal |
| D3 | `RecoveryState.radius == 64.0` | literal |
| D4 | `RecoveryState.config.unitsPerFaction == 100` | literal |
| D5 | `RecoveryState.config.matchLimitSeconds == 90` | literal |
| D6 | `RecoveryRules.forCycle(1).battleConfig` equals `RecoveryState.config` | `==` |
| D7 | Existing `test/recovery_test.dart` | still green **without** changing occupancy assertions |
| D8 | `StoryCatalog` seeds, durations (180 s), directive targets, `oneTimeBonus` | unchanged |

### E. Echo rules

| ID | Check | Pass if |
|---|---|---|
| E1 | `RecoveryRules.forCycle(2).matchLimitSeconds == 78` | |
| E2 | `forCycle(3) == 66`, `forCycle(4) == 54`, `forCycle(99) == 54` | clamp |
| E3 | `forCycle(2).requiredSeconds == 8.0` (and 3, 4) | occupancy not escalated |
| E4 | Sequential echo conclude of `wake` with `ending` set | `echoConcludedOperations == {wake}`; canonical `concludedOperations` still all five |
| E5 | Echo conclude with `recoveryOutcome: timeout` | progress identical, `directiveBonusCredit == 0` |
| E6 | Echo conclude when ledger already has `chronicle-directive-wake` | `directiveBonusCredit == 0` |
| E7 | `bestClearSeconds` updates to min elapsed on recovered reports | 70 then 55 → 55; failed report does not write |
| E8 | After five echo concludes, `currentOperation == wake`, `displayCycle == echoCycle + 1` | |
| E9 | Next `wake` sequential conclude rolls `echoCycle += 1` and starts with `{wake}` | |
| E10 | Archive replay `replay: true` during echo does not add to `echoConcludedOperations` | |

### F. Economy and cosmetics

| ID | Check | Pass if |
|---|---|---|
| F1 | Cycle 1 success base reward 60 | existing formula |
| F2 | Cycle 3 success base reward 40; cycle 4+ is 20 | |
| F3 | Unlock `color_echo_orbit` on first echo-cycle clear; second clear does not duplicate | `unlockedIds` contains id once |
| F4 | Unlock `trail_checksum_scar` only when the two ending fields are different members of `EndingChoice` | same ending twice → locked |

### G. Layout regressions (must stay green)

| ID | Check | Pass if |
|---|---|---|
| G1 | Lobby deploy bar still outside the `SingleChildScrollView` | existing widget test |
| G2 | Result `chronicle-action-layer` still one continue/retry row or the existing ending panel | no new sibling bar |
| G3 | Recovery HUD rail tests at 2640×1080 | unchanged dest keys and `/8` |

---

## 12. Out of scope

- Joystick, dash, or direct unit control in Chronicle. Recovery stays destination-selection.
- Any change to battle HUD gutter rails, dest 1/2/3 placement, pause, or occupancy ring art.
- Any change to lobby sticky deploy **layout** or result action **row layout**.
- Energy timers, lootboxes, pay-to-progress, IAP, accounts, servers, online leaderboards.
- New ad placements or rewarded-ad expansion.
- Live-service weekly operations, procedural OP-06+, or authored OP-06+.
- Per-faction combat powers. Doctrine as a combat modifier.
- Skirmish progression, Skirmish WT changes, or 4,000-unit Chronicle return.
- Retuning cycle-1 8 / 5 / 90 / 64 / 100.
- Changing `StoryCatalog` seeds, 180 s durations, or directive targets.
- Grade ranks (S/A/B/C), no-loss badges, all-three-nodes badges (tautological).
- Forcing the opposite ending.
- Bumping persistence schema above 3.
- New third-party dependencies.
- Overwriting canonical `ending` except via `restart()`.

---

## 13. Implementation order for the engineering worker

1. `lib/story/story_models.dart` — fields, JSON defaults, `currentOperation`, `displayCycle`, `isSemanticallyValid`, `BattleReport.recoveryElapsedSeconds`.
2. `lib/game/recovery.dart` — `RecoveryRules` + `configForCycle`; **do not edit** the five cycle-1 literals.
3. `lib/story/campaign_controller.dart` — echo `conclude` branch, `chooseEnding` residual path, `bestClearSeconds`.
4. `lib/app/tokenfront_runtime.dart` — cosmetic grants; schema version stays 3.
5. `lib/main.dart` — seed/config per `displayCycle`; continue-from-result lobby return after a full echo cycle; fill `recoveryElapsedSeconds` on the report.
6. `lib/ui/lobby_screen.dart` — deploy label + enablement; echo banner in the scroll body. Sticky bar structure untouched.
7. `lib/ui/result_screen.dart` — residual `showEndingChoices` condition only.
8. `lib/ui/archive_sheet.dart` — caption + best time; restart disclosure via updated ARB.
9. `lib/economy/cosmetic_catalog.dart` — two cost-0 items.
10. ARB en/ko/ja/zh + `flutter gen-l10n` + `StoryLocalizations`.
11. Tests in §11. Update any test that asserts `currentOperation == null` **after** `chooseEnding` (that assertion is now wrong). Tests that assert `null` **before** ending stay.

---

## 14. What this document is not

- Not a retune of occupancy, radius, unit count, or HUD rails.
- Not a Skirmish redesign.
- Not a request for joystick, endless procedural ops, or a mastery spreadsheet.
- Not Dart. Field names and numbers here are the implementation contract.
