# Tokenfront Fun / Systems / UI-UX GDD

**Status:** Active playtest direction  
**Date:** 2026-09-18  
**Product:** Tokenfront: Orbital Signal War  
**Scope:** Keep recovery as destination-selection, not movement execution. Do not add joystick/dash to Chronicle. Do not invent faction-exclusive powers.

## Design pillars

1. **Command, not piloting.** The player is a core intelligence choosing *where* the signal goes. Movement, combat, and casualty relay stay automatic.
2. **Readable swarm.** 4 cores, live token supply, and three numbered signal nodes must be readable at a glance on a 1080×2640 foldable.
3. **Consequence without chores.** Switching destinations is the only verb. Recovered progress never resets on death.
4. **Tactical console, not chrome.** Beveled panels, instrument type, orbital palette. Extra sci-fi decoration is debt.

## Fun hypothesis

The game works if tapping 1/2/3 feels like rerouting a live command signal: immediate visual lock on the node, a short haptic, a cyan destination, and a filling 0–8s occupancy clock. If destination change does not read as an event, the loop is a timer, not a war.

Broken states (playtest fail):

- Player cannot tell which node is selected without reading the button color.
- Instruction overlay blocks the arena after the first destination tap.
- Destination tap produces no haptic / no arena pulse.
- Hardcoded English CTA (`CHOOSE DESTINATION`) on a Korean device.
- Recovered node still looks tappable.

## Core loops

### Moment-to-moment (0–30s)

- **Action:** Tap destination 1, 2, or 3.
- **Feedback:** Button turns threadCyan; arena node stroke/fill matches; light haptic; occupancy clock ticks while the linked token is inside radius 64.
- **Reward:** Seconds banked on that node (0–10). Completing a node flips it to volt and auto-selects the next incomplete node.

### Session loop (≤90s Chronicle recovery)

- **Goal:** Occupy all three nodes for 8s each before 90s or allied wipe.
- **Tension:** The swarm is live. Changing destination abandons occupancy on the previous node until you return; recovered nodes stay recovered.
- **Resolution:** recovered / timeout / alliesLost. Reward floor 40 WT, +20 WT per recovered signal when succeeded.

### Long-term loop

- Chronicle operations → medals → ending choice.
- Skirmish remains the 4,000-token joystick/dash fantasy.
- War Tokens buy cosmetics only. Never combat power.

## Systems map

| System | Player verb | Output | Fail |
|---|---|---|---|
| Recovery destinations | Tap 1/2/3 | Selected index, auto-move | Recovered/invalid ignored |
| Occupancy clock | Stay in radius | +dt to selected seconds | Leaves radius → clock pauses |
| Casualty relay | None (auto) | New linked token, progress kept | Allies lost ends match |
| Handoff juice | None | 1.5s camera/time-scale sequence | Must not block destination input after settle |
| Skirmish stick/dash | Stick + dash | Direct token control | Disabled in recovery |
| WT / locker | After match | Cosmetics | No power |

## Economy (recovery)

| Variable | Base | Notes |
|---|---|---|
| Match limit | 90s | RecoveryState.config |
| Occupancy | 8s / node | Tuned down from 10s after 2026-09-18 playtest (P1) |
| Units / faction | 100 | Recovery scale, not 1000 |
| World | 1200×800 | Three nodes at (300,240) (900,240) (600,600) |
| Radius | 64 | Must remain larger than unitRadius 8 |
| Reward | max(40, recoveredCount×20) | Success only |

## UI / UX architecture

### Surfaces

1. **Lobby / Command Deck** — mode rail (Chronicle vs Skirmish), four cores, deploy CTA, WT locker, settings.
2. **Recovery HUD** — top status rail, dismissible instruction panel, bottom three destination buttons.
3. **Skirmish HUD** — command rail, pause, view rail, joystick, dash, minimap.
4. **Result** — outcome, WT, optional rewarded double, rematch/lobby.

### Recovery HUD contract

- Top: `recoveryProgress` + remaining seconds + pause.
- Center overlay: only while `awaitingRecoveryInstruction` or paused. Destination tap **and** localized continue CTA both dismiss it.
- Bottom: equal-width destination buttons labeled with localized signal number **and** `seconds/10`. Color is secondary to the number.
- Selected = threadCyan. Recovered = volt + disabled. Idle = relayIvory.
- Continue CTA uses `recoveryChooseDestination` (localized). Never hardcode English.

### Accessibility

- Semantic labels: `recoveryDestination(number, seconds)`.
- Touch targets ≥ `TokenfrontSizes.buttonSize` (124×50).
- Large text: instruction panel scrolls.
- Reduce-motion / low-spec remain existing settings.
- Color is never the only selected-state cue (number + selected semantics).

### Visual tokens

Use `TokenfrontColors` / `TokenfrontSpacing` / `TokenfrontType` only. Deep field arena, relayIvory text, threadCyan selected, volt recovered, danger fail.

## Game-feel tiers (recovery)

| Event | Tier | Channels |
|---|---|---|
| Destination select | small | haptic light, cyan lock, node stroke |
| Occupancy tick at 5s | small | optional audio later |
| Node recovered | medium | volt fill, haptic medium, recoveryComplete cue (existing) |
| Casualty relay | medium | existing 1.5s handoff |
| Match win | large | result copy + WT |

Do not add screen-shake on destination taps. Do not slow simulation on destination change.

## Onboarding

- Core verb (destination tap) visible within 1s of deploy.
- First overlay may be dismissed by tapping a destination — guaranteed first success is “select node 1”, not occupying 8s.
- First session hook: first recovered node flips volt while the other two remain open.

## Out of scope this pass

Joystick in Chronicle, new faction abilities, capture-the-relay physics, IAP, account sync, decorative motion beyond destination lock.

## Observable acceptance

- Widget tests: destination tap dismisses instructions; localized continue CTA exists in en/ko/ja/zh.
- ADB on SM_F741N: install `com.toris.tokenfront.tokenfront`, launch lobby, deploy Chronicle, tap destination 1 then 2, capture screenshots proving selected node + overlay gone.
