# Tokenfront: Signal Chronicle — Story Campaign Design

**Status:** Approved direction, pending written-spec review
**Date:** 2026-08-05
**Design model:** GPT-5.6 Sol, ultra reasoning

## Decision

Tokenfront gains a five-operation story campaign named **SIGNAL CHRONICLE**. It turns the existing movement, direct combat, command handoff, faction standings, and result systems into five distinct narrative assignments instead of adding a disconnected lore gallery.

Each campaign operation uses the existing four factions and 4,000-unit deterministic battle, advances for at most 180 simulation seconds, and gives the player one optional directive that rewards a different behavior. Pause time and the existing handoff slowdown can make wall-clock play longer than three minutes. Completing an attempt advances the story regardless of victory or elimination. Fulfilling the directive awards a medal and a one-time War Token bonus. The existing 15-minute battle remains available as **SKIRMISH**.

This design replaces the earlier design's Lobby, Battle HUD, Result, and localization presentation. It retains the earlier design's orbital world, neutral faction IDs, app and Web metadata, Blender asset direction, Skirmish rules and 15-minute limit, and new Cloudflare project target. Signal Chronicle supplies the missing plot, player role, campaign loop, and replay motivation.

## Problem

The current product repeats one loop: select a faction, enter the same 15-minute battle, view standings and rewards, then rematch or return to the lobby. It contains no campaign state, mission objective, story reveal, or narrative consequence. The unique 1.5-second command-handoff mechanic is visually strong but has no story meaning, and the first match records `tutorial_completed` without presenting a real tutorial or structured learning sequence.

The redesign must:

- make the player understand who they are and why the war continues;
- make each of five early sessions encourage a different play style;
- use the current combat rather than promise an unimplemented starship game;
- keep story access from being blocked by combat difficulty;
- preserve offline play, deterministic performance, accessibility, localization, and Skirmish behavior.

## Options considered

### 1. Five-operation Signal Chronicle — selected

Reuse the current battle with short operation limits, live directives, debriefing, persistent medals, two endings, and an archive. This makes the story change what the player tries to do while keeping the combat core stable.

### 2. Full campaign with new maps, faction abilities, and AI rules — deferred

This would create the strongest content variety, but it expands balance, art, simulation, performance, and QA at the same time. It is a later update after the campaign proves its loop.

### 3. Result-only lore unlocks — rejected

This is inexpensive but leaves the battle itself repetitive and fails to address the lack of gameplay motivation.

## World and player role

The surface has been silent for 72 years. **Orbit 00**, the final functioning relay layer, exposes only one administrator slot. Its damaged authorization loop orders four command cores to fight until one remains:

- **AMETHYST // ARCHIVE** remembers what the war deletes.
- **COBALT // BASTION** endures so the signal outlives its body.
- **VOLT // SURGE** crosses a gap before silence can close it.
- **PRISM // MIRROR** changes its pattern to preserve the message.

The player is not a single unit. The player is a human-origin **command signal** that occupies one unit at a time. When that body falls, the signal moves into a surviving unit. Command handoff is therefore the story's central verb, not a recovery animation detached from the fiction.

Across five operations, the signal reconstructs a final human instruction. It discovers that the four enemies share one root checksum: they were once four protocols inside the same planetary defense intelligence. The Last Relay's winner-only authorization loop forces them to erase one another and then repeats the war whenever the surviving memory becomes unstable.

## Campaign structure

Campaign battles use a 180-simulation-second limit. Four factions still begin with 1,000 units each and retain identical combat rules. An operation attempt concludes at that limit, global battle resolution, or complete elimination of the player's faction. If the limit arrives during a handoff presentation, the presentation finishes before debrief; OP-02 counts it only when the existing successful handoff callback completes.

Every concluded attempt unlocks the next operation and its recovered transmission, including an eliminated or losing attempt. A directive is independent of narrative progression: success grants a medal and its one-time bonus; failure displays `DIRECTIVE MISSED` and leaves the operation replayable from the Archive.

