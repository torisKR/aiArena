# Signal Chronicle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebrand the existing deterministic 4,000-unit game as Tokenfront: Orbital Signal War and ship the five-operation SIGNAL CHRONICLE campaign, persistent progression, optional mastery rewards, accessible story UI, two endings, and a verified interim Cloudflare feature preview without changing Skirmish combat.

**Architecture:** Keep BattleSimulation deterministic and story-agnostic. Add immutable story content and a pure CampaignController around BattleReport, persist StoryProgress and ProfileRewardLedger through the existing runtime, and let TokenfrontRoot coordinate Chronicle versus Skirmish while screens consume view data and callbacks only. TokenfrontGame collects directive metrics at existing event boundaries and HUD cadence, with no additional scan over all units.

**Tech Stack:** Flutter 3.44.6, Dart 3.12.2, Flame, flutter_localizations/ARB, shared_preferences/localStorage state adapters, Blender scene tooling through tooling/blender_mcp_call.py, Flutter integration tests, Cloudflare Pages/Wrangler.

## Global Constraints

- English is the source locale; English, Korean, Japanese, and Simplified Chinese ship together.
- Public title is Tokenfront: Orbital Signal War. User-visible/runtime/exported identifiers must not contain Claude, Gemini, ChatGPT, Grok, Codex, or OpenAI.
- Internal faction IDs are exactly amethyst, cobalt, volt, and prism. All four remain mechanically identical.
- Chronicle has exactly five ordered operations, each using 1,000 units per faction, fixed 30 Hz simulation, a 180-simulation-second limit, and seeds 2026080501 through 2026080505.
- Skirmish retains its existing 900-simulation-second limit, unrestricted faction selection, spectator flow, ranking, handoff, base reward, and 4,000-unit battle.
- A concluded Chronicle attempt advances the story after time limit, global resolution, or player-faction elimination, independent of directive success.
- Directive boundaries are exactly 45.0 uninterrupted command seconds, 2 completed handoffs, 3 directly commanded kills, rank 2 or better, and sole victory.
- Directive bonuses are exactly 15, 20, 25, 30, and 40 WT. Each operation bonus is paid once per local profile; Chronicle restart never resets that lifetime ledger.
- The medal, lifetime claim ID, and WT credit are one idempotent debrief transition. Rewarded-ad doubling applies only to the existing base reward.
- Campaign metrics reuse combat events, handoff completion, simulation time, standings, and the current HUD publish cadence; they add no per-frame unit scan.
- The existing 104 dp joystick, 72 dp dash control, minimap, focus order, screen-reader support, reduced-motion behavior, and low-spec behavior remain usable.
- The local snapshot migrates from schema 1 to schema 2 and preserves wallet, cosmetics, language, accessibility, audio, camera, privacy, and advertising choices.
- Missing story state resets only Chronicle. Story construction failure leaves Skirmish playable with CHRONICLE UNAVAILABLE.
- The previous tokenfront-ai-arena Cloudflare deployment is retained. This plan may publish an interim feature preview at tokenfront-orbital-war.pages.dev; the privacy/Play publishing plan Task 7 exclusively owns the final post-privacy Web rebuild, source-parity proof, and production redeploy.
- This plan owns the shared EN/KO/JA/ZH product-name copy in ARB/Web sources. The Android production-release plan exclusively owns android/app/src/main/res/values*/strings.xml, its launcher-label contract, adaptive icons, and final package verification.
- This plan fixes the lifecycle/input regression and may smoke it on an available emulator. The Android production-release plan Task 5 exclusively owns API 36 emulator plus physical-device acceptance and release evidence.
- Do not add accounts, online inference, multiplayer, faction abilities, capture points, ship physics, live ad credentials, purchases, or new analytics events.
- Execute from baseline commit 024c6d2 or a descendant that preserves it. Before Task 1, inspect git status and preserve all later user/agent changes; never stage broad directories. Every commit below uses only the exact listed paths.
- Historical pre-fix baseline: 118 Flutter tests passing, one Web-only test skipped, and flutter analyze clean. The current Android checkpoint is 269 VM tests plus integration suites passing 10/10 and 1/1 on emulator-5586; the former integration failures at `integration_test/app_smoke_test.dart:36` and the disposed `FocusManager` are resolved historical context.

---

## File map

| Responsibility | Files |
|---|---|
| Neutral combat IDs and debug schema | lib/game/simulation.dart, lib/game/faction_visuals.dart |
| Story data and pure rules | lib/story/story_models.dart, lib/story/story_catalog.dart, lib/story/campaign_controller.dart |
| Battle metrics and report production | lib/game/tokenfront_game.dart |
| Persistence and atomic story rewards | lib/app/tokenfront_runtime.dart |
| Mode and route coordination | lib/main.dart |
| Command Deck, Archive, ring, battle rail, debrief | lib/ui/lobby_screen.dart, lib/ui/archive_sheet.dart, lib/ui/orbital_progress_ring.dart, lib/ui/battle_screen.dart, lib/ui/result_screen.dart |
| Localized story presentation | lib/story/story_localizations.dart, lib/l10n/app_en.arb, lib/l10n/app_ko.arb, lib/l10n/app_ja.arb, lib/l10n/app_zh.arb, generated lib/l10n/app_localizations*.dart |
| Shared product title and interim Web preview | web/index.html, web/manifest.json, pubspec.yaml, README.md, docs/completion-audit.md, wrangler.jsonc |
| Orbital art | tooling/build_tokenfront_scene.py, assets/blender/tokenfront_arena.blend, assets/blender/tokenfront_arena.glb, assets/blender/tokenfront_keyart.png |
| Verification | test/story_catalog_test.dart, test/campaign_controller_test.dart, test/chronicle_metrics_test.dart, test/runtime_test.dart, test/localization_test.dart, test/widget_test.dart, test/battle_accessibility_input_test.dart, test/performance_test.dart, integration_test/app_smoke_test.dart |

### Task 1: Neutral faction identifiers and Orbital public metadata

**Files:**
- Modify: lib/game/simulation.dart
- Modify: lib/game/faction_visuals.dart
- Modify: lib/game/tokenfront_game.dart
- Modify: lib/main.dart
- Modify: tooling/performance_profile_app.dart
- Modify: test/simulation_test.dart
- Modify: test/widget_test.dart
- Modify: test/token_atlas_test.dart
- Modify: test/battle_accessibility_input_test.dart
- Modify: lib/l10n/app_en.arb
- Modify: lib/l10n/app_ko.arb
- Modify: lib/l10n/app_ja.arb
- Modify: lib/l10n/app_zh.arb
- Regenerate: lib/l10n/app_localizations.dart
- Regenerate: lib/l10n/app_localizations_en.dart
- Regenerate: lib/l10n/app_localizations_ko.dart
- Regenerate: lib/l10n/app_localizations_ja.dart
- Regenerate: lib/l10n/app_localizations_zh.dart
- Modify: web/index.html
- Modify: web/manifest.json
- Modify: pubspec.yaml
- Modify: README.md
- Modify: docs/completion-audit.md
- Modify: wrangler.jsonc

**Interfaces:**
- Consumes: BattleSimulation.exportDebugCombatLog() and FactionVisuals.visual.
- Produces: enum Faction { amethyst, cobalt, volt, prism }; debug schemaVersion 2; shared localized product copy; interim Cloudflare project name tokenfront-orbital-war.

- [ ] **Step 1: Write the failing neutral-ID test**

Add this test to test/simulation_test.dart:

~~~dart
test('faction IDs and exported logs are original and schema 2', () {
  expect(
    Faction.values.map((faction) => faction.name),
    orderedEquals(const ['amethyst', 'cobalt', 'volt', 'prism']),
  );
  final simulation = BattleSimulation(
    seed: 2026080501,
    playerFaction: Faction.amethyst,
    config: const BattleConfig(unitsPerFaction: 2),
  );
  final payload = simulation.exportDebugCombatLog();
  expect(payload['schemaVersion'], 2);
  expect(
    simulation.exportDebugCombatLogJson().toLowerCase(),
    isNot(anyOf(contains('claude'), contains('codex'), contains('grok'), contains('gemini'))),
  );
});
~~~

- [ ] **Step 2: Run the focused test and confirm RED**

Run: flutter test test/simulation_test.dart --plain-name "faction IDs and exported logs are original and schema 2"

Expected: FAIL to compile because Faction.amethyst does not exist.

- [ ] **Step 3: Rename the enum and preserve visual/atlas order**

Apply this exact mapping everywhere under lib, test, integration_test, and tooling:

~~~text
Faction.claude -> Faction.amethyst
Faction.codex  -> Faction.cobalt
Faction.grok   -> Faction.volt
Faction.gemini -> Faction.prism
~~~

Then set the declarations to:

~~~dart
enum Faction { amethyst, cobalt, volt, prism }

extension FactionVisuals on Faction {
  FactionVisual get visual => switch (this) {
    Faction.amethyst => const FactionVisual(name: 'AMETHYST', mark: '◆', color: TokenfrontColors.amethyst, sides: 4),
    Faction.cobalt => const FactionVisual(name: 'COBALT', mark: '[ ]', color: TokenfrontColors.cobalt, sides: 4),
    Faction.volt => const FactionVisual(name: 'VOLT', mark: 'ϟ', color: TokenfrontColors.volt, sides: 3),
    Faction.prism => const FactionVisual(name: 'PRISM', mark: '✣', color: TokenfrontColors.prism, sides: 6),
  };
}
~~~

