# Tokenfront Chronicle recovery battle HUD layout

**Status:** Implementation contract  
**Date:** 2026-09-18  
**Product:** Tokenfront: Orbital Signal War  
**Surface:** Chronicle recovery **battle screen only** (`RecoveryHud` over `GameWidget`)  
**Device of record:** Samsung SM-F741N, forced landscape **2640×1080**, package `com.toris.tokenfront.tokenfront`  
**Evidence:** `qa-artifacts/2026-09-18-p0p2-adb/05-occupancy-8s.png` + `05-occupancy-8s.xml`  
**Owner of this file:** design. A separate engineering worker implements it. Do not treat this document as Dart.

---

## 1. Decision

**Recommended layout: candidate (1) — destination 1/2/3 move into the left and right gutters as vertical rails.**

The full-width top status bar and the full-width bottom destination panel are **removed** on landscape. Their contents relocate into those rails. This is still candidate (1), not a hybrid: the rails already have unused vertical capacity, and leaving a 190 px top bar would keep clipping `WIN LV … OUT` while wasting the axis that is already scarce.

Candidate (2) and candidate (3) are rejected for this device. See §3.

---

## 2. Why the current HUD fails (measured)

Coordinate space below is the **uiautomator dump space** of `05-occupancy-8s.xml`: physical pixels, `rotation="1"`, bounds `[0,0][2640,1080]`. Flutter widget tests that `setSurfaceSize(Size(2640, 1080))` use the same numbers as logical pixels.

### Measured chrome

| Piece | Dump bounds | Size | Share of 1080-tall frame |
|---|---|---|---|
| Pause control | `[2223,45][2595,195]` | 372×150 | top of a ~190 px bar (17.5%) |
| Dest 1 | `[121,855][930,1035]` | 809×180 | bottom row |
| Dest 2 | `[954,855][1762,1035]` | 808×180 | **crosses the hinge** |
| Dest 3 | `[1786,855][2595,1035]` | 809×180 | bottom row |
| Bottom panel (dest row + `recoveryAutomatic`) | y ≈ 770–1080 | ~310 px | **28.8% of height** |

Top bar + bottom panel ≈ **45% of screen area**. Instruction overlay in `03-recovery-deployed.xml` starts at **x = 94**, which is the landscape mapping of cutout `Rect(0,94,0,0)`.

### Arena vs. HUD

`GameWidget` is full-bleed. Recovery world is **1200×800** with nodes at `(300,240)`, `(900,240)`, `(600,600)` and radius **64** (`RecoveryState`). `tokenfront_game.dart` clamps `wideZoom` to **0.65** and eases `followZoom` to **0.92**. At zoom 0.92 the world rasterizes to **1104×736** and is centered:

- Arena rect ≈ `[768, 172][1872, 908]`
- Left black gutter ≈ 768 px, right ≈ 768 px (task measurement 548 / 594 is the **visible grid inside** that letterbox; both describe the same waste)
- Node 3 screen center ≈ `(1320, 724)`, occupancy ring ≈ 59 px radius → circle y **665–783**
- Bottom panel top ≈ y **770** slices that ring. The tower/base sprite reported near `(1010, 545)` in earlier notes is the same lower objective, cut by the panel edge.

`WIN LV 2 > 1 OUT` is a world-space combat flash (`_drawCombatFlashes`, offset `-18/zoom` above the event). At zoom **1.35** (handoff/density clamp max) the world fills the 1080-tall canvas, so the label paints at **negative y** and clips the top edge. Safe-area is applied only to the HUD overlay, not the canvas.

### Structural cause

The camera letterboxes on **width** (surplus). The HUD Column consumes **height** (scarce). Dest 2 also sits on the Z Flip hinge (x ≈ 1320).

---

## 3. Candidate comparison