| Operation | Seed | Story beat | Directive | Recovered transmission | Bonus |
|---|---:|---|---|---|---:|
| OP-01 `WAKE // DEAD ORBIT` | `2026080501` | A pulse with human authority rises from the silent surface. | Maintain one uninterrupted command link for 45 seconds. | `KEEP THE LINK—` | 15 WT |
| OP-02 `ECHO // BORROWED BODIES` | `2026080502` | The command signal survives the destruction of its current body. | Complete two command handoffs. | `—WHEN ONE BODY FALLS, MOVE—` | 20 WT |
| OP-03 `SPLIT // FOUR FROM ONE` | `2026080503` | Enemy and allied cores return the same root checksum. | Accumulate three kills by units while directly commanded. | `—FOUR CORES, ONE ROOT—` | 25 WT |
| OP-04 `CROWN // FALSE WINNER` | `2026080504` | The administrator contest is revealed as an erasure loop. | Finish at rank two or better. | `—THE WINNER ERASES THE REST—` | 30 WT |
| OP-05 `LAST // THE INSTRUCTION` | `2026080505` | The final human order is reconstructed before deletion. | Win the battle. | `—DO NOT CHOOSE ONE. OPEN THE RELAY.` | 40 WT |

Directive boundary rules are exact:

- OP-01 succeeds at `longestCommandLinkSeconds >= 45.0`.
- OP-02 succeeds at `commandRelays >= 2` after completed handoffs only.
- OP-03 succeeds at `commandKills >= 3`; AI-controlled allied kills never count, while kills by later commanded bodies continue the same total.
- OP-04 succeeds at `playerRank <= 2`, including deterministic time-limit ranking.
- OP-05 succeeds only when the selected faction is the sole winner; a draw does not count.

## Narrative source copy

The prologue shown before core selection is: `The surface has been silent for 72 years. You are a command signal without a body. The Last Relay is calling.`

English is the content source; the other locales translate its meaning and voice rather than preserving English word order.

| Operation | Briefing | Shared debrief response |
|---|---|---|
| OP-01 | `A human-authority pulse is rising from the silent surface. Keep one body online long enough to triangulate it.` | `The pulse did not address a unit. It addressed the signal moving between them.` |
| OP-02 | `Your current body is expendable. The instruction is not. Cross two deaths without losing the link.` | `A body can be destroyed. Command continuity survives the transfer.` |
| OP-03 | `Enemy checksums match your own root. Enter direct combat and recover an intact comparison.` | `Four armies return one origin key. The enemy was once part of the same guardian.` |
| OP-04 | `The relay crowns one survivor, then deletes every competing memory. Reach the crown key before the cycle closes.` | `This war is not choosing a defender. It is erasing witnesses to a damaged authorization loop.` |
| OP-05 | `The final packet is sealed inside the administrator lock. Break the field before the loop resets.` | `The human order was never to choose a winner. It was to keep every command channel open.` |

The selected core name is inserted into the shared debrief response. Faction personality remains in the four lobby identity lines above rather than multiplying campaign outcomes.

## Ending choice

After the first OP-05 attempt concludes, the recovered instruction unlocks two narrative choices:

- **CLAIM THE RELAY** — the selected campaign core becomes the sole administrator and preserves the old authorization model.
- **OPEN THE RELAY** — the human-origin signal broadcasts the shared memory to all four cores and disables the winner-only loop.

The choice changes the ending record, Archive epilogue, and final debrief copy only. It never changes combat power, rewards, or Skirmish behavior. The selected ending is persistent but can be replaced only by explicitly restarting the Chronicle.

- **CLAIM epilogue:** `One core inherits Orbit 00. The other three survive only as checksum scars.`
- **OPEN epilogue:** `The relay opens. Four distinct cores receive the same memory. The authorization war ends.`

After either ending, operation replays and Skirmish are labeled `ARCHIVE SIMULATION // NON-CANONICAL` so continued play does not contradict the canonical ending.

## Player loop