Change exportDebugCombatLog schemaVersion from 1 to 2. Do not reorder the enum because atlas rectangles and deterministic tie-breaking use indexes.

- [ ] **Step 4: Apply exact public metadata**

Set the Web title and description to Tokenfront: Orbital Signal War, the PWA short name to Tokenfront, pubspec description to Four AI command cores fight for the Last Relay in a deterministic 4,000-unit orbital signal war., and wrangler.jsonc name to tokenfront-orbital-war. Update README.md and docs/completion-audit.md headings to the new title. Do not edit Android resource labels here: the Android production-release plan Task 3 consumes the same four approved strings and owns their resource-level RED/PASS contract. That Android test must remain valid whether labels are stale or already synchronized, because its missing adaptive/round/monochrome resources independently establish RED.

Replace the existing appTitle, lobbyTagline, and deploySignal values in all four ARBs with the exact EN/KO/JA/ZH title, lobby line, and primary action in the approved Orbital design. Run flutter gen-l10n so the app itself changes title in this commit; Task 7 adds the remaining Chronicle copy.

- [ ] **Step 5: Verify the domain, metadata, and brand boundary**

Run:

~~~bash
flutter gen-l10n
flutter test test/simulation_test.dart test/token_atlas_test.dart test/battle_accessibility_input_test.dart test/localization_test.dart
rg -n -i "claude|gemini|chatgpt|grok|codex|openai|ai arena" lib web pubspec.yaml README.md docs/completion-audit.md tooling
~~~

Expected: all tests PASS; rg returns no user-visible/runtime/exported third-party product names and no old AI Arena title. Comments that describe the Codex tool are not permitted in these release surfaces either.

- [ ] **Step 6: Commit the neutral rebrand**

~~~bash
git add lib/game/simulation.dart lib/game/faction_visuals.dart lib/game/tokenfront_game.dart lib/main.dart tooling/performance_profile_app.dart test/simulation_test.dart test/widget_test.dart test/token_atlas_test.dart test/battle_accessibility_input_test.dart lib/l10n/app_en.arb lib/l10n/app_ko.arb lib/l10n/app_ja.arb lib/l10n/app_zh.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_ko.dart lib/l10n/app_localizations_ja.dart lib/l10n/app_localizations_zh.dart web/index.html web/manifest.json pubspec.yaml README.md docs/completion-audit.md wrangler.jsonc
git commit -m "feat: establish orbital signal war identity"
~~~

### Task 2: Story domain models and immutable catalog

**Files:**
- Create: lib/story/story_models.dart
- Create: lib/story/story_catalog.dart
- Create: test/story_catalog_test.dart

**Interfaces:**
- Consumes: Faction and FactionStanding from lib/game/simulation.dart.
- Produces: GameMode, StoryOperationId, DirectiveKind, EndingChoice, ChronicleEndReason, Directive, DirectiveProgress, StoryOperation, BattleReport, StoryProgress, ProfileRewardLedger, and StoryCatalog.operations.

- [ ] **Step 1: Write the failing catalog contract**

Create test/story_catalog_test.dart:

~~~dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/story/story_catalog.dart';
import 'package:tokenfront/story/story_models.dart';

void main() {
  test('catalog contains the five fixed operations in order', () {
    expect(StoryCatalog.operations.map((op) => op.id), StoryOperationId.values);
    expect(
      StoryCatalog.operations.map((op) => op.seed),
      orderedEquals(const [2026080501, 2026080502, 2026080503, 2026080504, 2026080505]),
    );
    expect(StoryCatalog.operations.every((op) => op.duration == const Duration(seconds: 180)), isTrue);
    expect(StoryCatalog.operations.map((op) => op.directive.target), orderedEquals(const [45.0, 2.0, 3.0, 2.0, 1.0]));
    expect(StoryCatalog.operations.map((op) => op.oneTimeBonus), orderedEquals(const [15, 20, 25, 30, 40]));
  });

  test('fresh progress and reward ledger are empty', () {
    expect(StoryProgress.initial().currentOperation, StoryOperationId.wake);
    expect(StoryProgress.initial().campaignFaction, isNull);
    expect(StoryProgress.initial().ending, isNull);
    expect(ProfileRewardLedger.empty().claimedDirectiveBonusIds, isEmpty);
  });

  test('story collections defensively copy and expose no mutation path', () {
    final concluded = <StoryOperationId>{StoryOperationId.wake};
    final medals = <StoryOperationId>{StoryOperationId.wake};
    final transmissions = <StoryOperationId>{StoryOperationId.wake};
    final progress = StoryProgress(
      campaignFaction: Faction.amethyst,
      concludedOperations: concluded,
      medals: medals,
      recoveredTransmissions: transmissions,
      ending: null,
    );
    concluded.add(StoryOperationId.echo);
    medals.clear();
    transmissions.add(StoryOperationId.split);

    expect(progress.concludedOperations, {StoryOperationId.wake});
    expect(progress.medals, {StoryOperationId.wake});
    expect(progress.recoveredTransmissions, {StoryOperationId.wake});
    expect(
      () => progress.concludedOperations.add(StoryOperationId.echo),
      throwsUnsupportedError,
    );
    final encoded = progress.toJson();
    (encoded['concludedOperations']! as List<Object?>).clear();
    expect(progress.concludedOperations, {StoryOperationId.wake});

    final equivalent = StoryProgress(
      campaignFaction: Faction.amethyst,
      concludedOperations: {StoryOperationId.wake},
      medals: {StoryOperationId.wake},
      recoveredTransmissions: {StoryOperationId.wake},
      ending: null,
    );
    expect(progress, equivalent);
    expect(progress.hashCode, equivalent.hashCode);
  });

  test('ledger report and catalog collections are immutable values', () {
    final claims = <String>{'chronicle-directive-wake'};
    final ledger = ProfileRewardLedger(claimedDirectiveBonusIds: claims);
    claims.add('chronicle-directive-echo');
    expect(ledger.claimedDirectiveBonusIds, {'chronicle-directive-wake'});
    expect(
      () => ledger.claimedDirectiveBonusIds.add('chronicle-directive-split'),
      throwsUnsupportedError,
    );
    expect(
      ledger,
      ProfileRewardLedger(
        claimedDirectiveBonusIds: {'chronicle-directive-wake'},
      ),
    );
    expect(
      ledger.hashCode,
      ProfileRewardLedger(
        claimedDirectiveBonusIds: {'chronicle-directive-wake'},
      ).hashCode,
    );

    const standing = FactionStanding(
      faction: Faction.amethyst,
      survivors: 10,
      levelSum: 50,
      kills: 3,
    );
    final standings = <FactionStanding>[standing];
    final report = BattleReport(
      endReason: ChronicleEndReason.timeLimit,
      standingsAtConclusion: standings,
      globalWinner: Faction.amethyst,
      commandRelays: 1,
      commandKills: 3,
      longestCommandLinkSeconds: 45,
      playerRank: 1,
      playerSurvivors: 10,
    );
    standings.clear();
    expect(report.standingsAtConclusion, hasLength(1));
    expect(
      () => report.standingsAtConclusion.add(standing),
      throwsUnsupportedError,
    );
    final equivalentReport = BattleReport(
      endReason: ChronicleEndReason.timeLimit,
      standingsAtConclusion: const [standing],
      globalWinner: Faction.amethyst,
      commandRelays: 1,
      commandKills: 3,
      longestCommandLinkSeconds: 45,
      playerRank: 1,
      playerSurvivors: 10,
    );
    expect(report, equivalentReport);
    expect(report.hashCode, equivalentReport.hashCode);
    expect(
      () => StoryCatalog.operations.add(StoryCatalog.operations.first),
      throwsUnsupportedError,
    );
  });
}
~~~

- [ ] **Step 2: Run the focused test and confirm RED**

Run: flutter test test/story_catalog_test.dart

Expected: FAIL because lib/story/story_catalog.dart and its types do not exist.

- [ ] **Step 3: Implement the exact story types**

Create immutable value types with these signatures in lib/story/story_models.dart:

~~~dart
import 'package:flutter/foundation.dart' show setEquals;

enum GameMode { chronicle, skirmish }
enum StoryOperationId { wake, echo, split, crown, lastInstruction }
enum DirectiveKind { longestCommandLink, commandRelays, commandKills, finalRank, victory }
enum EndingChoice { claimRelay, openRelay }
enum ChronicleEndReason { timeLimit, globalResolution, playerEliminated }

final class Directive {
  const Directive({required this.kind, required this.target});
  final DirectiveKind kind;
  final double target;
}

final class DirectiveProgress {
  const DirectiveProgress({required this.kind, required this.current, required this.target});
  final DirectiveKind kind;
  final double current;
  final double target;
  bool get completed => switch (kind) {
    DirectiveKind.finalRank => current <= target,
    _ => current >= target,
  };
}