| | (1) Gutter rails | (2) Shrink bottom panel ~130→80 | (3) Camera clamp |
|---|---|---|---|
| Node 3 fully visible | **Yes** — bottom 310 px goes away | No. An 80 px bar still covers y 665–783 of the ring at zoom 0.92 | Yes, by cropping the world |
| Uses the 700+ px black gutters | **Yes** | No | No |
| Arena scale | Unchanged (zoom 0.92 still shows the full 1200×800) | Unchanged, still occluded | **Smaller** visible world — wrong in a 90 s swarm-read mode |
| Thumb reach on 2640-wide foldable | **Ends of the device, off the hinge** | Dest 2 stays on the crease | Layout unchanged, including dest 2 on the hinge |
| Muscle memory | Positions change. Acceptable: this build has no shipped muscle memory, and the current dest 2 is already a bad target | Keeps bad positions | Keeps bad positions |
| Scope | Recovery HUD Stack + rail placement | Padding tweak | Camera math in `render()` |

**(2) loses** because it does not free the scarce axis far enough for node 3, does not use the gutters, and leaves dest 2 on the hinge.

**(3) loses** because it treats occlusion as a camera problem. The board is already letterboxed; clamping objectives inside the remaining 580 px strip shrinks the swarm the player is supposed to read. It also leaves the 45% HUD tax in place.

**No hybrid with (2) or (3).** Rail button sizes in §5 are part of (1), not a shrink-panel scheme. A camera clamp of nodes is out of scope. The only canvas note in this contract is a **label paint clamp** for combat flashes (§5.6), which is not candidate (3).

---

## 4. Landscape grip and thumb reach (2640×1080 foldable)

SM-F741N inner display in landscape is a **two-hand bar**: 2640 px wide, 1080 px tall, **hinge vertical at x ≈ 1320**. Thumbs rest on the short edges. One-handed play across 2640 px is not a real grip and is not designed for.

| Zone | Dump rect | Role |
|---|---|---|
| Left thumb comfortable | `[0, 480][520, 1080]` | Left-hand index/thumb |
| Right thumb comfortable | `[2120, 480][2640, 1080]` | Right-hand index/thumb |
| Hinge avoid | `[1180, 0][1460, 1080]` | Crease; no tap targets |
| Top stretch | y `< 200` | Pause only, never dest |

**Placement (spatial map of the three nodes):**

| Control | Rail | Slot | Why |
|---|---|---|---|
| Dest **1** (world left-upper `(300,240)`) | **Left** | Lowest slot | Onboarding first tap; left thumb |
| Dest **2** (world right-upper `(900,240)`) | **Right** | Above dest 3 | Right node; right thumb |
| Dest **3** (world bottom-center `(600,600)`) | **Right** | Lowest slot | The node that was hidden; easiest right-thumb reach |
| Progress + remaining seconds + `recoveryAutomatic` | **Left** | Top of rail | Readout, not a verb |
| Pause (`battle-pause`) | **Right** | Top of rail, y `< 200` | Must not sit next to dest 3 |

Do not mirror dest 3 onto both rails. Keys `recovery-destination-0/1/2` must remain unique.

---

## 5. Layout contract (implement these numbers)

Breakpoint: **landscape rails** when `maxWidth >= maxHeight` **and** `maxWidth >= 720` (`TokenfrontBreakpoints.compact`). The SM-F741N battle screen is forced landscape and always takes this branch.

Narrow / portrait fallback is §8. It exists so `test/recovery_ui_test.dart` sizes `375×667` and `768×375` keep working. It is **not** candidate (2) and it **does not run** on the device of record.

### 5.1 Safe area / cutout

Apply padding to the HUD overlay (keep `GameWidget` full-bleed):

```
pad.left   = max(MediaQuery.padding.left,   viewPadding.left,   8)
pad.right  = max(MediaQuery.padding.right,  viewPadding.right,  8)
pad.top    = max(MediaQuery.padding.top,    viewPadding.top,    8)
pad.bottom = max(MediaQuery.padding.bottom, viewPadding.bottom, 8)
```