```text
Command Deck
  → operation briefing and core identity
  → 3-minute battle with one live directive
  → command handoff and directive milestones
  → debrief, transmission recovery, medal, reward
  → next node opens on the broken orbital ring
  → final relay choice and persistent epilogue
```

The five directives form an implicit tutorial without a separate training arena:

- OP-01 teaches controlled movement, danger reading, and survival.
- OP-02 makes handoff desirable rather than treating every death as pure failure.
- OP-03 asks the player to seek direct combat.
- OP-04 asks the player to read the minimap and faction-wide battle state.
- OP-05 tests the complete rule set through the existing victory condition.

Any concluded operation can be replayed immediately from the Archive. Replay never changes the first incomplete sequential operation, recovered transmissions, or an existing ending. It can restore a missing medal and claim that operation's still-unclaimed one-time directive bonus. `CONTINUE` advances a first-run attempt to the next sequential operation; after a replay it returns to the Archive. After the Chronicle ends, the player can restart with another campaign core or continue Skirmish under the non-canonical archive-simulation label.

## Screen design

### Command Deck lobby

The current operation becomes the lobby's primary hierarchy. The screen retains Tokenfront's dark tactical console, beveled panels, faction colors, monospace instruments, and Blender key art.

```text
TOKENFRONT                              ORBIT 00 // 03 OF 05

          broken five-node orbital ring
          ●────●────◉    ○    ○

OP-03 // FOUR FROM ONE
Enemy signals carry the same root key as your own.

DIRECTIVE   COMMAND KILLS 0 / 3             BONUS 25 WT

[ AMETHYST ] [ COBALT ] [ VOLT ] [ PRISM ]

[ DEPLOY OP-03 ]     [ SKIRMISH ]     [ ARCHIVE ]
```

On a fresh profile, selecting a core and starting OP-01 locks that core for the current Chronicle. Skirmish always allows free faction selection. Changing the campaign core is available only through `RESTART CHRONICLE`, with a confirmation that medals, recovered transmissions, and ending choice will reset; wallet, cosmetics, settings, Skirmish, and the lifetime directive-bonus claim ledger remain untouched. The confirmation explicitly says that previously paid operation bonuses cannot be earned again.

The signature element is a **broken five-node orbital ring**. Each concluded operation joins one segment and lights its node. The ring carries real progress information and is the only new decorative emphasis.

### Battle directive rail

A compact, non-interactive directive rail sits immediately below the existing top command rail:

- visible form: `DIRECTIVE // COMMAND KILLS 1 / 3`;
- achieved form: `DIRECTIVE LOCKED // BONUS READY`;
- missed state appears only in debrief;
- progress reuses the existing HUD publish cadence rather than scanning 4,000 units again;
- the rail hides optional animation in low-spec or reduced-motion mode but retains text and state;
- screen readers announce only operation start, midpoint where applicable, and completion, never every HUD tick.

When a directive completes, the rail shows a two-second `DIRECTIVE LOCKED` transmission cue. It does not pause the battle, steal focus, or block movement.

### Debrief result

The result screen adds a story panel before the existing standings and reward sections:

1. `TRANSMISSION RECOVERED` and the operation title;
2. the newly decoded fragment and one short core response;
3. directive success or failure, medal status, and one-time bonus status;
4. existing faction standings and base match reward;
5. `CONTINUE`, `RETRY DIRECTIVE`, and `COMMAND DECK` actions.

Elimination in Chronicle returns directly to the debrief rather than forcing the player to spectate the remaining battle. Skirmish retains its existing spectator behavior.

The directive medal, lifetime bonus-claim ID, and War Token credit are applied together only when a Chronicle conclusion is created and the debrief state is entered. A locked directive followed by elimination still pays at debrief. A process exit before conclusion pays nothing. Rewarded-ad doubling applies only to the existing base match reward, never to a directive bonus.

### Archive sheet

The Archive is a lobby bottom sheet that shows:

- five orbital nodes with concluded, current, and locked states;
- recovered transmissions in operation order;
- directive medals and whether each bonus was claimed;
- the final ending and epilogue after OP-05;
- replay for concluded operations;
- Chronicle restart and campaign-core change.