final class StoryOperation {
  const StoryOperation({
    required this.id,
    required this.seed,
    required this.duration,
    required this.directive,
    required this.oneTimeBonus,
  });
  final StoryOperationId id;
  final int seed;
  final Duration duration;
  final Directive directive;
  final int oneTimeBonus;
  String get bonusClaimId => 'chronicle-directive-${id.name}';
}

final class BattleReport {
  BattleReport({
    required this.endReason,
    required List<FactionStanding> standingsAtConclusion,
    required this.globalWinner,
    required this.commandRelays,
    required this.commandKills,
    required this.longestCommandLinkSeconds,
    required this.playerRank,
    required this.playerSurvivors,
  }) : standingsAtConclusion =
           List<FactionStanding>.unmodifiable(standingsAtConclusion);
  final ChronicleEndReason endReason;
  final List<FactionStanding> standingsAtConclusion;
  final Faction? globalWinner;
  final int commandRelays;
  final int commandKills;
  final double longestCommandLinkSeconds;
  final int playerRank;
  final int playerSurvivors;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BattleReport &&
          endReason == other.endReason &&
          _standingsEqual(standingsAtConclusion, other.standingsAtConclusion) &&
          globalWinner == other.globalWinner &&
          commandRelays == other.commandRelays &&
          commandKills == other.commandKills &&
          longestCommandLinkSeconds == other.longestCommandLinkSeconds &&
          playerRank == other.playerRank &&
          playerSurvivors == other.playerSurvivors;

  @override
  int get hashCode => Object.hash(
    endReason,
    Object.hashAll(standingsAtConclusion.map(_standingHash)),
    globalWinner,
    commandRelays,
    commandKills,
    longestCommandLinkSeconds,
    playerRank,
    playerSurvivors,
  );
}

bool _standingsEqual(List<FactionStanding> left, List<FactionStanding> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    final a = left[index];
    final b = right[index];
    if (a.faction != b.faction ||
        a.survivors != b.survivors ||
        a.levelSum != b.levelSum ||
        a.kills != b.kills) {
      return false;
    }
  }
  return true;
}

int _standingHash(FactionStanding standing) => Object.hash(
  standing.faction,
  standing.survivors,
  standing.levelSum,
  standing.kills,
);
~~~

StoryProgress must expose campaignFaction, an ordered Set of concluded operation IDs, an ordered Set of medal IDs, recovered transmission IDs, EndingChoice? ending, currentOperation, toJson(), and StoryProgress.fromJson(). ProfileRewardLedger must expose an immutable claimedDirectiveBonusIds set, toJson(), and fromJson(). Store enum names, never localized labels.

Use this exact public shape, with unmodifiable Set views, structural equality, and matching hashCode:

~~~dart
final class StoryProgress {
  StoryProgress({
    required this.campaignFaction,
    required Iterable<StoryOperationId> concludedOperations,
    required Iterable<StoryOperationId> medals,
    required Iterable<StoryOperationId> recoveredTransmissions,
    required this.ending,
  }) : concludedOperations = _orderedStoryIds(concludedOperations),
       medals = _orderedStoryIds(medals),
       recoveredTransmissions = _orderedStoryIds(recoveredTransmissions);
  factory StoryProgress.initial();
  factory StoryProgress.fromJson(Map<String, Object?> json);
  final Faction? campaignFaction;
  final Set<StoryOperationId> concludedOperations;
  final Set<StoryOperationId> medals;
  final Set<StoryOperationId> recoveredTransmissions;
  final EndingChoice? ending;
  StoryOperationId? get currentOperation;
  StoryProgress lockCore(Faction faction);
  Map<String, Object?> toJson();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryProgress &&
          campaignFaction == other.campaignFaction &&
          setEquals(concludedOperations, other.concludedOperations) &&
          setEquals(medals, other.medals) &&
          setEquals(recoveredTransmissions, other.recoveredTransmissions) &&
          ending == other.ending;
  @override
  int get hashCode => Object.hash(
    campaignFaction,
    Object.hashAll(concludedOperations),
    Object.hashAll(medals),
    Object.hashAll(recoveredTransmissions),
    ending,
  );
}

final class ProfileRewardLedger {
  ProfileRewardLedger({required Iterable<String> claimedDirectiveBonusIds})
    : claimedDirectiveBonusIds = Set<String>.unmodifiable(
        claimedDirectiveBonusIds.toList()..sort(),
      );
  factory ProfileRewardLedger.empty();
  factory ProfileRewardLedger.fromJson(Map<String, Object?> json);
  final Set<String> claimedDirectiveBonusIds;
  Map<String, Object?> toJson();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileRewardLedger &&
          setEquals(
            claimedDirectiveBonusIds,
            other.claimedDirectiveBonusIds,
          );
  @override
  int get hashCode => Object.hashAll(claimedDirectiveBonusIds);
}

Set<StoryOperationId> _orderedStoryIds(Iterable<StoryOperationId> source) {
  final present = source.toSet();
  return Set<StoryOperationId>.unmodifiable(
    StoryOperationId.values.where(present.contains),
  );
}
~~~

Implement StoryProgress and ProfileRewardLedger equality with setEquals from package:flutter/foundation.dart. Because _orderedStoryIds and the sorted claim set give canonical iteration order, compute matching hashCode with Object.hashAll over each stored set. Every copyWith, lockCore, fromJson, controller transition, and restart must call these public constructors rather than retaining a caller-owned collection. toJson returns fresh List values.

- [ ] **Step 4: Implement the fixed catalog**

Create StoryCatalog.operations as an unmodifiable list with the exact seeds, Duration(seconds: 180), directive kinds/targets, and bonuses asserted above. Add StoryCatalog.byId(StoryOperationId id) using a switch so an unknown position cannot silently select another operation.

- [ ] **Step 5: Verify catalog behavior**

Run: dart format lib/story test/story_catalog_test.dart && flutter test test/story_catalog_test.dart

Expected: PASS for the catalog, defensive-copy, rejected-mutation, structural-equality, and hash-code tests with no analyzer warnings.

- [ ] **Step 6: Commit the story foundation**

~~~bash
git add lib/story/story_models.dart lib/story/story_catalog.dart test/story_catalog_test.dart
git commit -m "feat: define signal chronicle story catalog"
~~~

### Task 3: Pure campaign transitions, directives, replay, restart, and endings

**Files:**
- Create: lib/story/campaign_controller.dart
- Create: test/campaign_controller_test.dart
- Modify: lib/story/story_models.dart

**Interfaces:**
- Consumes: StoryCatalog.byId(), StoryProgress, ProfileRewardLedger, BattleReport.
- Produces: CampaignTransition and CampaignController.conclude(), chooseEnding(), restart(), directiveProgress(), and directiveSucceeded().

- [ ] **Step 1: Write failing boundary and idempotency tests**

Create test/campaign_controller_test.dart with table-driven reports for all five directives:

~~~dart
void main() {
  const controller = CampaignController();

  test('directive thresholds pass at the exact boundary', () {
    final reports = <StoryOperationId, BattleReport>{
      StoryOperationId.wake: report(link: 45),
      StoryOperationId.echo: report(relays: 2),
      StoryOperationId.split: report(commandKills: 3),
      StoryOperationId.crown: report(rank: 2),
      StoryOperationId.lastInstruction: report(winner: Faction.amethyst),
    };
    for (final entry in reports.entries) {
      expect(
        controller.directiveSucceeded(
          operation: StoryCatalog.byId(entry.key),
          report: entry.value,
          campaignFaction: Faction.amethyst,
        ),
        isTrue,
      );
    }
  });

  test('OP-04 rank progress uses lower-is-better polarity', () {
    final operation = StoryCatalog.byId(StoryOperationId.crown);
    for (final rank in const [1, 2]) {
      final battleReport = report(rank: rank);
      final progress = controller.directiveProgress(
        operation: operation,
        report: battleReport,
        campaignFaction: Faction.amethyst,
      );
      expect(progress.current, rank.toDouble());
      expect(progress.target, 2);
      expect(progress.completed, isTrue, reason: 'rank $rank must pass');
      expect(
        controller.directiveSucceeded(
          operation: operation,
          report: battleReport,
          campaignFaction: Faction.amethyst,
        ),
        isTrue,
      );
    }
    for (final rank in const [3, 4]) {
      final battleReport = report(rank: rank);
      final progress = controller.directiveProgress(
        operation: operation,
        report: battleReport,
        campaignFaction: Faction.amethyst,
      );
      expect(progress.completed, isFalse, reason: 'rank $rank must miss');
      expect(
        controller.directiveSucceeded(
          operation: operation,
          report: battleReport,
          campaignFaction: Faction.amethyst,
        ),
        isFalse,
      );
    }
  });

  test('loss advances story while a missed directive pays nothing', () {
    final transition = controller.conclude(
      progress: StoryProgress.initial().lockCore(Faction.amethyst),
      ledger: ProfileRewardLedger.empty(),
      operationId: StoryOperationId.wake,
      report: report(reason: ChronicleEndReason.playerEliminated, link: 44.999),
      replay: false,
    );
    expect(transition.nextProgress.currentOperation, StoryOperationId.echo);
    expect(transition.directiveSucceeded, isFalse);
    expect(transition.directiveBonusCredit, 0);
  });

  test('duplicate and replay conclusions never repay a claimed bonus', () {
    final first = controller.conclude(
      progress: StoryProgress.initial().lockCore(Faction.amethyst),
      ledger: ProfileRewardLedger.empty(),
      operationId: StoryOperationId.wake,
      report: report(link: 45),
      replay: false,
    );
    final duplicate = controller.conclude(
      progress: first.nextProgress,
      ledger: first.nextLedger,
      operationId: StoryOperationId.wake,
      report: report(link: 60),
      replay: true,
    );
    expect(first.directiveBonusCredit, 15);
    expect(duplicate.directiveBonusCredit, 0);
    expect(duplicate.nextProgress.currentOperation, StoryOperationId.echo);
  });
}
~~~

