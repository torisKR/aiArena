# Tokenfront Fun / Systems Audit

**Date:** 2026-09-18  
**Agent lens:** GameDesigner + game-feel  
**Device evidence:** `qa-artifacts/2026-09-18-adb/` on SM-F741N

## Verdict

**Chronicle recovery loop is mechanically sound and now reads as "command rerouting," not passive waiting.** Destination taps dismiss onboarding, produce haptic + audio feedback, and occupancy progress persists across relay handoffs. Remaining fun risk is **pacing** (10s × 3 nodes in 90s) and **first-session clarity** on foldable portrait lobby scroll.

## What works (playtest pass)

| Signal | Evidence |
|---|---|
| Core verb visible within 1 deploy | Lobby CTA `신호 세 개 회수하기` → recovery HUD with destinations 1/2/3 |
| Destination tap dismisses overlay | Tap dest 1 removed `목적지 선택` overlay (`OVERLAY_GONE True` in `05-ui.xml`) |
| Localized CTA | Overlay button semantic label `목적지 선택` (ko), not hardcoded English |
| Progress persists | After tap dest 1 then 2: `신호 1: 10/10초` retained while dest 2 selected |
| Auto relay fantasy intact | Status rail: `자동 이동 · 자동 전투 · 자동 이어받기` |
| Feedback stack on select | Code: `HapticFeedback.lightImpact()` + `GameAudioCue.commandRelay` in `selectDestination()` |
| Arena read on select | Selected node stroke widens to 4px + 0.35 alpha fill (`tokenfront_game.dart`) |

## Broken / risky states (prior → status)

| GDD fail state | Before | Now |
|---|---|---|
| No haptic on destination tap | Missing | Fixed |
| Hardcoded English dismiss CTA | `CHOOSE DESTINATION` | Fixed → `recoveryChooseDestination` ARB |
| Overlay blocks arena after first tap | Partial | Fixed — tap destination OR CTA dismisses |
| Selected node unreadable | Thin stroke | Improved — thicker cyan lock ring |
| English on Korean device | Yes | Fixed in HUD copy |

## Fun hypothesis check

> Tapping 1/2/3 should feel like rerouting a live command signal.

**Pass (ADB):** UI shows immediate selection (`2\n0/10` active), overlay gone, node 1 completed to 10/10 while switching to node 2. Timer pressure visible (`신호 1/3개 회수 · 72s`).

**Still [PLACEHOLDER]:** 10s occupancy per node — if playtests feel slow, tune to 8s before touching radius or unit count.

## Systems map (recovery-only)

```
Player tap 1/2/3
  → RecoveryState.select(index)
  → acknowledgeRecoveryInstruction()
  → haptic + commandRelay cue
  → auto-move linked token to node radius 64
  → occupancy +dt while inside
  → node complete → volt + auto-advance
  → casualty → 1.5s handoff, progress kept
```

## Recommended next tuning (priority)

1. **P0 — Lobby deploy discoverability (portrait 1080×2640):** Primary CTA sits at y≈2575; requires scroll. Add sticky deploy bar or auto-scroll to `chronicle-deploy` on OP select.
2. **P1 — Occupancy midpoint juice:** At 5s on active node, optional subtle pulse (game-feel tier: small) — audio stub only today.
3. **P1 — Skirmish vs Chronicle contrast:** Lobby already splits mode rail; reinforce in first Chronicle tooltip that stick/dash are Skirmish-only.
4. **P2 — Result hook:** Guarantee first recovered node triggers volt + `recoveryComplete` cue before match ends (already in sim; verify on full 90s run).

## Observable metrics for next session

- Time-to-first-destination-tap from cold launch (target < 15s without scroll confusion)
- % sessions completing ≥1 node in first attempt
- Destination switches per minute (should be > 2 when learning; < 0.5 when idle = fail)

## Out of scope (unchanged)

Joystick in Chronicle, faction-exclusive powers, new relay physics, IAP.