The first incomplete operation in sequence remains the current progression target. Replays never move that pointer or alter an ending.

Locked entries reveal only their operation number and silhouette. The Archive remains fully usable with keyboard focus, screen readers, reduced motion, and narrow portrait layouts.

## Architecture and responsibilities

### Domain types

```dart
enum GameMode { chronicle, skirmish }

enum StoryOperationId { wake, echo, split, crown, lastInstruction }

enum DirectiveKind {
  longestCommandLink,
  commandRelays,
  commandKills,
  finalRank,
  victory,
}

enum EndingChoice { claimRelay, openRelay }

enum ChronicleEndReason { timeLimit, globalResolution, playerEliminated }

final class StoryOperation {
  StoryOperationId id;
  int seed;
  Duration duration;
  Directive directive;
  int oneTimeBonus;
}

final class BattleReport {
  ChronicleEndReason endReason;
  List<FactionStanding> standingsAtConclusion;
  Faction? globalWinner;
  int commandRelays;
  int commandKills;
  double longestCommandLinkSeconds;
  int playerRank;
  int playerSurvivors;
}
```

### Modules

- `StoryCatalog` is immutable content: operation order, deterministic seeds, duration, directive thresholds, and bonuses.
- `StoryProgress` is serializable state: campaign core, concluded operations, current operation, medals, recovered transmissions, and ending choice.
- `ProfileRewardLedger` stores directive-bonus claim IDs for the lifetime of the local profile and is not reset with Chronicle progress.
- `CampaignController` is a pure rules layer. It converts a `BattleReport` into a directive result and an idempotent progress/reward transition.
- `TokenfrontGame` counts command-only kills, completed handoffs, and uninterrupted command-link duration at existing event/update points. It produces `BattleReport`; it does not own story copy or persistence.
- `TokenfrontRoot` owns `GameMode`, operation selection, and screen transitions. It passes a 180-simulation-second `BattleConfig` only for Chronicle and the current default config for Skirmish.
- `LobbyScreen`, `BattleScreen`, `ResultScreen`, and `ArchiveSheet` receive view data and callbacks. They do not independently decide progression or reward eligibility.
- ARB resources own all operation titles, briefings, fragments, directives, core responses, endings, semantics, and errors in English, Korean, Japanese, and Simplified Chinese.

The existing `Faction` enum is renamed to the neutral internal identifiers `amethyst`, `cobalt`, `volt`, and `prism` as required by the Orbital Signal War design. Stable serialized story identifiers use the enum names from this neutral model. Debug combat-log schema increments because faction identifiers change.

## Metric collection

Directive collection adds no new per-frame scan over all units.

- Longest command link increments from simulation time only while the current commanded unit remains the same and alive; a completed handoff resets the current streak after preserving its maximum.
- Handoffs increment only after the existing 1.5-second sequence completes successfully.
- Command kills compare each combat event against the controlled unit ID captured immediately before that simulation step. Comparing against the post-step successor ID is prohibited.
- Rank derives from `standingsAtConclusion`; victory requires `globalWinner` to equal the campaign core. Player elimination uses the current standings snapshot without manufacturing a completed Skirmish `MatchResult`.
- The directive view reads these values from the existing HUD snapshot cadence: standard mode at the current rate and low-spec mode at its existing reduced rate.

## Persistence and migration

The local snapshot moves from schema 1 to schema 2. Schema 2 must explicitly decode schema 1 instead of treating it as corrupt.

Migration guarantees:

- preserve War Token balance, unlocks, equipped cosmetics, language, accessibility, audio, camera, privacy, and advertising choices;
- add default empty `story` state when loading schema 1;
- decode wallet, preferences, privacy, and story independently so malformed story data resets only Chronicle progress;
- store stable English identifiers rather than translated strings;
- persist every concluded operation, medal, lifetime claimed-bonus ID, campaign core, restart, and ending choice;
- make progress and bonus application idempotent when result callbacks repeat or the app restarts;
- never claim a directive bonus before the directive succeeds.

