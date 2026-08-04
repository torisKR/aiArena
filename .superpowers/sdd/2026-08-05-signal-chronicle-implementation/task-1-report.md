# Task 1 report: neutral faction identifiers and Orbital public metadata

## RED (TDD first)

Added the named test `faction IDs and exported logs are original and schema 2` to `test/simulation_test.dart` before changing production code.

Invocation:

```text
flutter test test/simulation_test.dart --plain-name "faction IDs and exported logs are original and schema 2"
```

Result: RED as required. Compilation failed with `Error: Member not found: 'amethyst'.` at `playerFaction: Faction.amethyst` because the existing enum still used the prior identifiers.

## GREEN

Implemented the exact ordered enum mapping (`amethyst`, `cobalt`, `volt`, `prism`), preserved visual and atlas index order, renamed all Faction references across runtime/tests/tooling, and changed debug combat-log `schemaVersion` from 1 to 2. Updated the four approved localized title/tagline/action strings, regenerated Flutter localization output, and applied Orbital metadata to web, PWA, package, README/audit headings, and Wrangler.

Focused invocation:

```text
flutter gen-l10n
flutter test test/simulation_test.dart test/token_atlas_test.dart test/battle_accessibility_input_test.dart test/localization_test.dart
```

Result: PASS, 65 tests passed.

Full-suite invocation (run once as required):

```text
flutter test
```

Result: PASS, 119 tests passed with 1 pre-existing skipped test (`~1`).

## Brand-boundary check

Invocation:

```text
rg -n -i "claude|gemini|chatgpt|grok|codex|openai|ai arena" lib web pubspec.yaml README.md docs/completion-audit.md tooling
```

No semantic legacy product names remain in the scanned release surfaces. The only output is `geMini` from the existing identifier `minimap`/`nudgeMinimapCamera`; it is a case-insensitive substring false positive, not a product name. The old tooling docstring containing a legacy name was removed. Test-only anti-brand literals remain intentionally in the required regression assertion.

## Files changed

Task brief paths changed: `lib/game/simulation.dart`, `lib/game/faction_visuals.dart`, `lib/game/tokenfront_game.dart`, `lib/main.dart`, `tooling/performance_profile_app.dart`, `test/simulation_test.dart`, `test/widget_test.dart`, `test/token_atlas_test.dart`, `test/battle_accessibility_input_test.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_ko.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb`, generated `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_ko.dart`, `lib/l10n/app_localizations_ja.dart`, `lib/l10n/app_localizations_zh.dart`, `web/index.html`, `web/manifest.json`, `pubspec.yaml`, `README.md`, `docs/completion-audit.md`, and `wrangler.jsonc`.

Mechanical rename/expectation expansions required for compile and the mandated checks: `lib/ui/lobby_screen.dart`, `lib/ui/battle_screen.dart`, `test/localization_test.dart`, `test/orientation_test.dart`, and `tooling/blender_mcp_call.py` (nonessential legacy-name docstring removal). No behavior outside the Task 1 mapping/metadata contract was changed.

## Self-review

- `Faction` declaration order remains unchanged semantically, so deterministic faction indexes, atlas rectangles, staging quadrants, rally points, and tie-breaking remain stable.
- `FactionVisuals.visual` keeps the approved AMETHYST/COBALT/VOLT/PRISM names, marks, colors, and side counts.
- Exported debug logs now identify schema 2 and emit only neutral faction enum names.
- Android resource labels were not edited; Cloudflare was not deployed.
- `git diff --check` passed.

## Concerns

The required naive brand-boundary regex reports `geMini` inside the pre-existing `minimap` identifier. This is a substring false positive; changing the established minimap API would broaden Task 1 unnecessarily. No actual legacy brand token remains in runtime, metadata, or user-visible copy.