Add the local report() fixture with four ordered FactionStanding values; winner defaults to null, rank defaults to 4, survivors default to 0, and its arguments map one-for-one to BattleReport fields.

- [ ] **Step 2: Run the focused tests and confirm RED**

Run: flutter test test/campaign_controller_test.dart

Expected: FAIL because CampaignController and CampaignTransition do not exist. A generic current >= target implementation would also be rejected by the OP-04 test because it incorrectly fails rank 1 and passes ranks 3 and 4.

- [ ] **Step 3: Implement the pure transition API**

Add this public shape:

~~~dart
final class CampaignTransition {
  const CampaignTransition({
    required this.nextProgress,
    required this.nextLedger,
    required this.directiveSucceeded,
    required this.directiveBonusCredit,
    required this.firstConclusion,
  });
  final StoryProgress nextProgress;
  final ProfileRewardLedger nextLedger;
  final bool directiveSucceeded;
  final int directiveBonusCredit;
  final bool firstConclusion;
}

final class CampaignController {
  const CampaignController();
  CampaignTransition conclude({
    required StoryProgress progress,
    required ProfileRewardLedger ledger,
    required StoryOperationId operationId,
    required BattleReport report,
    required bool replay,
  });
  DirectiveProgress directiveProgress({
    required StoryOperation operation,
    required BattleReport report,
    required Faction campaignFaction,
  });
  bool directiveSucceeded({
    required StoryOperation operation,
    required BattleReport report,
    required Faction campaignFaction,
  });
  StoryProgress chooseEnding(StoryProgress progress, EndingChoice choice);
  StoryProgress restart(StoryProgress progress);
}
~~~

Implement directiveProgress and make directiveSucceeded delegate to its completed result:

~~~dart
DirectiveProgress directiveProgress({
  required StoryOperation operation,
  required BattleReport report,
  required Faction campaignFaction,
}) {
  final current = switch (operation.directive.kind) {
    DirectiveKind.longestCommandLink => report.longestCommandLinkSeconds,
    DirectiveKind.commandRelays => report.commandRelays.toDouble(),
    DirectiveKind.commandKills => report.commandKills.toDouble(),
    DirectiveKind.finalRank => report.playerRank.toDouble(),
    DirectiveKind.victory =>
      report.globalWinner == campaignFaction ? 1.0 : 0.0,
  };
  return DirectiveProgress(
    kind: operation.directive.kind,
    current: current,
    target: operation.directive.target,
  );
}

bool directiveSucceeded({
  required StoryOperation operation,
  required BattleReport report,
  required Faction campaignFaction,
}) => directiveProgress(
  operation: operation,
  report: report,
  campaignFaction: campaignFaction,
).completed;
~~~

conclude must reject an unlocked first-run operation, add conclusion/transmission regardless of loss, add a medal only on success, add the bonus claim ID and credit only when absent from the lifetime ledger, and leave current progression/ending unchanged for replay. chooseEnding must throw StateError until OP-05 is concluded. restart returns StoryProgress.initial() while the caller retains the existing ledger.

- [ ] **Step 4: Add immediate-below-boundary and ending tests**

Test 44.999 seconds, 1 relay, 2 command kills, ranks 3 and 4, and null/different winner as failures. Explicitly retain ranks 1 and 2 as successes so later UI refactors cannot invert OP-04. Test that OP-05 loss still concludes and permits both endings; a second ending choice is rejected until restart; restart clears campaign core, conclusions, transmissions, medals, and ending but does not accept or return a ledger.

- [ ] **Step 5: Verify pure rules**

Run: dart format lib/story test/campaign_controller_test.dart && flutter test test/story_catalog_test.dart test/campaign_controller_test.dart

Expected: PASS; the test log proves exact boundaries including OP-04 ranks 1/2 PASS and 3/4 MISS, loss advancement, replay independence, one-time bonuses, and ending gates.

- [ ] **Step 6: Commit the rules**

~~~bash
git add lib/story/story_models.dart lib/story/campaign_controller.dart test/campaign_controller_test.dart
git commit -m "feat: implement chronicle campaign transitions"
~~~

### Task 4: Schema-2 persistence and atomic directive rewards

**Files:**
- Modify: lib/app/tokenfront_runtime.dart
- Modify: test/runtime_test.dart
- Modify: lib/story/story_models.dart

**Interfaces:**
- Consumes: CampaignController.conclude(), StoryProgress.toJson/fromJson(), ProfileRewardLedger.toJson/fromJson(), WarTokenWallet.
- Produces: TokenfrontRuntime.storyProgress, rewardLedger, concludeChronicle(), chooseChronicleEnding(), and restartChronicle().

- [ ] **Step 1: Write failing migration and atomic-credit tests**

Add to test/runtime_test.dart:

~~~dart
test('schema 1 migrates wallet preferences privacy and empty story', () async {
  final store = MemoryStateStore.withValue(schema1Fixture);
  final runtime = await TokenfrontRuntime.restore(
    platform: ClientPlatform.web,
    stateStore: store,
  );
  addTearDown(runtime.dispose);
  expect(runtime.wallet.balance, 275);
  expect(runtime.preferences.languageCode, 'ko');
  expect(runtime.analyticsSharingAllowed, isTrue);
  expect(runtime.storyProgress, StoryProgress.initial());
  expect(runtime.rewardLedger.claimedDirectiveBonusIds, isEmpty);
});

test('conclusion atomically stores medal claim and WT once', () async {
  final store = MemoryStateStore();
  final runtime = await TokenfrontRuntime.restore(
    platform: ClientPlatform.web,
    stateStore: store,
  );
  addTearDown(runtime.dispose);
  runtime.lockChronicleCore(Faction.amethyst);
  final before = runtime.wallet.balance;
  final first = runtime.concludeChronicle(
    operationId: StoryOperationId.wake,
    report: report(link: 45),
    replay: false,
  );
  final duplicate = runtime.concludeChronicle(
    operationId: StoryOperationId.wake,
    report: report(link: 45),
    replay: true,
  );
  await runtime.flushLocalState();
  expect(first.directiveBonusCredit, 15);
  expect(duplicate.directiveBonusCredit, 0);
  expect(runtime.wallet.balance, before + 15);
  expect(runtime.storyProgress.medals, contains(StoryOperationId.wake));
  expect(runtime.rewardLedger.claimedDirectiveBonusIds, contains('chronicle-directive-wake'));
});

test('malformed story preserves a separately valid lifetime ledger', () async {
  final store = MemoryStateStore.withValue(schema2WithMalformedStoryAndWakeClaim);
  final runtime = await TokenfrontRuntime.restore(
    platform: ClientPlatform.web,
    stateStore: store,
  );
  addTearDown(runtime.dispose);
  expect(runtime.storyProgress.currentOperation, StoryOperationId.wake);
  expect(
    runtime.rewardLedger.claimedDirectiveBonusIds,
    contains('chronicle-directive-wake'),
  );
});

test('malformed ledger preserves separately valid Chronicle progress', () async {
  final store = MemoryStateStore.withValue(
    schema2WithWakeConcludedAndMalformedLedger,
  );
  final runtime = await TokenfrontRuntime.restore(
    platform: ClientPlatform.web,
    stateStore: store,
  );
  addTearDown(runtime.dispose);
  expect(
    runtime.storyProgress.concludedOperations,
    contains(StoryOperationId.wake),
  );
  expect(runtime.storyProgress.currentOperation, StoryOperationId.echo);
  expect(runtime.rewardLedger.claimedDirectiveBonusIds, isEmpty);
});
~~~

Use the existing in-memory TokenfrontStateStore fixture style. Construct schema1Fixture with schemaVersion 1 and non-default wallet, cosmetic, language, accessibility, audio, camera, analytics, and ad values so every preserved field is asserted.

- [ ] **Step 2: Run the focused tests and confirm RED**

Run: flutter test test/runtime_test.dart --plain-name "schema 1 migrates wallet preferences privacy and empty story"

Expected: FAIL because schema 1 currently lacks story migration and runtime story accessors.

- [ ] **Step 3: Implement independent schema-2 decoding**

Change only the local snapshot schema from 1 to 2. Decode wallet, preferences, privacy, story, and reward ledger in separate guarded functions. For schema 1, decode all current fields and inject StoryProgress.initial() plus ProfileRewardLedger.empty(). Malformed story JSON resets only StoryProgress and preserves a separately valid ProfileRewardLedger; malformed ledger JSON resets only the ledger and preserves separately valid story and non-story values. Unknown top-level schemas keep the existing corruption fallback.