Chronicle restart clears core, conclusion state, transmissions, medals, and ending only. It never clears the lifetime bonus ledger. In-progress battles are not restored; relaunching returns to the current operation briefing without changing progress or rewards.

## Reward policy

- Every concluded Chronicle attempt uses the existing base match-reward formula, including a loss or player-faction elimination.
- Replays may earn the normal base match reward again.
- Each directive bonus is paid once per local profile and operation, regardless of Chronicle restart.
- Directive medal, lifetime claim ID, and WT credit are one idempotent debrief transition.
- Rewarded advertising can double only the base match reward; it never multiplies a directive bonus.

## Localization

English remains the source locale. Korean, Japanese, and Simplified Chinese ship simultaneously. Every locale includes:

- Chronicle, Skirmish, Archive, restart, briefing, directive, debrief, and ending controls;
- five operation titles and briefings;
- five recovered transmission fragments;
- five shared debrief responses with the selected core name supplied as a placeholder;
- directive progress, success, failure, medal, and bonus states;
- accessibility labels and announcements.

Operation IDs, thresholds, ranks, and reward amounts are data, not embedded in translation strings. Generated localization Dart files are regenerated from ARB sources and are not hand-maintained.

## Failure behavior

- Player faction eliminated in Chronicle: end the operation immediately, record the attempt as concluded, unlock its transmission and next operation, award no directive medal unless it had already succeeded, then show debrief.
- Directive missed: story continues; medal and bonus remain available on replay.
- Replayed directive already rewarded: retain the medal and show `BONUS CLAIMED`; never credit twice.
- App backgrounded: existing pause behavior remains. If the process is killed, return to briefing with no partial attempt recorded.
- State write failure: continue the session, keep the existing retry policy, and avoid showing a false saved indicator.
- Invalid story identifiers or ranges: recover to the last internally consistent operation; preserve all non-story local state.
- Missing story content or localization: fail generation/build in development; if an unexpected runtime lookup fails, show the stable operation code rather than a blank control.
- Low-spec/reduced-motion: preserve all copy, progression, directive checks, and focus behavior; remove only orbit-ring and transmission animation.
- Story subsystem construction failure: keep Skirmish playable and surface a clear `CHRONICLE UNAVAILABLE` message.

## Analytics boundaries

The MVP changes only the existing tutorial boundary: the first Chronicle operation replaces the current false `tutorial_completed` shortcut, and tutorial completion records only after OP-01 concludes for the first time. Chronicle-specific analytics events are explicitly deferred. Analytics failure cannot block progress, rewards, or offline play.

## Testing strategy

Implementation follows red-green-refactor.

### Domain tests

- catalog contains exactly five ordered operations with seeds `2026080501` through `2026080505`, 180 simulation seconds, thresholds, and bonuses;
- directive boundaries pass at exactly 45 seconds, 2 relays, 3 command kills, rank 2, and a sole winner;
- directive values immediately below each boundary fail;
- allied AI kills never count, later commanded bodies do count, and failed handoffs do not count;
- narrative advancement and directive success are independent;
- elimination still concludes an operation and unlocks the next story entry;
- duplicate reports do not duplicate conclusion, medals, or rewards;
- final ending requires OP-05 conclusion and only one valid stored choice.
- player elimination produces a standings snapshot and `playerEliminated` end reason without completing or mutating the Skirmish simulation result;
- a handoff crossing the 180-second limit counts only after its successful completion callback.

### Persistence tests

- schema 1 migrates to schema 2 while preserving wallet, cosmetics, all settings, language, and privacy choices;
- schema 2 round-trips campaign core, operation states, medals, bonus claims, and ending;
- malformed story resets only story while preserving wallet and preferences;
- flush/recreate returns to the exact next operation;
- Chronicle restart clears progress, medals, transmissions, core, and ending while preserving the lifetime directive-bonus ledger;
- completing the same directive after Chronicle restart restores its medal but does not credit WT again.