On SM-F741N landscape dump this **must** yield `pad.left >= 94` (cutout). Other edges may be 8 if the inset is 0. No HUD child, including pause and dest controls, may draw outside the padded rect. Do not ignore `viewPadding` on this foldable.

### 5.2 Rail geometry (logical px; dump px at `Size(2640, 1080)`)

```
railWidth = clamp(168, 0.11 * maxWidth, 280)
            → 280 at 2640 wide
            → 168 at 1280 wide and at 768×375
railInner = railWidth - 16          // TokenfrontSpacing.sm on both sides
destGap   = shortHeight ? 4 : 8     // shortHeight := maxHeight < 560
```

| Rail | x0 | x1 | y0 | y1 |
|---|---|---|---|---|
| Left | `pad.left` | `pad.left + railWidth` | `pad.top` | `height - pad.bottom` |
| Right | `width - pad.right - railWidth` | `width - pad.right` | `pad.top` | `height - pad.bottom` |

**ADB bounds at 2640×1080 with pad.left = 94, pad.right = 8, pad.top = 8, pad.bottom = 8:**

| Rail | Must satisfy |
|---|---|
| Left panel | `x1 >= 94`, `x2 <= 94+280+8 = 382`, `y1 >= 8`, `y2 <= 1072` |
| Right panel | `x1 >= 2640-8-280 = 2352`, `x2 <= 2632`, `y1 >= 8`, `y2 <= 1072` |

Rails use `TacticalPanel` (`deepField` fill, `panelBorder`). They must **not** span the full width. No widget with width `> 0.40 * screenWidth` may occupy y `> 0.70 * screenHeight` (that is the old bottom bar).

### 5.3 Destination controls

Keep `TacticalButton`, keys, colors, and two-line visible label:

- Key: `recovery-destination-$index` (`0`,`1`,`2`)
- Visible label: `'$n\n${seconds.floor()}/${requiredSeconds.floor()}'` (already `/8`)
- `semanticLabel`: `copy.recoveryDestination(n, seconds.floor())` — **do not drop**
- `Semantics(selected: recovery.selected == index)` — **do not drop**
- Color: recovered `volt` + `onPressed == null`; selected `threadCyan`; idle `relayIvory`
- `onPressed` still calls `game.selectDestination(index)` then `setState`

**Size**

| | Minimum | At 2640×1080 | Short landscape (`maxHeight < 560`) |
|---|---|---|---|
| Width | `max(TokenfrontSizes.buttonWidth, railInner)` = **152** | 264 | 152 |
| Height | **72** (two-line instrument + `buttonVertical` padding) | **88** (`max(72, 0.08 * height)`) | **56** (still `>= 50`) |

Thumb-slot vertical placement (bottom-up, dump space 2640×1080):

| Control | x band | y band (inclusive) | Center must lie in |
|---|---|---|---|
| Dest 1 | left rail inner | `[900, 1072]` | left thumb zone |
| Dest 3 | right rail inner | `[900, 1072]` | right thumb zone |
| Dest 2 | right rail inner | `[780, 900)` , 8 px above dest 3 | right thumb zone |

All three dest **centers** must sit in y `[480, 1080]`. None may intersect the hinge avoid band `[1180, 1460]`.

### 5.4 Status and pause

**Left rail, top (not a thumb slot):**

1. `recoveryProgress(recoveredCount) · ${remaining.ceil()}s` — `TokenfrontType.instrument`, `maxLines: 2`, `overflow: TextOverflow.ellipsis`.
2. 8 px gap.
3. `recoveryAutomatic` — `TokenfrontType.body`, `fontSize` 11, `maxLines: 2`, `overflow: TextOverflow.ellipsis`. Korean `자동 이동 · 자동 전투 · 자동 이어받기` and Japanese `自動移動 · 自動戦闘 · 自動引き継ぎ` **must** wrap inside `railInner` without a `RenderFlex` overflow.

**Right rail, top:** existing pause `TacticalButton` key `battle-pause`. Top edge `>= pad.top`. Do not enlarge it. It must not overlap dest 2 (`pause.bottom + 8 <= dest2.top`).