Add runtime state and methods with exact signatures:

~~~dart
StoryProgress get storyProgress;
ProfileRewardLedger get rewardLedger;
void lockChronicleCore(Faction faction);
CampaignTransition concludeChronicle({
  required StoryOperationId operationId,
  required BattleReport report,
  required bool replay,
});
void chooseChronicleEnding(EndingChoice choice);
void restartChronicle();
~~~

concludeChronicle calls CampaignController exactly once, credits transition.directiveBonusCredit directly to the wallet without using the rewarded-ad path, assigns both next states before one _schedulePersist() call, and then notifies listeners. restartChronicle changes StoryProgress only.

- [ ] **Step 4: Add round-trip, malformed-story, relaunch, and restart coverage**

Test schema-2 round trip of campaign core, conclusions, medals, transmissions, ending, and ledger. Run both independent corruption fixtures: malformed story preserves valid wallet/preferences/privacy/ledger, and malformed ledger preserves valid wallet/preferences/privacy/story. Test flush/recreate restores the first incomplete operation. Test restart and a second successful OP-01 restore the medal but credit zero WT because the lifetime claim remains.

- [ ] **Step 5: Verify persistence**

Run: dart format lib/app/tokenfront_runtime.dart lib/story/story_models.dart test/runtime_test.dart && flutter test test/runtime_test.dart test/economy_test.dart test/game_preferences_test.dart

Expected: PASS with no duplicate credit and all prior economy/preference tests green.

- [ ] **Step 6: Commit persistence**

~~~bash
git add lib/app/tokenfront_runtime.dart lib/story/story_models.dart test/runtime_test.dart
git commit -m "feat: persist chronicle progress and reward ledger"
~~~

### Task 5: Battle metrics and deterministic BattleReport

**Files:**
- Modify: lib/game/tokenfront_game.dart
- Modify: lib/game/simulation.dart
- Create: test/chronicle_metrics_test.dart
- Modify: test/battle_accessibility_input_test.dart
- Modify: test/performance_test.dart

**Interfaces:**
- Consumes: GameMode, StoryOperation, BattleReport, DirectiveProgress, BattleSimulation.frameCombatEvents, handoffLog, standings().
- Produces: TokenfrontGame.onBattleConcluded(BattleReport), BattleHudSnapshot.directiveProgress, and immediate Chronicle player-elimination conclusion.

- [ ] **Step 1: Write failing metric tests**

Create test/chronicle_metrics_test.dart. Use a tiny BattleConfig for event control and assert:

~~~dart
test('command kills use controlled ID captured before the step', () {
  final harness = ChronicleGameHarness(operation: StoryCatalog.byId(StoryOperationId.split));
  final commandedId = harness.game.simulation.controlledUnitId;
  harness.resolveKillBy(unitId: commandedId!);
  harness.game.update(1 / 30);
  expect(harness.game.commandKills, 1);
});

test('completed handoffs count and failed handoffs do not', () {
  final harness = ChronicleGameHarness(operation: StoryCatalog.byId(StoryOperationId.echo));
  harness.completeHandoff();
  harness.failHandoffByEliminatingFaction();
  expect(harness.game.commandRelays, 1);
});

test('player elimination reports standings without finishing simulation', () {
  final harness = ChronicleGameHarness(operation: StoryCatalog.byId(StoryOperationId.wake));
  harness.eliminatePlayerFaction();
  harness.game.update(1 / 30);
  expect(harness.reports.single.endReason, ChronicleEndReason.playerEliminated);
  expect(harness.game.simulation.result, isNull);
  expect(harness.game.simulation.finished, isFalse);
});
~~~

The harness is a test-only class in the same file that receives onBattleConcluded into a List<BattleReport> and manipulates existing Unit state/combat events without adding production debug APIs.

- [ ] **Step 2: Run the metric tests and confirm RED**

Run: flutter test test/chronicle_metrics_test.dart

Expected: FAIL because TokenfrontGame does not expose Chronicle operation/report metrics.

- [ ] **Step 3: Refactor the game constructor and counters**

Replace onMatchEnded with:

~~~dart
TokenfrontGame({
  required Faction playerFaction,
  required void Function(BattleReport report) onBattleConcluded,
  GameMode mode = GameMode.skirmish,
  StoryOperation? operation,
  int seed = 20260715,
  BattleConfig config = const BattleConfig(),
  // existing visual, input, audio, and handoff arguments remain
}) : assert(mode == GameMode.skirmish || operation != null);
~~~

Capture simulation.controlledUnitId before each simulation.step. Iterate only frameCombatEvents and count an event when its winnerUnitId equals that captured ID. Increment commandRelays only from the existing successful handoff completion callback. Accumulate current/longest command-link duration from simulation delta while the same commanded unit remains alive; preserve max then reset when the ID changes. Publish DirectiveProgress through BattleHudSnapshot at the existing standard/low-spec cadence.

- [ ] **Step 4: Produce exactly one conclusion report**

For Chronicle, conclude on player-faction elimination, global resolution, or the 180-second simulation limit. If the limit arrives during a handoff presentation, defer report creation until the existing successful/failed handoff callback completes. For Skirmish, preserve current global/time-limit completion and spectator behavior. Build rank from the standings list index and playerSurvivors from its faction entry. At time limit, globalWinner is the unique deterministic MatchResult/rank winner even when multiple factions still have survivors; at global elimination it is the sole surviving faction; it is null on a tied time-limit result or player-elimination snapshot that has not globally resolved.

- [ ] **Step 5: Prove metrics and performance**

Run:

~~~bash
dart format lib/game/tokenfront_game.dart lib/game/simulation.dart test/chronicle_metrics_test.dart
flutter test test/chronicle_metrics_test.dart test/battle_accessibility_input_test.dart test/performance_test.dart
~~~

Expected: PASS; performance tests show 4,000 units, fixed 30 Hz, existing culling/batching/far-AI counters, and no new full-unit pass in TokenfrontGame.update.

- [ ] **Step 6: Commit battle reporting**

~~~bash
git add lib/game/tokenfront_game.dart lib/game/simulation.dart test/chronicle_metrics_test.dart test/battle_accessibility_input_test.dart test/performance_test.dart
git commit -m "feat: report chronicle directive metrics"
~~~

### Task 6: TokenfrontRoot mode flow, rewards, and tutorial boundary

**Files:**
- Modify: lib/main.dart
- Modify: lib/ui/lobby_screen.dart
- Modify: lib/ui/result_screen.dart
- Modify: lib/l10n/app_en.arb
- Modify: lib/l10n/app_ko.arb
- Modify: lib/l10n/app_ja.arb
- Modify: lib/l10n/app_zh.arb
- Regenerate: lib/l10n/app_localizations.dart
- Regenerate: lib/l10n/app_localizations_en.dart
- Regenerate: lib/l10n/app_localizations_ko.dart
- Regenerate: lib/l10n/app_localizations_ja.dart
- Regenerate: lib/l10n/app_localizations_zh.dart
- Modify: test/widget_test.dart
- Modify: test/services_test.dart

**Interfaces:**
- Consumes: StoryCatalog, TokenfrontRuntime story API, TokenfrontGame onBattleConcluded, BattleReport.
- Produces: Chronicle briefing/battle/debrief routing, archive replay context, Skirmish routing, and base reward claim separated from directive credit.

- [ ] **Step 1: Write failing flow tests**

Add widget tests that tap CHRONICLE, select AMETHYST, deploy OP-01, force player elimination, and assert ResultScreen plus OP-02 after continue. Add a second test that starts SKIRMISH, eliminates the player faction, and asserts BattleScreen remains for spectating. Change the analytics test to assert tutorial_completed is absent on deploy and present exactly once after the first OP-01 report.

Add this construction-failure regression:

~~~dart
testWidgets('Chronicle construction failure keeps Skirmish deployable', (tester) async {
  final runtime = TokenfrontRuntime(platform: ClientPlatform.web);
  addTearDown(runtime.dispose);
  await tester.pumpWidget(
    TokenfrontApp(
      runtime: runtime,
      storyOperationsProvider: () => throw StateError('catalog unavailable'),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('CHRONICLE UNAVAILABLE'), findsOneWidget);
  expect(find.byKey(const Key('chronicle-deploy-disabled')), findsOneWidget);
  await tester.tap(find.byKey(const Key('skirmish-deploy')));
  await tester.pump();
  expect(find.byType(BattleScreen), findsOneWidget);
  expect(tester.takeException(), isNull);
});
~~~

- [ ] **Step 2: Run the flow tests and confirm RED**

Run: flutter test test/widget_test.dart --plain-name "Chronicle construction failure keeps Skirmish deployable"

Expected: FAIL to compile because storyOperationsProvider and the unavailable/deploy keys do not exist.

- [ ] **Step 3: Add explicit root contexts**

Use:

~~~dart
typedef StoryOperationsProvider = Iterable<StoryOperation> Function();

enum _Screen { lobby, briefing, battle, result }

final class _ActiveBattle {
  const _ActiveBattle({
    required this.mode,
    required this.faction,
    required this.matchId,
    this.operation,
    this.replay = false,
  });
  final GameMode mode;
  final Faction faction;
  final String matchId;
  final StoryOperation? operation;
  final bool replay;
}
~~~

Add nullable StoryOperationsProvider storyOperationsProvider to TokenfrontApp and TokenfrontRoot and forward it unchanged. In TokenfrontRoot init, resolve the provider as List<StoryOperation>.unmodifiable((storyOperationsProvider ?? () => StoryCatalog.operations)()) so later caller mutation cannot change the active catalog. Treat only StateError and FormatException as story construction/lookup failure; rethrow every other error so BattleSimulation and Skirmish faults are never hidden. Store chronicleAvailable = false for those two story failures.

Chronicle config is BattleConfig(matchLimitSeconds: operation.duration.inSeconds.toDouble()) with operation.seed. Skirmish uses const BattleConfig() and the existing incrementing seed. Lock the campaign core only when fresh OP-01 begins; Archive replay uses the locked core. Skirmish selection never changes the campaign core.

When chronicleAvailable is false, render a disabled control keyed chronicle-deploy-disabled and an enabled Skirmish control keyed skirmish-deploy. Add the exact localized values and regenerate localization code:

~~~text
EN: CHRONICLE UNAVAILABLE
KO: 시그널 크로니클 이용 불가
JA: シグナル・クロニクル利用不可
ZH: 信号编年史暂不可用
~~~

Do not create partial operations or fall back to different seeds. Archive story actions remain disabled, while settings, locker, and Skirmish remain functional.

- [ ] **Step 4: Separate base and directive rewards**

Calculate the existing base formula from BattleReport: 40 + commandRelays * 8 + playerStanding.kills ~/ 5. Claim it for every concluded Chronicle attempt and every completed Skirmish. Then call runtime.concludeChronicle for Chronicle; never pass its directive bonus into claimBaseReward or claimRewardedBonus. Use stable match IDs containing mode, operation ID when present, seed, and an incrementing attempt number.

- [ ] **Step 5: Correct tutorial analytics**

Keep tutorial_started on app start. Remove tutorial_completed from startMatch. Record tutorial_completed only when OP-01 changes from unconcluded to concluded; do not record it on replay, Skirmish, or duplicate callback. Add no Chronicle-specific analytics names.

- [ ] **Step 6: Verify flow and commit**

Run: flutter gen-l10n && dart format lib/main.dart lib/ui/lobby_screen.dart lib/ui/result_screen.dart test/widget_test.dart && flutter test test/widget_test.dart test/services_test.dart test/economy_test.dart

Expected: PASS for loss advancement, spectator preservation, base reward on Chronicle elimination, non-doubled directive bonus, corrected tutorial event, and a catalog failure that renders CHRONICLE UNAVAILABLE while Skirmish deploys.

~~~bash
git add lib/main.dart lib/ui/lobby_screen.dart lib/ui/result_screen.dart lib/l10n/app_en.arb lib/l10n/app_ko.arb lib/l10n/app_ja.arb lib/l10n/app_zh.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_ko.dart lib/l10n/app_localizations_ja.dart lib/l10n/app_localizations_zh.dart test/widget_test.dart test/services_test.dart
git commit -m "feat: coordinate chronicle and skirmish flows"
~~~

### Task 7: Four-locale story copy and stable presentation mapping

**Files:**
- Create: lib/story/story_localizations.dart
- Modify: lib/l10n/app_en.arb
- Modify: lib/l10n/app_ko.arb
- Modify: lib/l10n/app_ja.arb
- Modify: lib/l10n/app_zh.arb
- Regenerate: lib/l10n/app_localizations.dart
- Regenerate: lib/l10n/app_localizations_en.dart
- Regenerate: lib/l10n/app_localizations_ko.dart
- Regenerate: lib/l10n/app_localizations_ja.dart
- Regenerate: lib/l10n/app_localizations_zh.dart
- Modify: test/localization_test.dart

**Interfaces:**
- Consumes: StoryOperationId, DirectiveKind, EndingChoice, Faction.visual.name.
- Produces: StoryLocalizations operationTitle(), briefing(), transmission(), response(), directiveLabel(), endingLabel(), and endingEpilogue().

- [ ] **Step 1: Write failing key-completeness tests**

For each AppLocalizations.supportedLocales, pump Localizations and assert every StoryOperationId returns non-empty title, briefing, fragment, and response; every DirectiveKind returns a label; both endings return labels and epilogues. Assert English prologue exactly:

~~~text
The surface has been silent for 72 years. You are a command signal without a body. The Last Relay is calling.
~~~

Assert the localized product contracts:

~~~text
EN | Tokenfront: Orbital Signal War | FOUR AI CORES. ONE LAST RELAY. | DEPLOY TO ORBIT
KO | Tokenfront: 궤도 신호전 | 네 AI 코어. 단 하나의 최후 릴레이. | 궤도 투입
JA | Tokenfront: 軌道信号戦 | 4つのAIコア。最後のリレーは1つ。 | 軌道へ展開
ZH | Tokenfront：轨道信号战 | 四个AI核心，最后一座中继站。 | 部署至轨道
~~~

- [ ] **Step 2: Run localization generation/test and confirm RED**

Run: flutter gen-l10n && flutter test test/localization_test.dart

Expected: FAIL because Chronicle keys and StoryLocalizations do not exist.

- [ ] **Step 3: Add source-locale keys with exact English narrative**

Add the named key chroniclePrologue with the exact approved English sentence, then add keys for chronicle, skirmish, archive, restart, briefing, directive, debrief, ending controls; the five operation titles, the five briefings and responses from the approved Signal Chronicle design; these fragments:

~~~text
KEEP THE LINK—
—WHEN ONE BODY FALLS, MOVE—
—FOUR CORES, ONE ROOT—
—THE WINNER ERASES THE REST—
—DO NOT CHOOSE ONE. OPEN THE RELAY.
~~~

Add protocol/identity keys for ARCHIVE, BASTION, SURGE, MIRROR and their approved identity lines. Add exact ending epilogues, DIRECTIVE LOCKED // BONUS READY, DIRECTIVE MISSED, BONUS CLAIMED, ARCHIVE SIMULATION // NON-CANONICAL, CHRONICLE UNAVAILABLE, RETRY DIRECTIVE, CONTINUE, and COMMAND DECK. Only coreResponse(String coreName) uses an ICU String placeholder; operation number, threshold, rank, and WT are passed as data.

- [ ] **Step 4: Add Korean, Japanese, and Simplified Chinese values**

Use professional in-universe translations with the same rule meaning. The following rule-bearing strings are fixed:

~~~text
KO: 지휘 연결 45초 유지 | 지휘권 인계 2회 완료 | 직접 지휘 처치 3회 | 2위 이상으로 종료 | 단독 승리
JA: 指揮リンクを45秒維持 | 指揮引き継ぎを2回完了 | 直接指揮で3体撃破 | 2位以内で終了 | 単独勝利
ZH: 保持指挥链路45秒 | 完成2次指挥交接 | 直接指挥击破3个单位 | 以第2名或更高名次结束 | 单独获胜
~~~

Use these ending labels:

~~~text
KO: 릴레이 장악 | 릴레이 개방
JA: リレーを掌握 | リレーを開放
ZH: 接管中继站 | 开放中继站
~~~

Preserve OP-01 through OP-05, 45, 2, 3, rank 2, and WT values as data in all locales.

- [ ] **Step 5: Implement exhaustive enum-to-key mapping and regenerate**

StoryLocalizations must use exhaustive switch expressions for every enum and never index translated arrays. Run flutter gen-l10n; do not hand-edit generated Dart.

- [ ] **Step 6: Verify all locales and commit**

Run:

~~~bash
dart format lib/story/story_localizations.dart test/localization_test.dart
flutter gen-l10n
flutter test test/localization_test.dart
~~~

Expected: PASS for EN/KO/JA/ZH completeness, exact rule meaning, source-title contracts, and missing-localization loud failure.

~~~bash
git add lib/story/story_localizations.dart lib/l10n/app_en.arb lib/l10n/app_ko.arb lib/l10n/app_ja.arb lib/l10n/app_zh.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_ko.dart lib/l10n/app_localizations_ja.dart lib/l10n/app_localizations_zh.dart test/localization_test.dart
git commit -m "feat: localize signal chronicle story"
~~~

### Task 8: Command Deck, broken orbital ring, and Archive

**Files:**
- Create: lib/ui/orbital_progress_ring.dart
- Create: lib/ui/archive_sheet.dart
- Modify: lib/ui/lobby_screen.dart
- Modify: lib/main.dart
- Modify: test/widget_test.dart
- Modify: test/localization_test.dart

**Interfaces:**
- Consumes: StoryProgress, ProfileRewardLedger, StoryCatalog, StoryLocalizations, callbacks supplied by TokenfrontRoot.
- Produces: LobbyScreen Chronicle/Skirmish/Archive actions, OrbitalProgressRing, showSignalArchive(), replay and restart callbacks.

- [ ] **Step 1: Write failing Command Deck and Archive tests**

Add this fresh-profile assertion before selecting a core:

~~~dart
const prologue =
    'The surface has been silent for 72 years. '
    'You are a command signal without a body. '
    'The Last Relay is calling.';
expect(find.text(prologue), findsOneWidget);
expect(
  tester.getTopLeft(find.text(prologue)).dy,
  lessThan(tester.getTopLeft(find.text('AMETHYST')).dy),
);
~~~

In the same test, assert OP-01, all four cores, CHRONICLE, SKIRMISH, ARCHIVE, a five-node semantics label, and DEPLOY OP-01. Test core locks after OP-01 begins while Skirmish still selects freely. Pump 320x568 and assert no overflow. Open Archive and assert locked entries reveal only OP numbers; concluded entries reveal transmissions/medals/bonus claim; replay leaves current operation and ending unchanged.

- [ ] **Step 2: Run focused widget tests and confirm RED**

Run: flutter test test/widget_test.dart --plain-name "fresh Command Deck shows prologue before core selection"

Expected: FAIL because the exact prologue is not rendered before the core cards.

- [ ] **Step 3: Implement the lobby view contract**

Change LobbyScreen to receive immutable values and callbacks:

~~~dart
const LobbyScreen({
  required GameMode selectedMode,
  required StoryProgress storyProgress,
  required ProfileRewardLedger rewardLedger,
  required Faction selectedSkirmishFaction,
  required ValueChanged<Faction> onSelectChronicleCore,
  required ValueChanged<Faction> onSelectSkirmishFaction,
  required VoidCallback onDeployChronicle,
  required VoidCallback onDeploySkirmish,
  required VoidCallback onOpenArchive,
  required int warTokenBalance,
  required VoidCallback onOpenSettings,
  required VoidCallback onOpenLocker,
  required bool bannerVisible,
});
~~~

Make current operation the primary hierarchy. When storyProgress.campaignFaction is null, render context.l10n.chroniclePrologue directly above the four Chronicle core cards and before the first focusable core control. After the campaign core locks, replace that prologue position with the current operation briefing; never render both blocks simultaneously. Render the faction protocol and identity but never imply asymmetric powers. Chronicle core cards become read-only after lock; Skirmish mode remains selectable.

- [ ] **Step 4: Implement the progress ring and Archive**

OrbitalProgressRing paints one broken ring with exactly five nodes/segments, ignores pointers, and exposes one combined semantics label. It disables animation for low-spec/reduced-motion. ArchiveSheet lists five stable states: concluded/current/locked, recovered transmission, medal, BONUS CLAIMED or available, and replay only for concluded IDs. After ending, show the stored epilogue and ARCHIVE SIMULATION // NON-CANONICAL.

Restart confirmation must state that campaign core, progress, transmissions, medals, and ending reset; wallet/settings/cosmetics remain; paid operation bonuses cannot be earned again. Confirm calls runtime.restartChronicle and returns to OP-01 core selection.

- [ ] **Step 5: Verify responsive/focus behavior**

Run:

~~~bash
flutter test test/widget_test.dart test/localization_test.dart
flutter test test/widget_test.dart --plain-name "Command Deck and Archive fit 320x568"
~~~

Expected: PASS with no RenderFlex overflow, all actions keyboard reachable, locked silhouettes not focusable, and one ring semantics announcement.

- [ ] **Step 6: Commit Command Deck**

~~~bash
git add lib/ui/orbital_progress_ring.dart lib/ui/archive_sheet.dart lib/ui/lobby_screen.dart lib/main.dart test/widget_test.dart test/localization_test.dart
git commit -m "feat: add chronicle command deck and archive"
~~~

### Task 9: Directive rail, debrief, replay actions, and endings

**Files:**
- Modify: lib/ui/battle_screen.dart
- Modify: lib/ui/result_screen.dart
- Modify: lib/main.dart
- Modify: test/battle_accessibility_input_test.dart
- Modify: test/widget_test.dart

**Interfaces:**
- Consumes: BattleHudSnapshot.directiveProgress, CampaignTransition, StoryOperation, BattleReport, StoryLocalizations.
- Produces: live directive rail, two-second locked cue, story debrief, Continue/Retry/Command Deck actions, and final ending choice.

- [ ] **Step 1: Write failing rail/debrief tests**

Add tests that pump progress 1/3 and expect DIRECTIVE // COMMAND KILLS 1 / 3; update to 3/3 and expect DIRECTIVE LOCKED // BONUS READY for two seconds without focus change. Count SemanticsService announcements and assert only operation start, applicable midpoint, and completion are announced. Add result tests for success, failure, replay BONUS CLAIMED, and OP-05 ending choice after both win and loss.

- [ ] **Step 2: Run focused tests and confirm RED**

Run: flutter test test/battle_accessibility_input_test.dart --plain-name "directive rail announces milestones without tick spam"

Expected: FAIL because BattleScreen does not render directive progress.

- [ ] **Step 3: Implement the non-interactive directive rail**

Place the rail immediately below the current top command rail. It reads BattleHudSnapshot only, uses IgnorePointer and ExcludeSemantics around animated decoration, and exposes a stable live-region label only when milestone state changes. Completion starts a two-second visual cue; reduced motion/low-spec switches immediately to the completed text with no animation.

- [ ] **Step 4: Implement debrief and ending choice**

ResultScreen renders in this order: TRANSMISSION RECOVERED and title, fragment, localized core response, directive/medal/bonus status, faction standings, base reward, and actions. First-run CONTINUE advances to the next briefing; replay returns to Archive. RETRY DIRECTIVE starts the same fixed seed and never changes sequential progress. After the first OP-05 conclusion, require CLAIM THE RELAY or OPEN THE RELAY, persist it, and show its epilogue. Ending changes copy only.

- [ ] **Step 5: Preserve controls and reward behavior**

Pump 568x320 and 844x390. Assert the 104 dp joystick, 72 dp dash, minimap, directive rail, pause button, and safe-area layout do not overlap. Assert rewarded doubling changes only base reward and directive bonus remains exactly its catalog value.

- [ ] **Step 6: Verify and commit presentation**

Run: dart format lib/ui/battle_screen.dart lib/ui/result_screen.dart lib/main.dart test/battle_accessibility_input_test.dart test/widget_test.dart && flutter test test/battle_accessibility_input_test.dart test/widget_test.dart

Expected: PASS for progress, accessibility milestones, success/failure debrief, replay, both endings, reward separation, and mobile layouts.

~~~bash
git add lib/ui/battle_screen.dart lib/ui/result_screen.dart lib/main.dart test/battle_accessibility_input_test.dart test/widget_test.dart
git commit -m "feat: present chronicle directives and debrief"
~~~

### Task 10: Lifecycle regression fix and Android release handoff

**Files:**
- Modify: integration_test/app_smoke_test.dart
- Modify: lib/ui/battle_screen.dart
- Modify: lib/main.dart
- Modify: test/widget_test.dart

**Interfaces:**
- Consumes: WidgetsBindingObserver lifecycle callbacks and BattleScreen pause state.
- Produces: deterministic pause overlay lifecycle, safe disposal/focus behavior, and a green integration scenario for the Android production-release plan to re-run on its owned API 36 emulator and physical device.

- [ ] **Step 1: Preserve the verified failing scenario as a regression test**

Keep the existing Android sequence at integration_test/app_smoke_test.dart:36: enter battle, send paused, pump, expect SIGNAL HELD / BATTLE PAUSED, send resumed, pump, expect it removed. Add a final pumpAndSettle before teardown and assert tester.takeException() is null.

- [ ] **Step 2: Reproduce RED on Android**

Run: flutter test integration_test/app_smoke_test.dart -d emulator-5554

Expected: FAIL at line 36 because the pause overlay is absent, followed by a FocusManager used after disposal exception. If the device ID differs, obtain the connected Android ID from flutter devices and run the same command with that exact ID.

- [ ] **Step 3: Fix lifecycle ownership**

Ensure one mounted State owns WidgetsBindingObserver registration and forwards paused/inactive/resumed to BattleScreen. BattleScreen stores paused state, blocks game input/update while paused, renders the localized overlay, and removes its focus/listener callbacks before disposing the FocusNode/game reference. Guard every async orientation/pause callback with mounted and active game identity.

- [ ] **Step 4: Verify PASS on Android and widget runner**

Run:

~~~bash
flutter test test/widget_test.dart --plain-name "battle pauses and resumes without disposed focus callbacks"
flutter test integration_test/app_smoke_test.dart -d emulator-5554
~~~

Expected: PASS; overlay appears and disappears in order and no FocusManager exception is logged. This emulator run verifies the implementation slice only; it is not the Android 16 or physical-device release acceptance.

- [ ] **Step 5: Hand the green regression to the Android production plan**

Record in the implementation handoff that the Android production-release plan Task 5 must run this same integration test on its API 36 emulator and physical device, then own joystick, 72 dp dash, pause/resume, background/resume, handoff, Chronicle elimination-to-debrief, Archive scroll, landscape controls, device model/API, and release evidence. Do not duplicate that physical-device evidence in this plan.

- [ ] **Step 6: Commit the regression fix**

~~~bash
git add integration_test/app_smoke_test.dart lib/ui/battle_screen.dart lib/main.dart test/widget_test.dart
git commit -m "fix: stabilize Android battle lifecycle"
~~~

### Task 11: Blender orbital key art and runtime backdrop

**Files:**
- Modify: tooling/build_tokenfront_scene.py
- Regenerate: assets/blender/tokenfront_arena.blend
- Regenerate: assets/blender/tokenfront_arena.glb
- Regenerate: assets/blender/tokenfront_keyart.png
- Modify: lib/game/tokenfront_game.dart
- Modify: test/token_atlas_test.dart
- Modify: test/widget_test.dart

**Interfaces:**
- Consumes: existing Blender MCP helper and existing key-art fallback.
- Produces: canonical 1440x900 orbital plotting-table render with Last Relay beacon, broken arcs, four neutral signal colors, and non-interactive runtime backdrop.

- [ ] **Step 1: Write failing asset/runtime assertions**

Assert the key art decodes at exactly 1440x900 and the scene script contains named objects LastRelayBeacon, BrokenOrbitArc01, BrokenOrbitArc02, BrokenOrbitArc03, PlanetaryLimb, SignalNodeAmethyst, SignalNodeCobalt, SignalNodeVolt, and SignalNodePrism. Add a widget/game test proving the backdrop layer is below units and ignores hit testing/semantics.

- [ ] **Step 2: Run tests and confirm RED**

Run: flutter test test/token_atlas_test.dart test/widget_test.dart --plain-name "orbital key art keeps the tactical asset contract"

Expected: FAIL because the named orbital scene elements are absent.

- [ ] **Step 3: Extend the canonical Blender build script**

In tooling/build_tokenfront_scene.py, create a central low-emission relay beacon, three broken concentric curve arcs, four small colored signal nodes using existing faction palette values, and one restrained planetary limb/void falloff. Keep the top-down camera, four swarms, relay tape, existing atlas, and 1440x900 output. Do not add ships, projectiles, capture mechanics, logos, or dense star fields.

- [ ] **Step 4: Regenerate through Blender MCP**

Run the repository helper exactly as documented:

~~~bash
python3 tooling/blender_mcp_call.py --code-file tooling/build_tokenfront_scene.py --user-prompt "Rebuild the approved Orbital Signal War scene and render the canonical key art."
~~~

Then save the canonical blend, export GLB, and render assets/blender/tokenfront_keyart.png from the same scene. If Blender MCP is unavailable, stop this task; do not synthesize a substitute image.

- [ ] **Step 5: Verify asset and fallback**

Run: flutter test test/token_atlas_test.dart test/widget_test.dart && flutter build web --release

Expected: PASS; art is 1440x900, visual elements are below interaction layers, missing-art test still shows the dark tactical fallback, and the release-mode feature-preview build contains the generated key art.

- [ ] **Step 6: Commit art**

~~~bash
git add tooling/build_tokenfront_scene.py assets/blender/tokenfront_arena.blend assets/blender/tokenfront_arena.glb assets/blender/tokenfront_keyart.png lib/game/tokenfront_game.dart test/token_atlas_test.dart test/widget_test.dart
git commit -m "feat: render the last relay orbital arena"
~~~

### Task 12: End-to-end campaign, regression, performance, and interim Cloudflare preview

**Files:**
- Modify: integration_test/app_smoke_test.dart
- Modify: test/performance_test.dart
- Modify: tooling/performance_profile_app.dart
- Modify: docs/completion-audit.md
- Modify: README.md

**Interfaces:**
- Consumes: all preceding public interfaces.
- Produces: automated five-operation evidence, regression/performance evidence, a release-mode Web feature build, and an explicitly interim tokenfront-orbital-war.pages.dev preview. The privacy/Play publishing plan Task 7 later replaces it with the final privacy-complete source-parity deployment.

- [ ] **Step 1: Add failing integration scenarios**

Add deterministic tests for:

~~~text
fresh state -> choose core -> conclude OP-01 -> flush/recreate -> OP-02
player eliminated -> debrief -> next operation without medal
directive success -> one bonus -> replay -> zero duplicate bonus
directive locked -> process ends before conclusion -> no progress/medal/bonus
directive locked -> player elimination -> one progress/medal/bonus transition
five concluded attempts -> choose OPEN -> flush/recreate -> Archive epilogue
OP-05 loss -> ending choice unlocked
all four cores x all five fixed seeds -> deterministic BattleReport
Skirmish -> 900 seconds, spectator, ranking, handoff, existing base reward
~~~

Use test-only runtime stores and direct deterministic report/simulation hooks; do not reduce production unit count or duration.

- [ ] **Step 2: Run integration/domain suites and confirm RED**

Run: flutter test integration_test/app_smoke_test.dart test/campaign_controller_test.dart test/runtime_test.dart

Expected: FAIL until all new end-to-end scenarios are wired.

- [ ] **Step 3: Complete only missing wiring exposed by the scenarios**

Fix the exact failed boundary in its owning module. Keep Skirmish defaults unchanged, do not add new services, and do not bypass runtime persistence/reward APIs in tests.

- [ ] **Step 4: Run the complete quality gate**

Run:

~~~bash
dart format --output=none --set-exit-if-changed lib test integration_test tooling
flutter gen-l10n
flutter analyze
flutter test
flutter test integration_test/app_smoke_test.dart -d emulator-5554
flutter build web --release
~~~

Expected: formatter exits 0; analyzer reports No issues found; all tests pass with only the documented Web-only skip when its platform condition applies; the implementation-level Android emulator integration passes; the release-mode Web feature-preview build succeeds. API 36/physical Android acceptance remains owned by the Android production-release plan Task 5.

- [ ] **Step 5: Run performance and hands-on Web QA**

Run the established performance profile at 4,000 units and fixed 30 Hz, then inspect desktop, 320x568 portrait, 568x320 landscape, and 844x390 landscape. Verify keyboard, mouse, joystick in all directions, dash, pause, five operation flows, elimination debrief, Archive, restart warning, both endings, relaunch persistence, reduced motion, low-spec, and screen-reader focus. Record measured FPS/culling/batch results and screenshots in docs/completion-audit.md.

- [ ] **Step 6: Build and deploy the exact interim preview artifact**

Record a pre-deploy digest:

~~~bash
find build/web -type f -print0 | sort -z | xargs -0 shasum -a 256 > /tmp/tokenfront-orbital-war-build.sha256
npx wrangler pages deploy build/web --project-name tokenfront-orbital-war
~~~

Expected: Wrangler reports a successful deployment for project tokenfront-orbital-war. Add Status: INTERIM FEATURE PREVIEW — PRIVACY REDEPLOY REQUIRED to docs/completion-audit.md. Do not issue any delete command for tokenfront-ai-arena, and do not describe this deployment as the final release.

- [ ] **Step 7: Verify the interim preview URL and artifact identity**

Run:

~~~bash
curl --fail-with-body --silent https://tokenfront-orbital-war.pages.dev/ > /tmp/tokenfront-orbital-war-index.html
rg -n "Tokenfront: Orbital Signal War" /tmp/tokenfront-orbital-war-index.html
curl --fail-with-body --silent https://tokenfront-orbital-war.pages.dev/manifest.json > /tmp/tokenfront-orbital-war-manifest.json
rg -n "Tokenfront: Orbital Signal War" /tmp/tokenfront-orbital-war-manifest.json
~~~

Expected: both curl commands return HTTP success and both files contain the new title. Use the Wrangler deployment output to compare the uploaded build with the digest recorded before deployment; store the preview URL, timestamp, deployment ID, digest, and interim status in docs/completion-audit.md. The privacy/Play publishing plan Task 7 must rebuild after the in-app privacy surface exists, prove AAB/Web source parity, redeploy this retained project, and replace the interim evidence with final evidence.

- [ ] **Step 8: Commit interim preview evidence**

~~~bash
git add integration_test/app_smoke_test.dart test/performance_test.dart tooling/performance_profile_app.dart docs/completion-audit.md README.md
git commit -m "test: verify signal chronicle preview"
~~~

## Final acceptance gate

- [ ] Five fixed 180-second operations use the approved seeds, directives, story copy, and one-time bonuses.
- [ ] Loss, time limit, global resolution, and player elimination all conclude Chronicle; Skirmish elimination still spectates.
- [ ] Archive replay never moves sequential progression or changes an ending; restart never clears the lifetime bonus ledger.
- [ ] CLAIM and OPEN persist, and later play is labeled ARCHIVE SIMULATION // NON-CANONICAL.
- [ ] Schema-1 data survives migration; malformed story resets only story, and malformed ledger resets only the lifetime ledger.
- [ ] Four locales convey the same rules; stable IDs contain no translated strings.
- [ ] No third-party AI product name remains on public/runtime/exported surfaces.
- [ ] Mobile controls, focus, screen readers, reduced motion, low-spec mode, lifecycle regression, and 4,000-unit performance are verified at feature level; Android production Task 5 owns API 36 plus physical-device acceptance.
- [ ] flutter analyze, the full Flutter suite, implementation-level emulator integration, and release-mode Web preview build pass.
- [ ] https://tokenfront-orbital-war.pages.dev returns the verified interim Orbital Signal War feature artifact, the previous deployment still exists, and the audit clearly requires privacy/Play Task 7's final post-privacy redeploy.