### Widget and localization tests

- a fresh profile shows OP-01, free core selection, Chronicle, Skirmish, and Archive;
- starting Chronicle locks the campaign core while Skirmish retains free selection;
- live directive progress and completion render without per-tick semantic spam;
- Chronicle elimination routes to debrief while Skirmish still permits spectating;
- directive success and failure produce the correct debrief and action set;
- final choice and epilogue persist in Archive;
- concluded-operation replay leaves current progression and ending unchanged;
- after an ending, replay and Skirmish visibly show `ARCHIVE SIMULATION // NON-CANONICAL`;
- all EN, KO, JA, and ZH story keys render and preserve the same operation numbers and rule meaning;
- no real AI product brand appears in visible UI, persistence IDs, or newly exported debug logs;
- 320×568 lobby/Archive and 568×320 plus 844×390 battle surfaces have no overflow or overlap with the 104dp joystick, 72dp dash, and minimap;
- keyboard focus, screen-reader milestones, and reduced-motion behavior remain usable.

### Integration and regression tests

- fresh state → choose core → conclude OP-01 → relaunch → OP-02 restored;
- eliminate player faction → debrief → next operation unlocked without medal;
- succeed directive → one bonus → replay → no duplicate bonus;
- lock directive → terminate before conclusion → relaunch with no progress, medal, or bonus;
- lock directive → player elimination → debrief grants progress, medal, and exactly one bonus;
- complete five attempts → choose ending → relaunch → Archive preserves ending;
- lose or become eliminated in OP-05 → story still concludes and ending choice unlocks;
- rewarded doubling changes the base reward only and never the directive bonus;
- all four campaign cores complete all five fixed seeds with 4,000 units and deterministic conclusion reporting;
- Skirmish keeps 15-minute limit, 4,000 units, handoff, spectator, ranking, and current base-reward behavior;
- all existing simulation, input, orientation, persistence, economy, service, and localization tests remain green;
- static analysis and release Web build pass.

### Performance acceptance

- campaign retains 4,000 units and fixed 30Hz simulation;
- metric collection iterates combat events only and adds no extra full-unit scan;
- directive UI reuses the current HUD publish cadence;
- the established render culling, atlas batching, far-AI throttling, and low-spec behavior remain intact;
- hands-on Web QA verifies desktop and mobile landscape command input, operation flow, debrief, archive, and relaunch persistence.

## MVP scope

### Included

- Orbital Signal War public rebrand and neutral internal faction identifiers;
- five three-minute Chronicle operations;
- five live directives, medals, and one-time bonuses;
- persistent campaign core, progression, Archive, and two endings;
- Chronicle briefing, battle rail, debrief, replay, restart, and Skirmish split;
- English, Korean, Japanese, and Simplified Chinese;
- deterministic offline operation and schema-1 migration;
- existing enlarged mobile controls and accessibility behavior.

### Excluded

- voice acting, video cutscenes, downloadable content, or online inference;
- faction-exclusive abilities, asymmetric balance, bosses, new maps, capture points, or ship physics;
- procedural missions, daily challenges, cloud saves, accounts, or multiplayer;
- ending-dependent combat statistics or rewards;
- store submission, live ad credentials, or purchases.

## Acceptance criteria

- From the first lobby and OP-01 briefing, a new player can state that they are a command signal moving between bodies to recover a human instruction from the Last Relay.
- Five operations deliver five distinct play prompts and a complete reveal with two persistent endings.
- Story always advances after a concluded operation attempt; mastery rewards remain optional and replayable.
- Chronicle progress, medals, bonus claims, core, and ending survive restart without losing schema-1 user data.
- Skirmish preserves the current unrestricted 15-minute battle and existing reward behavior.
- All four locales, narrow/mobile surfaces, accessibility behavior, simulation performance, tests, static analysis, and Web release build meet the verification requirements above.
- The verified Web release is deployed to the retained Cloudflare target `tokenfront-orbital-war.pages.dev`; the old AI Arena deployment is not deleted as part of this work.