There is **no** full-width top `TacticalPanel`. That is what currently occupies y `0–195` and hides combat flashes.

### 5.5 Arena viewport (HUD-free rect)

GameWidget stays full-bleed; do **not** change `wideZoom` / `followZoom` / camera follow / world size / node positions.

Unobstructed HUD-free rectangle at 2640×1080 after this layout:

```
viewport = Rect.fromLTRB(
  pad.left + railWidth,   // 94+280 = 374
  pad.top,                // 8
  width - pad.right - railWidth,  // 2352
  height - pad.bottom,    // 1072
)
= [374, 8][2352, 1072]   // 1978 × 1064
```

At zoom 0.92 the world is `[768,172][1872,908]` — **entirely inside** this viewport. Node 3 ring bottom ≈ 783 has **289 px** of clearance above y 1072.

**Hard rule:** every destination circle (`center ± 64` world, converted through the current zoom) must be at least **16 px** inside `viewport`. If an engineer observes a violation at default zoom 0.92, they have implemented the rails too wide — they must not “fix” it with a camera clamp.

### 5.6 Combat flash label (secondary defect)

In `_drawCombatFlashes`, after computing the `TextPainter` offset `center + Offset(-width/2, -18/zoom)`, clamp the **canvas-space** top of that label to `>= 8` px (and `>= MediaQuery`/`viewPadding.top` if the game widget is later inset). Do **not** change camera center, zoom, or node positions to achieve this.

This is a paint clamp of floating HUD-adjacent type, not candidate (3).

### 5.7 Instruction / pause overlay

Replace the current `Column(topBar, Expanded(overlay), bottomBar)` with a `Stack`:

- Full-size `GameWidget` (already in `BattleScreen`; HUD does not own it)
- Left rail `Positioned`
- Right rail `Positioned`
- Center overlay only while `awaitingRecoveryInstruction || paused`

Overlay rules (unchanged behavior, new geometry):

- Centered in `viewport` (between the rails), max width `viewport.width - 24`
- `SingleChildScrollView` kept for large text
- Dest buttons stay **visible and hit-testable** while the overlay is up (first-session success is still “tap 1”)
- Dest tap **and** `recoveryChooseDestination` still dismiss
- Overlay must not cover any dest control: `overlay.bottom <= destN.top - 8` is **not** required if the overlay is centered and rails are on the sides; instead assert dest hit targets are outside the overlay’s rect

### 5.8 Game-feel / feedback — **do not change**

Destination tap remains the only verb.

| Channel | Keep |
|---|---|
| Haptic | `HapticFeedback.lightImpact()` inside `selectDestination()` |
| Audio | `GameAudioCue.commandRelay` |
| Arena lock | selected node stroke **4 px**, fill alpha **0.35**, `threadCyan` |
| Recovered | `volt`, button disabled, occupancy retained |
| Midway 5 s | existing `advanceMidwayCues()` light haptic + `commandRelay` (unchanged, still shared channels) |
| Node complete | existing `recoveryComplete` cue |
| Shake | none |
| Sim timescale | dest change must not touch `simulationScaleAt` |

Do **not** add a second haptic to “teach” the new rail positions. It would collide with the 5 s midway cue, which already uses the same pair.

---

## 6. Invariants (must not change)

- Recovery stays **destination-selection**. No joystick, dash, or direct unit control on this screen.
- `RecoveryState.requiredSeconds = 8.0`, `midwaySeconds = 5.0`, `radius = 64.0`, `matchLimitSeconds = 90`, world **1200×800**, destinations **unchanged**.
- Locales **en, ko, ja, zh** via existing ARB + `flutter gen-l10n`. Longest visible occupancy string in practice is Korean semantics `신호 1: 0/8초`; visible button face stays `1\n0/8`.
- Semantics labels on dest controls stay; `test/recovery_ui_test.dart` taps `Key('recovery-destination-1')`.
- `lib/ui/lobby_screen.dart` and `lib/ui/result_screen.dart` are **out of scope** (sticky deploy bar and result action row already device-verified this session).
- No new third-party dependencies.
- Tokens only: `TokenfrontColors` / `TokenfrontSpacing` / `TokenfrontType` / `TacticalPanel` / `TacticalButton`.
- Color is never the only selected-state cue (number + selected semantics).

