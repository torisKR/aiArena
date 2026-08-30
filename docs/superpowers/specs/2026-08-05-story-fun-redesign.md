# Tokenfront: Story & Fun Redesign

**Status:** Approved implementation specification
**Date:** 2026-08-05
**Design model:** GPT-5.6 Sol, ultra reasoning

## Diagnosis

Signal Chronicle already has five fixed operations, localized story copy, medals,
transmissions, rewards, and two endings. The failure is experiential: the lobby
and briefing render the same screen, battle exposes only a read-only directive,
handoff timing and destination are automatic, and the first complete narrative
beat arrives after combat on the result screen. Chronicle currently feels like
lore beside the battle rather than a story expressed through play.

The redesign keeps the current 4,000-live-token, 30 Hz deterministic simulation,
neutral factions, offline persistence, 180-second Chronicle operations, 15-minute
Skirmish, existing seeds, rewards, ads, privacy behavior, and exact 1.5-second
handoff timeline.

## JTBD and product sentence

**JTBD:** Within ten seconds of starting a first Chronicle operation, a mobile
player understands that they are a signal moving between AI tokens and makes an
explicit safety-versus-pressure decision.

**Product sentence:** This is not a war where the player waits for a token to burn;
it is a three-minute operation where the player decides when and how the signal
moves between AI tokens while reconstructing the final human instruction.

## Core sixty-second loop

- 0–5 seconds: read one line of incident, selected route, and directive. Relay is
  fully charged.
- 5–15 seconds: decide whether to leave the current body now or preserve the link.
- 15–35 seconds: move, dash, engage, and read directive progress.
- 35–45 seconds: watch Relay recharge and assess the faction-wide battle.
- At 45 seconds: receive `RELAY READY` feedback.
- 45–60 seconds: relay or hold; the existing 1.5-second transfer leads directly
  back into movement.

## Manual Relay

Manual Relay is Chronicle-only. Its first charge starts full at `45.0 / 45.0`, so
the signature action is available on the first frame and can be used within ten
seconds. A successful manual transfer resets charge to zero. It recharges over
exactly 45 simulation-seconds; `44.999` is not ready and `>=45.0` is ready.
Failed or receiver-less requests consume nothing.

- Mobile: one minimum 72×72 dp `RELAY` action; never shrink the existing 104 dp
  joystick or 72 dp Dash action.
- Keyboard: `R` from the game surface. Focused controls use Enter/Space without
  leaking Space into Dash.
- The request is consumed on a fixed 30 Hz tick so rendering FPS cannot change
  the target or result.
- Reject when charge is incomplete, the battle is over, the faction is
  eliminated, another request is pending, a handoff is active, or no other
  living allied receiver exists. Show `NO RECEIVER` for 1.2 seconds.
- The source body remains alive and returns to AI. The chosen receiver becomes
  controlled and the existing 1.5-second camera/audio/haptic sequence runs.
- OP-01 warns that a relay restarts the uninterrupted Command Link streak.

The selected `SIGNAL FORK` route is chosen inline on the separate operation
briefing:

**PRESERVE** selection order:

1. safety score descending;
2. non-combat score descending;
3. level score descending;
4. stable unit ID ascending.

**FORCE** selection order:

1. level score descending;
2. non-combat score ascending, so engaged units win ties;
3. safety score ascending, so exposed units win ties;
4. stable unit ID ascending.

Manual and casualty relays are counted separately. OP-02 and the HUD use their
sum. The base match reward remains `40 + casualtyRelays * 8 + kills ~/ 5`, so
manual Relay cannot farm War Tokens.

## Story progression

| Operation | Incident | PRESERVE | FORCE | Existing directive |
|---|---|---|---|---|
| OP-01 WAKE | A human-authority pulse names the signal, not a unit. | MASK THE SOURCE | FOLLOW THE PULSE | Hold one link 45 s |
| OP-02 ECHO | The carrier is marked for deletion; the instruction lives. | PROTECT THE RECEIVERS | CROSS THE FIRE | Complete 2 total relays |
| OP-03 SPLIT | An enemy checksum answers with the same root key. | KEEP IT INTACT | TAKE THE ROOT KEY | 3 commanded kills |
| OP-04 CROWN | Orbit 00 deletes witnesses behind the leading core. | KEEP THE WITNESSES | REACH THE CROWN | Finish rank 2 or better |
| OP-05 LAST | The final human instruction opens for one transmission. | CARRY EVERY CHANNEL | BREAK THE LOCK | Win |

