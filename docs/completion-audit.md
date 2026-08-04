# Tokenfront: Orbital Signal War — completion audit

- Audit date: 2026-08-05 (KST)
- Requirement source: `pasted-text-1.txt` supplied with the build request
- Repository root: `/Users/toris/projects/aiArena`
- Audited product: Flutter + Flame offline single-player MVP

**Task 12 status: INTERIM FEATURE PREVIEW — PRIVACY REDEPLOY REQUIRED.** The
current release Web artifact is built and its 46-line pre-deploy digest is
recorded at `.omo/evidence/task-12/tokenfront-orbital-war-build.sha256`; the
digest file SHA-256 is
`b575725e9a9fe9a80d82a8b5abc99cb7e8ae6c49568ee095b2d957ad03f9c4f7`. Forty-six
files were uploaded to the retained `tokenfront-orbital-war` Pages project as
production deployment `e74f7d12-c7c5-40c0-9d87-83240b57de5c` at
`2026-08-04T20:53:49.386Z` (`2026-08-05T05:53:49.386+09:00`); the canonical
preview URL is <https://tokenfront-orbital-war.pages.dev/>. This is a dirty
working-tree feature preview whose Cloudflare source metadata still names base
commit `f246035`, not commit-bound final release evidence. Task 7 must rebuild
and redeploy after the in-app privacy surface exists and prove Web/AAB source
parity.

This is an evidence audit, not a store-release declaration. “Verified” means the current workspace contains the implementation plus a relevant passing automated test, successful build/runtime command, or a recorded hands-on target-platform check. Browser visual QA is identified as hands-on rather than automated.

## Executive status

The gameplay MVP and requested performance architecture are implemented and automated-test verified. The current build has a deterministic 4,000-unit battle (1,000 per faction), fixed 30Hz simulation, 10–15Hz tactical AI, approximately 5Hz far-idle AI, faction-partitioned spatial queries, a fixed unit pool, conservative render culling, an expanded camera with a right-side tactical minimap, sub-600dp Android/iOS/Web landscape requests and portrait gating, Blender-authored runtime atlas rendering, the complete handoff experience, responsive input/UI, offline-safe monetization boundaries, and privacy-gated analytics buffering. Current 4,000-unit physical-device performance acceptance remains open.

Historical 2026-07-16 web evidence for the retired
`tokenfront-ai-arena` Pages project includes:

