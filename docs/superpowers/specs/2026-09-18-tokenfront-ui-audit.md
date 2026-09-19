# Tokenfront Recovery HUD / UI Audit

**Date:** 2026-09-18  
**Agent lens:** design-ui-designer + design-ux-architect + design-whimsy-injector  
**Device:** SM-F741N, 1080×2640 portrait / 2640×1080 landscape recovery

## Verdict

**Recovery HUD contract is met on device.** Three equal destination buttons, localized overlay CTA, semantic labels, and auto-relay status rail all present. Primary UX debt is **lobby scroll-to-deploy** on tall portrait screens, not recovery itself.

## Surface audit

### 1. Command Deck (lobby)

| Element | ADB evidence | Status |
|---|---|---|
| Mode rail (Chronicle / Skirmish) | `크로니클`, `스커미시` buttons visible | Pass |
| Faction core picker | 4 cores with `AI 코어 선택` semantics | Pass |
| Deploy CTA | `신호 세 개 회수하기` at bounds `[48,2515][1032,2640]` | Pass but **below fold** |
| Status copy | `자동 이동 · 자동 전투 · 자동 이어받기` | Pass |
| WT locker / settings | `보관소 0 WT`, `조정` | Pass |

**Issue P0:** Deploy CTA requires scroll on 1080×2640. User may not see Chronicle entry without swiping. Recommend sticky bottom deploy bar or auto-scroll when OP-01 briefing is in view.

### 2. Recovery HUD (in-match)

| Contract item | Evidence (`03-ui.xml`) | Status |
|---|---|---|
| Top status rail | `신호 0/3개 회수 · 90s` + auto-relay line | Pass |
| Instruction overlay | Localized body + `목적지 선택` CTA | Pass |
| Bottom destinations | `1\n0/10`, `2\n0/10`, `3\n0/10` equal-width row | Pass |
| Semantic labels | `신호 N: X/10초` per button | Pass |
| Pause | `일시정지` top-right | Pass |
| Touch targets | Buttons ~809×180 px (landscape) | Pass (>> 124×50 min) |

### 3. Post-interaction (`05-ui.xml`)

| Check | Result |
|---|---|
| Overlay dismissed after dest tap | `OVERLAY_GONE True` |
| Progress retained | `신호 1: 10/10초` while dest 2 active |
| Selected semantics | Dest 2 shows `2\n0/10` as active target |
| Timer pressure | `신호 1/3개 회수 · 72s` |

## Visual token compliance

- Uses `TacticalPanel`, `TacticalButton`, `TokenfrontType.instrument/body` — no ad-hoc fonts in recovery HUD.
- Selected = threadCyan (code), recovered = volt + disabled (widget test + render).
- Color is not sole cue: number + `seconds/10` label on each button.

## Accessibility

| Criterion | Status |
|---|---|
| Semantic destination labels | Pass (`recoveryDestination`) |
| Touch target size | Pass on device |
| Large text / scroll | Instruction panel in overlay scrolls (widget tests) |
| Color-only selected state | Pass — number + selected semantics |
| Reduce motion | Existing settings; no new shake on dest tap |

## Whimsy (restrained)

Per whimsy-injector: recovery is a **professional command console**, not a party game.

- Appropriate: `commandRelay` audio, light haptic, cyan lock ring on arena node.
- Avoid: screen shake on tap, celebration particles before node complete, playful error copy during 90s timer.

**Optional P2:** Subtle 5s occupancy tick pulse (volt shimmer) — only if playtests show players lose track of active node.

## Responsive notes

| Form factor | Observation |
|---|---|
| Portrait lobby 1080×2640 | Scroll required for deploy; archive rail visible above fold |
| Landscape recovery 2640×1080 | HUD fits; destinations + overlay readable |
| Integration test | Uses landscape 1920×1080 screenshots — matches recovery layout |

## Recommended UI changes (ranked)

1. **P0** Sticky deploy CTA or scroll-into-view on `chronicle-deploy` when faction selected.
2. **P1** Highlight selected destination with border weight in addition to color (already partially via TacticalButton).
3. **P2** Show mini occupancy arc on arena node matching bottom button seconds.
4. **P3** First-session tooltip arrow pointing at destination `1` (dismisses on any tap).

## Screenshots

| File | Contents |
|---|---|
| `qa-artifacts/2026-09-18-adb/01-launch.png` | Lobby portrait |
| `qa-artifacts/2026-09-18-adb/03-recovery-deployed.png` | Recovery with overlay |
| `qa-artifacts/2026-09-18-adb/04-destination-1-selected.png` | After dest 1 tap |
| `qa-artifacts/2026-09-18-adb/05-destination-2-selected.png` | Dest 2 selected, node 1 complete |