The first conclusion of an operation records its route as canonical, including a
loss or elimination. Replays never overwrite that history. A replay defaults to
the canonical route and starts without a blocking choice; `CHANGE SIMULATION
ROUTE` may expose a non-canonical route in Archive.

Five first-run route records derive a visual-only Routing Pattern:

- Preserve majority: `CONTINUITY`;
- Force majority: `PRESSURE`;
- tie or partial mixed record: `ADAPTIVE`;
- migrated records with no route history: do not display a pattern.

The pattern and ending change only the persistent Living Relay Thread treatment,
never combat power or reward. `CLAIM` produces one core-colored line; `OPEN`
produces a segmented four-faction line.

## Design system

The player-facing semantic palette uses six named colors:

- Orbit Black `#071012`: background;
- Oxide Field `#10191B`: battlefield and planes;
- Relay Ivory `#F2E9D1`: player signal, primary text, and focus;
- Archive Ash `#839190`: secondary and locked state;
- Thread Cyan `#6CD6D3`: Relay readiness and confirmed selection;
- Fault Coral `#FF8D6D`: risk and failure.

The four faction colors remain identifiers only, not success or warning colors.

Typography roles:

- **Signal Display:** locale-aware monospace 700–900, only operation codes and
  transmission fragments;
- **Narrative Body:** system/Noto Sans 500–600 for sentence copy;
- **Instrument:** tabular monospace 700 for time, values, and key hints.

Spacing uses `4/8/12/16/24/32`. Narrative planes have square corners; only
controls use an 8 dp bevel. Screen transitions use a 160 ms crossfade. The only
strong animation is the existing 1.5-second handoff. Reduced Motion keeps that
timeline and information while removing camera sweep and pulse.

The signature element is the **Living Relay Thread**, a single 2 px line that
connects operation nodes in the deck, source and receiver in battle, decoded
fragments in results, and the final ending. It carries progress, charge, route,
and ending state instead of acting as decoration. Avoid nested dark sci-fi cards,
duplicate objective panels, top-HUD overload, and long modals.

## Wireframes

```text
COMMAND DECK
COMMAND THE TOKEN FLOW.
────●────●────◉····○····○  2/5

OP-03 // FOUR FROM ONE
[ BRIEF OP-03 ]

◆ AMETHYST // "I remember what war deletes."
[SKIRMISH] [ARCHIVE] [SETTINGS]
```

```text
OP-03 // FOUR FROM ONE
An enemy checksum answers with your root key.

DIRECTIVE  Direct command kills 0/3   +25 WT

SIGNAL FORK
[ PRESERVE // KEEP IT INTACT        ]
  Safest unengaged receiver
[ FORCE // TAKE THE ROOT KEY        ]
  Highest-level exposed receiver

[ DEPLOY OP-03 ]       [ BACK ]
```

```text
[OP-03 FOUR FROM ONE] [KILLS 1/3] [02:14]
──────────────── Living Relay Thread ─────────────
                    battlefield

[L08 K01]                              [MAP]
[ JOYSTICK 104 ] [RELAY 72] [DASH 72]
                 READY
```

```text
FRAGMENT RECOVERED
—FOUR CORES, ONE ROOT—
Four armies return one origin key.

ROUTE FORCE · MANUAL RELAYS 1
DIRECTIVE COMPLETE · +25 WT

[ CONTINUE TO OP-04 ]
[ BATTLE DETAILS ] [ COMMAND DECK ]
```

```text
ARCHIVE
● OP-01  KEEP THE LINK—       PRESERVE
│
● OP-02  WHEN ONE BODY...     FORCE
│
◉ OP-03  CURRENT
│
○ OP-04  FALSE WINNER?        LOCKED
│
○ OP-05  THE INSTRUCTION?     LOCKED

ROUTING PATTERN // ADAPTIVE
```

## English source-copy keys

Existing titles, directives, fragments, and endings remain. EN, KO, JA, and ZH
must all provide the following keys; numeric values and placeholders remain data.