- a successful `flutter build web --release` using the current 4,000-unit code;
- the former Cloudflare Pages deployment at [tokenfront-ai-arena.pages.dev](https://tokenfront-ai-arena.pages.dev), which returned HTTP 200 and matched that historical local release's `index.html` and `main.dart.js` SHA-256 hashes; this is not the current product project or release evidence;
- current-build Brave checks at 844×390 confirming the four 1,000-unit lobby entries, 4,000-unit total, battle HUD, right-side tactical minimap, controls, and zero browser-console errors or warnings;
- a local fresh-match seconds 3–8 `requestAnimationFrame` diagnostic of 58.197 average FPS, approximately 29.499 FPS 1% low, 34ms maximum frame time, and 58 frames above 25ms. This short headless desktop-browser diagnostic is not physical-device or endurance acceptance.

Preserved 2026-07-15 platform evidence includes:

- a prior-build physical Android integration smoke on **SM A175N**, device `RFKYB09D9TL`, Android 16;
- a preserved 2026-07-15 30-second dense-battle profile-mode sample on the same SM A175N: the former 400-unit build recorded 2,599 frame samples, 88.38 average FPS, 45 FPS 1% low, and 958 cumulative simulation ticks including warmup; the raw historical result is retained in `docs/performance-profile-sm-a175n-2026-07-15.json` and does not verify the current 4,000-unit build;
- a prior-build iOS integration smoke on **iPhone 17 Pro Max Simulator**, iOS 26.5;
- prior-build hands-on local **Safari and Chrome** checks on macOS covering rendering, input, aspect/layout, and pause/resume; Chrome reported zero app errors;
- successful default CanvasKit web and optional WebAssembly/Skwasm builds.

The remaining work is launch integration and acceptance work, not missing core gameplay. The exact open items are listed at the end of this document.

## Current quality-gate evidence

| Evidence | Current result | Classification |
|---|---|---|
| `flutter analyze` | Exit 0: `No issues found!` | **Verified** |
| `flutter test` | Exit 0 on 2026-08-05: **190 VM tests passed; 1 Web-only test skipped** | **Verified checkpoint; Web-only test remains a separate browser invocation** |
| Current Brave release QA | 844×390 local release and Cloudflare production checks confirm 4×1,000 lobby data, battle HUD, tactical minimap, controls, and 0 console errors/warnings | **Verified current hands-on browser QA** |
| Historical Cloudflare Pages deployment | The retired [tokenfront-ai-arena.pages.dev](https://tokenfront-ai-arena.pages.dev) project matched its 2026-07-16 build; it is not the current product project or final release | **Historical evidence only** |
| Android integration test | `integration_test/app_smoke_test.dart` passed on physical SM A175N / Android 16 on 2026-07-15 | **Historical prior-build platform evidence** |
| Android profile-mode performance | Historical SM A175N / Android 16 result for the former 400-unit build: 30-second dense sample, 2,599 frame samples, 88.38 average FPS, 45 FPS 1% low; retained in `docs/performance-profile-sm-a175n-2026-07-15.json` | **Historical baseline; current 4,000-unit device profile pending** |
| iOS integration test | The same smoke passed on iPhone 17 Pro Max Simulator / iOS 26.5 on 2026-07-15 | **Historical prior-build platform evidence** |
| Chrome hands-on QA | Rendering, keyboard/mouse input, layout/aspect, and resume checked on macOS on 2026-07-15; app error count 0 | **Historical prior-build browser evidence** |
| Safari hands-on QA | Rendering, keyboard/mouse input, layout/aspect, and resume checked on macOS on 2026-07-15 | **Historical prior-build browser evidence** |
| Android debug APK | `build/app/outputs/flutter-apk/app-debug.apk` from the 2026-07-15 prior build | **Historical prior-build artifact** |
| iOS simulator app | `build/ios/Debug-iphonesimulator/Runner.app/Runner` and `build/ios/iphonesimulator/Runner.app/Runner` from the 2026-07-15 prior build | **Historical prior-build artifact** |
| Default web build | `build/web/main.dart.js`; standard Flutter web path uses CanvasKit | **Verified build and runtime path** |
| Optional Wasm build | `build/web_wasm/main.dart.wasm` plus compatibility JavaScript from the 2026-07-15 prior build; Wasm-capable path uses Skwasm | **Historical optional-build artifact** |
| Blender scene/key art | Arena `.blend`, GLB 2.0 export, and 1440×900 key art under `assets/blender/` | **Verified artifacts** |
| Blender MCP runtime generation | A live BlenderMCP server v1.28.1 session successfully ran `execute_blender_code`, generated the runtime atlas/source artifacts, and was cleanly stopped | **Verified live MCP execution** |
| Blender runtime atlas | 256×64 PNG, JSON manifest, editable `.blend`, base PNG/`.blend`, generation scripts, runtime loading, and source-cell sampling tests | **Verified artifact and runtime integration** |

## Requirement-to-evidence matrix

### 1. Product, core loop, and match rules

| ID | Requirement | Status | Evidence |
|---|---|---|---|
| P-01 | Flutter + Flame app targeting Android, iOS, and Web. | **Verified** | Current `lib/main.dart`, `pubspec.yaml`, platform projects, automated platform tests, and Web release/deployment; Android/iOS integration and Safari/Chrome execution are preserved 2026-07-15 prior-build evidence. |
| P-02 | Four factions with commercially neutral presentation names. | **Verified** | Internal deterministic faction enum in `lib/game/simulation.dart`; Amethyst, Cobalt, Volt, and Prism presentation in `lib/game/faction_visuals.dart`; lobby widget tests. |
| P-03 | Offline single-player; multiplayer/accounts/chat/guilds are excluded. | **Verified** | Local deterministic runtime and offline-safe defaults; no online gameplay dependency. |
| P-04 | Select faction → spawn → move/fight → handoff → result/reward → retry. | **Verified for MVP flow** | App shell, battle, result, reward, and rematch surfaces are implemented; current widget tests cover deploy/result rewards, while the launch/settings/deploy/resume integration smoke is preserved 2026-07-15 prior-build evidence. |
| M-01 | Exactly four armies × 1,000 units = 4,000 units. | **Verified** | Spawn test asserts 4,000 total and 1,000 per faction. |
| M-02 | Equal Lv.1–10 distribution for every faction. | **Verified** | Distribution test asserts 100 units at every level for every faction. |
| M-03 | Higher level always wins; equal level is seeded 50/50. | **Verified** | 10,000 unequal-level trials all favor the higher level; 100,000 equal-level trials remain within 49–51%. |
| M-04 | Atomic engagement with combat lock and recovery. | **Verified** | `CombatResolver` and its direct simulation test. |
| M-05 | Elimination and 15-minute ranking rules. | **Verified** | Elimination path is implemented; survivor count, living-level sum, cumulative kills, and time-limit behavior are directly tested. |
| M-06 | Player elimination permits spectating while the remaining battle continues. | **Verified** | Core simulation test covers null successor, player elimination, and continued match progression. |
| M-07 | Seeded replay/debug log. | **Verified** | Same seed/input reproduces combat logs and exported Map/JSON; far-AI scheduling is also deterministic across render cadences. |
| M-08 | Default movement speed is 64 world units/second with a 1.9× dash. | **Verified** | A direct fixed-tick simulation test verifies normal and dash displacement. |

### 2. Input, camera, UI, and handoff

| ID | Requirement | Status | Evidence |
|---|---|---|---|
| C-01 | Mobile joystick/dash and desktop/web WASD, arrows, Space. | **Verified** | Short/compact landscape layouts now provide a 104dp joystick and 72dp dash target; a 568×320 widget test proves both remain separate from each other and the minimap. Tests also cover normalized input, focus-safe key release, HUD Space activation, minimap key isolation, and rotation input clearing. The physical Android, iOS Simulator, and Safari/Chrome hands-on checks are preserved prior-build evidence. |
| C-02 | Expanded follow camera, density zoom, mouse drag, wheel zoom, and right-side tactical minimap. | **Verified** | Tests cover the closer initial zoom, clamped viewport, faction/control markers, non-overlapping responsive layout, and minimap tap/drag camera navigation even when mouse camera is disabled. |
| C-03 | Exact 1.5-second handoff phases and time scaling. | **Verified** | `HandoffTimeline` plus phase/time-scale and reduced-motion tests. |
| C-04 | Successor score uses level 50%, safety 30%, non-combat 20%. | **Verified** | Direct weight, candidate, and no-successor tests. |
| C-05 | Handoff completes within 1.5 seconds without infinite wait. | **Verified** | Core transfer occurs in the combat tick; presentation preserves the full 1.5-second relay sequence. |
| C-06 | Relay-tape path renders safely throughout a live handoff. | **Verified by current regression test; historical device evidence preserved** | The original profile run exposed illegal `PathMetrics` re-iteration. `_drawRelayTape` now consumes one iterator once, `relay tape safely renders a live handoff path` reproduces the relay-travel render path, and the preserved 2026-07-15 physical Android rerun completed without the exception recurring. |
| C-07 | Sub-600dp Android/iOS/Web displays request landscape for battle and restore platform defaults afterward. | **Verified in automated platform-call and widget tests** | Displays below the 600dp shortest-side breakpoint request both landscape orientations before battle, restore with an empty orientation list on result/disposal, and gate battle rendering/input while portrait. Web uses the same best-effort request path; larger displays and other desktop platforms receive no request. |
| U-01 | Responsive dark battlefield, readable HUD, four high-contrast factions. | **Verified** | Current responsive widget tests and atlas-backed runtime rendering; the 2026-07-15 Safari/Chrome visual/layout QA is preserved prior-build evidence. |
| U-02 | Controlled outline/direction and short combat result feedback. | **Verified in implementation and hands-on render QA** | `TokenfrontGame` renders the controlled marker and 0.38-second combat flash; browser visual QA confirmed the battle surface. |
| U-03 | Accessibility, reduced motion, and pause/resume. | **Verified** | Current preference/semantics/lifecycle tests; the Android, iOS Simulator, Safari, and Chrome resume checks are preserved prior-build evidence. |
| U-04 | Bounded and failure-safe dash/impact/relay audio. | **Verified in implementation** | Bounded `AudioPool` usage, impact rate limiting, settings gates, and non-throwing load/play fallback. |

### 3. AI, simulation cadence, and performance design

| ID | Requirement | Status | Evidence |
|---|---|---|---|
| A-01 | Spawn, Seek, Chase, Engage, Recover, Flee, Dead states. | **Verified in implemented state machine** | `AiState`/`AIController`; direct flee, seek, rally, recovery, combat, and handoff tests exercise the operational transitions. |
| A-02 | SpatialGrid local queries instead of all-pairs scans. | **Verified** | Adjacent-cell correctness, faction-bucket candidate filtering, and the 4,000-unit performance regression guard. |
| A-03 | Separation, rally points, and probabilistic stronger-enemy avoidance. | **Verified** | Direct simulation tests. |
| A-04 | Tactical AI at 10–15Hz; movement/combat at fixed 30Hz. | **Verified** | Cadence and accumulator tests. Movement, grid rebuild, and combat remain on every 30Hz simulation tick. |
| A-05 | Far/off-screen-equivalent AI should update less often. | **Verified** | Targetless `Seek` units more than 720 world units from the live controlled unit use a deterministic 180–220ms decision interval, approximately 5Hz. Near, targeted, chase, engage, flee, recover, and imminent-threat units remain at 10–15Hz. Debug normal/throttled counters and cross-render-cadence determinism are tested. |
| F-01 | 4,000-unit performance baseline and regression guard. | **Verified on host; current-device profile pending** | The host guard runs up to five simulated seconds / 150 fixed ticks, retains the pool, stays below 10% of a 4,000×4,000 all-pairs candidate scan, and finishes below the generous eight-second debug ceiling. The 2026-07-15 physical profile is a historical 400-unit baseline only. |
| F-02 | Minimize per-frame allocation and pool unit objects. | **Verified** | All 4,000 `Unit` objects are allocated at match spawn, dead units remain in the fixed list, and the performance test asserts every object identity is retained. Movement/survivor scratch storage and grid/faction buckets are reused. |
| F-03 | Conservative viewport render culling. | **Verified** | `TokenfrontGame.render` culls live units outside the world viewport plus a 96-unit safety margin, preserves the handoff casualty focus, applies the same bound to chromatic echoes, and exposes rendered/culled debug counts. A canvas test verifies one rendered and one culled unit. |
| F-04 | Atlas rendering and audio concurrency limits. | **Verified** | Blender-produced 4×1 runtime atlas is loaded once and submitted in one `drawRawAtlas` batch for visible units; a canvas test asserts one batch for the default 4,000-unit match. Procedural rendering remains a safe fallback, and `AudioPool` bounds concurrency. |
| F-05 | Low-spec mode reduces rendering load. | **Verified in logic/UI tests** | Reduced grid/effects/trails/HUD work and constrained zoom; toggle and zoom behavior are tested. |
| F-06 | Target 60 average FPS and at least 30 FPS in dense combat. | **Historical 400-unit device evidence; current 4,000-unit acceptance pending** | The 2026-07-15 SM A175N run cleared 60 average / 30 dense for the former 400-unit build. It does not verify the current 4,000-unit build; repeat profile, thermal, memory, and endurance collection remains a launch task. |

### 4. Web renderer and platform behavior

| ID | Requirement | Status | Evidence |
|---|---|---|---|
| W-01 | Standard deployable web build. | **Verified** | Default release artifact exists under `build/web/` and uses the standard CanvasKit path. |
| W-02 | Optional modern Wasm renderer path. | **Verified build** | `build/web_wasm/main.dart.wasm` and its compatibility output exist; supported browsers may use Skwasm. This is optional, not the default deployment requirement. |
| W-03 | Legacy HTML renderer comparison. | **Resolved as superseded** | The current Flutter toolchain no longer uses the legacy HTML-renderer workflow from the original planning note. Current choices are default CanvasKit and optional Wasm/Skwasm. |
| W-04 | Chromium-family and Safari visual/input/aspect/resume QA. | **Current Brave core-flow evidence; historical Chrome/Safari evidence** | Current Brave checks cover the 4×1,000 lobby, battle, tactical minimap, controls, and zero console errors/warnings. Chrome and Safari were exercised locally on macOS on 2026-07-15, before the current camera/minimap/orientation changes. |

### 5. Blender MCP and runtime visual assets

| ID | Requirement | Status | Evidence |
|---|---|---|---|
| B-01 | Editable Blender arena/key-art source and export. | **Verified** | `assets/blender/tokenfront_arena.blend`, `tokenfront_arena.glb`, `tokenfront_keyart.png`, and `tooling/build_tokenfront_scene.py`. |
| B-02 | Runtime sprite atlas authored through Blender MCP. | **Verified in a live MCP session** | BlenderMCP server v1.28.1 successfully executed `execute_blender_code` and produced `assets/images/tokenfront_token_atlas.png`, its JSON manifest, `assets/blender/tokenfront_token_atlas.blend`, the base PNG/`.blend`, and the arena/key-art artifacts. The MCP server was cleanly stopped after completion. Generation scripts and the MCP request are retained under `tooling/`. |
| B-03 | Atlas dimensions/cells and runtime use. | **Verified by tests** | `test/token_atlas_test.dart` verifies the exact 256×64 image, four 64×64 cells ordered Amethyst/Cobalt/Volt/Prism, successful game loading, and per-faction source rectangles. |
| B-04 | Asset fallback safety. | **Verified in implementation** | Atlas load failure falls back to the procedural token renderer without blocking a match. |

### 6. Advertising, economy, privacy, and analytics

| ID | Requirement | Status | Evidence / launch boundary |
|---|---|---|---|
| E-01 | Interstitial only after results, no more than every two matches, never during battle/handoff. | **Verified as policy logic** | Direct service/runtime tests cover eligibility, impression/dismissal/failure analytics, frequency suppression, and battle/handoff suppression. |
| E-02 | Rewarded result offer doubles War Tokens only after completed reward. | **Verified with deterministic adapter** | Runtime, service, economy, and widget tests cover success, skip/failure, idempotency, and guaranteed base reward. |
| E-03 | Banner only in lobby/result. | **Verified as policy logic** | Direct placement tests. |
| E-04 | Ads/network/consent failures never block gameplay. | **Verified** | NoOp/Fake adapters and exception-to-value tests. |
| E-05 | War Tokens affect cosmetics only. | **Verified** | Catalog, wallet, locker, and economy tests. |
| E-06 | Privacy and ATT model blocks tracking identifiers before authorization. | **Verified as app-layer gate** | Privacy/service/runtime tests cover consent denial, ATT denial/not-determined, and null identifiers. Native ATT UI remains a launch integration item. |
| N-01 | Typed launch analytics and offline bounded buffer. | **Verified** | Typed event coverage, D1/D7 validation, bounded buffering, consent/offline gates, retry retention, and successful-flush tests. |
| N-02 | Production ad/analytics providers. | **Pending launch integration** | The default remains NoOp; live SDKs, IDs, credentials, and production receipt verification are intentionally not represented as complete. |
| N-03 | Settings, wallet, and cosmetic state survive restart. | **Verified locally** | A versioned snapshot restores War Tokens, unlock/equip state, five preferences, and analytics/ad choices. Runtime recreation, transient I/O, overwrite protection, real Chrome storage, and browser reload checks pass. This is device-local soft-currency state, not an account or purchase ledger. |

## Automated test inventory

The 2026-08-05 integrated worktree checkpoint passed **190 VM tests** and
skipped the one browser-only localStorage test. The inventory now covers:

- 4,000-unit simulation, deterministic combat, spatial-query performance,
  culling, atlas batching, input, camera, orientation, pause/resume, and
  lifecycle behavior;
- the five-operation Signal Chronicle, directives, rewards, both endings,
  non-canonical replay, semantic persistence validation, and result layouts;
- English, Korean, Japanese, and Simplified Chinese presentation plus localized
  live directive and accessibility semantics;
- offline NoOp ads/analytics, privacy gates, wallet/settings/story persistence,
  and the source-level release data-flow contract; and
- Blender asset dimensions/runtime sampling plus Google Play icon and feature
  graphic format/dimension contracts.

The browser-only `test/tokenfront_state_store_web_test.dart` remains a separate
Chromium invocation and is not promoted by this VM checkpoint.

### Task 12 execution evidence (2026-08-05)

| Scenario / invocation | Observable result | Artifact |
|---|---|---|
| RED gate: `flutter test integration_test/app_smoke_test.dart` before the missing import was wired | Failed while compiling the new deterministic scenarios (`ClientPlatform` undefined) | `.omo/evidence/task-12/red-integration.log` |
| Android emulator integration: `flutter test integration_test/app_smoke_test.dart -d emulator-5554 -r expanded` | 10 scenarios plus existing smoke passed (`All tests passed!`) on the implementation API 37 emulator | `.omo/evidence/task-12/integration.log` |
| 4,000-unit performance: `flutter test test/performance_test.dart -r expanded` | 150 fixed ticks / 30 Hz, 30,754,185 candidate visits, 205,027.9 visits/tick, 254 ms host sample | `.omo/evidence/task-12/performance.log` |
| 4,000-unit profile: `flutter run --profile -d emulator-5554 -t tooling/performance_profile_app.dart` | `sdk gphone16k arm64`, Android API 37 emulator (not a physical device); 30-second sample at fixed 30 Hz with warmup-subtracted 895 simulation ticks, 1,474,486 grid queries, and 37,604,824 candidate visits; 1,715 frames, 58.69 average FPS, 30 FPS 1% low, 566 rendered / 47 culled units, one atlas batch | `.omo/evidence/task-12/fix-device-profile.log` |
| Formatter: `dart format --output=none --set-exit-if-changed lib test integration_test tooling` | Exit 0 after formatting changed files | `.omo/evidence/task-12/format.log` |
| Localization: `flutter gen-l10n` | Exit 0 | `.omo/evidence/task-12/gen-l10n.log` |
| Analyzer: `flutter analyze` | Exit 0, `No issues found!` | `.omo/evidence/task-12/analyze.log` |
| Full suite: `flutter test -r compact` | Exit 0, 176 passed and 1 Web-only skip | `.omo/evidence/task-12/full-test.log` |
| Release Web build: `flutter build web --release` | Exit 0, `build/web` generated | `.omo/evidence/task-12/web-build.log` |
| Pre-deploy digest: `find build/web ... shasum -a 256` | 46 files captured before any upload attempt | `.omo/evidence/task-12/tokenfront-orbital-war-build.sha256` |
| Cloudflare upload: `npx wrangler pages deploy build/web --project-name=tokenfront-orbital-war --branch=main` | Production deployment completed at `2026-08-04T20:53:49.386Z`; 46 files uploaded, deployment ID `e74f7d12-c7c5-40c0-9d87-83240b57de5c` | `.omo/evidence/task-12/wrangler-deploy.log` |
| Live preview verification | Canonical index and manifest returned exit 0; both identify `Tokenfront: Orbital Signal War` | `.omo/evidence/task-12/preview-index.html`, `.omo/evidence/task-12/preview-manifest.json` |

The deployment artifact comparison redownloaded all 46 production files and
compared each response with the pre-deploy manifest: `CHECKED=46
MISMATCHES=0`. The deployed `manifest.json` artifact matches the expected
SHA-256 `30144ad28592b7b7a4e58d99d8cda01111a2aa1d2e13c176f55c6ea89e5e74c9`,
and the captured preview manifest has the same digest. The complete comparison
record, including the `-d emulator-5554` API 37 scope, is retained in
`.omo/evidence/task-12/post-deploy-comparison.txt`.

The profile-mode entrypoint now emits `TOKENFRONT_PERFORMANCE` with fixed Hz,
FPS, 1% low, rendered/cull counts, atlas batch submissions/sprites, and grid
candidate metrics. A real-device 4,000-unit profile and browser hands-on
matrix remain separate QA evidence; the historical 400-unit device result is
not promoted to current-build acceptance.

The separate integration suite contains eleven scenarios (the existing launch
smoke plus ten deterministic Chronicle/Skirmish scenarios):

| File | Count | Exact scenario | Executed targets |
|---|---:|---|---|
| `integration_test/app_smoke_test.dart` | 11 | Launch/configure/resume smoke; persistence, elimination, replay, locked-directive, five-operation, deterministic 4-core × 5-seed, and 900-second Skirmish scenarios | `emulator-5554` sdk gphone16k arm64 / Android API 37 passed on 2026-08-05; historical SM A175N / Android 16 and iPhone 17 Pro Max Simulator / iOS 26.5 evidence remains prior-build. |

## Launch-only gaps that remain open

1. **Live ad and analytics integrations:** select and connect AdMob/H5 Games Ads and the production analytics SDK/endpoint; add publisher/ad-unit IDs, credentials, live inventory/event receipt, and provider failure QA.
2. **Native iOS ATT:** implement the native system prompt and approve the final ATT purpose string/consent copy.
3. **Signing and store privacy metadata:** configure Android/iOS release signing and provisioning; complete store privacy/data-safety declarations, privacy policy, ad disclosure, age rating, target markets, screenshots, and submission metadata.
4. **Long-duration and cross-platform performance acceptance:** the 60 average / 30 dense target was verified only for the historical 400-unit SM A175N session. Current 4,000-unit device acceptance remains pending; collect long-duration memory, thermal, endurance, FPS, and 1% low data on representative real Android/iOS devices and deployed browsers. Compare default CanvasKit and optional Skwasm only if the Wasm path is selected for production.

## Audit conclusion

The requested gameplay MVP, deterministic combat rules, handoff experience, responsive cross-platform controls, far-AI throttling, fixed 4,000-unit pool, expanded camera and tactical minimap, sub-600dp Android/iOS/Web landscape-request and portrait-gate flow, render culling, Blender MCP runtime atlas, offline-safe service boundaries, and automated regression suite are implemented and evidenced. The 2026-07-15 Android physical, iOS Simulator, Safari, and Chrome checks remain preserved platform evidence for the prior build. The relay-tape `PathMetrics` fix remains regression-tested, while the former SM A175N result is treated strictly as a historical 400-unit performance baseline.

The workspace is not yet store-ready because live provider credentials/SDKs, native ATT UI/copy, release signing/store declarations, and long-duration real-device performance acceptance remain open. Device-local persistence is now implemented and verified; account synchronization or a purchase ledger would be a separate requirement if War Tokens ever become purchasable.