---

## 7. Observable acceptance

Engineer turns each row into a widget test at `Size(2640, 1080)` **and/or** an ADB dump assertion on SM-F741N after Chronicle deploy, overlay dismissed, dest 3 selected. Bounds are dump/test-surface pixels.

### A. Chrome gone

| ID | Check | Pass if |
|---|---|---|
| A1 | No full-width bottom dest row | No dest control has `width >= 700` **and** `top >= 800` |
| A2 | No full-width top bar | No HUD panel with `width >= 2000` and `height >= 140` whose `top <= 20` |
| A3 | Rails exist | Left dest (index 0) `right <= 400`; dest 1 and dest 2 `left >= 2200` |

### B. Numbers / hit targets

| ID | Check | Pass if |
|---|---|---|
| B1 | Min dest size | Each dest: `width >= 152`, `height >= 72` (56 if `height < 560`) |
| B2 | Tokenfront min | Each dest and pause: `width >= 124`, `height >= 50` (`TokenfrontSizes.buttonSize`) |
| B3 | Safe left cutout | Every HUD child’s `left >= 94` on this device dump |
| B4 | Safe top / bottom | Every HUD child’s `top >= 8` and `bottom <= 1072` |
| B5 | Dest 1 thumb | Dest 0 center inside `[0,480][520,1080]` |
| B6 | Dest 2/3 thumb | Dest 1 and dest 2 centers inside `[2120,480][2640,1080]` |
| B7 | Hinge clear | Intersection of any dest rect with `[1180,0][1460,1080]` is **empty** |
| B8 | Pause vs dest | `pause.bottom + 8 <= dest-2.top`; pause `top >= 8` |

### C. Arena / objectives

| ID | Check | Pass if |
|---|---|---|
| C1 | Viewport | HUD-free rect width `>= 1900` and height `>= 1000` at 2640×1080 |
| C2 | Node 3 visible | Screenshot: numbered node **3** occupancy ring fully visible, **≥ 16 px** from the nearest opaque HUD edge (compare to `05-occupancy-8s.png` where it is sliced) |
| C3 | Nodes 1 and 2 | Screenshot: nodes **1** and **2** fully visible, same 16 px clearance |
| C4 | Combat label | `WIN LV … OUT` fully visible; label top `>= 8` px from the screen top (no clip against y = 0) |

### D. Behavior (must still pass existing tests)

| ID | Check | Pass if |
|---|---|---|
| D1 | Select | Tap `recovery-destination-1` sets `recovery.selected == 1` and fires the existing `selectDestination()` path |
| D2 | Overlay | Instruction copy gone after dest tap; `recoveryChooseDestination` still dismisses |
| D3 | Semantics | Each dest exposes `recoveryDestination` (ko: `신호 N: X/8초`) |
| D4 | Recovered | When `seconds[i] >= 8`, that button `onPressed == null`, color volt |
| D5 | Locales | `en/ko/ja/zh` at 2640×1080, 1280×720, 768×375, 375×667: `tester.takeException() == null`, no RenderFlex overflow on progress, auto line, or dest face |
| D6 | Feedback | No new haptic/audio calls on dest tap; `lightImpact` + `commandRelay` remain the only select pair |
| D7 | Occupancy | No change to 8 s / 5 s / 90 s / radius 64 (existing `recovery_test.dart` still green) |

### E. Out of scope regressions

| ID | Check | Pass if |
|---|---|---|
| E1 | Lobby | `chronicle-deploy` / `skirmish-deploy` still outside the lobby `ScrollView` |
| E2 | Result | Result action row unchanged |
| E3 | Skirmish HUD | Joystick / dash / minimap layout untouched (`BattleScreen` non-recovery branch) |