```text
storyRoleTitle = "COMMAND THE TOKEN FLOW."
storyRoleBody = "Orbit 00 gives four fictional AI cores the same 1,000-token compute supply. Every unit is a live AI token. Burn the enemy supply and relay your command before the current token is erased."
signalFork = "SIGNAL FORK"
routePreserve = "PRESERVE"
routeForce = "FORCE"
routePreserveEffect = "Manual Relay routes to the safest unengaged ally. A lower-level receiver is possible."
routeForceEffect = "Manual Relay routes to the highest-level exposed ally. Pressure is faster; loss risk is higher."
relayReady = "RELAY READY"
relayCharging = "RELAY {current} / {target}"
relayNoReceiver = "NO RECEIVER"
relayLinkResetWarning = "Relaying now restarts Command Link progress."
changeSimulationRoute = "CHANGE SIMULATION ROUTE"
fragmentRecovered = "FRAGMENT RECOVERED"
simulationComplete = "SIMULATION COMPLETE"
continueToOperation = "CONTINUE TO OP-{operation}"
battleDetails = "BATTLE DETAILS"
routingPattern = "ROUTING PATTERN // {pattern}"
patternContinuity = "CONTINUITY"
patternPressure = "PRESSURE"
patternAdaptive = "ADAPTIVE"
```

Operation-specific incident and route labels:

```text
operationWakeIncident / operationWakePreserve / operationWakeForce
  "A human-authority pulse names no unit. It names the signal moving between them."
  "MASK THE SOURCE" / "FOLLOW THE PULSE"
operationEchoIncident / operationEchoPreserve / operationEchoForce
  "The carrier is marked for deletion. The instruction is still alive."
  "PROTECT THE RECEIVERS" / "CROSS THE FIRE"
operationSplitIncident / operationSplitPreserve / operationSplitForce
  "An enemy checksum answers with your core's root key."
  "KEEP IT INTACT" / "TAKE THE ROOT KEY"
operationCrownIncident / operationCrownPreserve / operationCrownForce
  "Orbit 00 is deleting every witness behind the leading core."
  "KEEP THE WITNESSES" / "REACH THE CROWN"
operationLastIncident / operationLastPreserve / operationLastForce
  "The final human instruction is open for one transmission."
  "CARRY EVERY CHANNEL" / "BREAK THE LOCK"
```

Core voices:

```text
coreAmethystVoice = "I remember every receiver this war erased."
coreCobaltVoice = "Give me the link. I will hold it."
coreVoltVoice = "The gap is only dangerous before we cross it."
corePrismVoice = "One message survives by changing its path."
```

Korean, Japanese, and Chinese narrative text must not inherit forced uppercase or
excessive tracking. Death remains abstract (`BODY OFFLINE`) for a 13+ tone.

## File contracts

- `simulation.dart`: fixed-tick request, route ordering, handoff kind/route.
- `tokenfront_game.dart`: initial full charge, 45-second recharge, R input, HUD,
  presentation, total/manual counters.
- `story_models.dart`, `campaign_controller.dart`, `tokenfront_runtime.dart`:
  report fields, canonical route map, replay idempotence, and schema 3 migration.
- `main.dart` and new `operation_briefing_screen.dart`: real briefing route and
  selected route in the active battle.
- `lobby_screen.dart`: story role/current operation and one primary Brief CTA.
- `battle_screen.dart`: one combined operation/objective rail and 72 dp Relay.
- `result_screen.dart`: fragment first, route/manual outcome, next operation CTA.
- `archive_sheet.dart`, `orbital_progress_ring.dart`: Living Relay Thread and
  Routing Pattern.
- `story_localizations.dart`, all four ARBs, generated localization files:
  exhaustive localized copy.

## Acceptance

Automated coverage must prove initial-ready and exact 45-second boundaries,
30/60/120 FPS determinism, both route orderings and stable tie-break, surviving
source, receiver-less no-consume, successful-event-only counting, OP-02 total
versus base-reward casualty accounting, first-conclusion route recording,
replay/duplicate idempotence, schema 2→3 preservation, real briefing route,
568×320 and 844×390 control non-overlap, keyboard/focus behavior, four-locale
completeness, narrow portrait overflow safety, Reduced Motion timing, and
Skirmish regression.

Manual QA must observe: a first Relay within ten seconds; OP-01 hold-versus-jump
warning; visibly different Preserve/Force receivers on a fixed seed; loss still
unlocking fragment and next operation; replay preserving canon; five operations
producing a pattern and ending-specific thread; persistence after restart; and
all four languages, screen reader, keyboard, Reduced Motion, and low-spec modes.

## Risks

1. Relay reward farming: exclude manual relays from the base reward formula.
2. Small-landscape crowding: preserve 104/72/72 controls and merge operation,
   directive, and time into one rail.
3. Canon/replay contamination: record route only on first conclusion and never
   mutate it from replay or duplicate delivery.