---

## 8. Narrow / portrait fallback (not the P0 fix)

When `maxWidth < maxHeight` **or** `maxWidth < 720`:

- Keep a **bottom dest row** of three equal `Expanded` `TacticalButton`s (current structure).
- Cap that panel: padding `TokenfrontSpacing.xs`, dest height **50–56**, optional auto line `maxLines: 1` ellipsis. Total bottom chrome **≤ 96** logical px.
- Top: keep a single compact progress+pause row, height **≤ 64**.
- This branch is for widget tests at `375×667` and any accidental portrait HUD pump. `BattleScreen.requireLandscape` already blocks portrait play on device.

Do not use this fallback on SM-F741N landscape.

---

## 9. Implementation notes for the engineering worker

Touch, in this order:

1. `lib/ui/recovery_hud.dart` — replace the `Column` with a landscape `Stack` of two rails; keep the fallback `Column` behind the breakpoint.
2. `lib/ui/battle_screen.dart` — only if `SafeArea` around `RecoveryHud` needs `minimum` raised to 8 on all edges. Do not wrap `GameWidget`.
3. `lib/game/tokenfront_game.dart` — only the combat-flash label clamp in `_drawCombatFlashes` (§5.6).

Add assertions to `test/recovery_ui_test.dart` (2640×1080 landscape + existing locale×size loop). Do not retune recovery sim tests.

Suggested widget-test skeleton (normative):

```dart
await tester.binding.setSurfaceSize(const Size(2640, 1080));
// pump RecoveryHud as today
final dest0 = tester.getRect(find.byKey(const Key('recovery-destination-0')));
final dest1 = tester.getRect(find.byKey(const Key('recovery-destination-1')));
final dest2 = tester.getRect(find.byKey(const Key('recovery-destination-2')));
expect(dest0.right, lessThanOrEqualTo(400));
expect(dest1.left, greaterThanOrEqualTo(2200));
expect(dest2.left, greaterThanOrEqualTo(2200));
expect(dest0.width, greaterThanOrEqualTo(152));
expect(dest0.height, greaterThanOrEqualTo(72));
expect(dest0.center.dy, greaterThanOrEqualTo(480));
expect(
  dest1.overlaps(const Rect.fromLTRB(1180, 0, 1460, 1080)),
  isFalse,
);
```

ADB after install on the device of record: landscape Chronicle, tap dest 1, dump `qa-artifacts/2026-09-18-p0p2-adb/12-rails.png` + `.xml`. Pass A1–A3, B3–B7, C2–C4 against that dump/screenshot.

---

## 10. ASCII target (2640×1080, pad.left = 94)

```
x=0                                                         x=2640
┌─ cutout 94 ───────────────────────────────────────────────┐
│ pad.top 8                                                 │
│ ┌ left 280 ┐                       ┌ right 280 ┐          │
│ │ 2/3 · 54s│                       │   PAUSE   │          │
│ │ auto ko  │                       │           │          │
│ │ wrapped  │     arena 1978×1064   └───────────┘          │
│ │          │     nodes 1 and 2                            │
│ │          │     node 3 fully visible                     │
│ │          │                       ┌───────────┐          │
│ │          │                       │ 2   8/8   │          │
│ ├──────────┤                       ├───────────┤          │
│ │ 1  8/8   │                       │ 3   4/8   │          │
│ └──────────┘                       └───────────┘          │
│                                              pad.bottom 8 │
└───────────────────────────────────────────────────────────┘
         hinge x≈1320 has no controls
```

---

## 11. What this document is not

- Not a retune of occupancy, radius, unit count, or match length.
- Not a Skirmish HUD redesign.
- Not a lobby or result-screen change.
- Not a request for joystick, occupancy arcs, or a new 5 s visual pulse (still an open P2 from the playtest, out of this layout pass).
