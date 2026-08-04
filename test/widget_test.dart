import 'dart:convert';
import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/app/tokenfront_state_store.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/l10n/l10n.dart';
import 'package:tokenfront/main.dart';
import 'package:tokenfront/services/ads/ad_service.dart';
import 'package:tokenfront/services/analytics/analytics_event.dart';
import 'package:tokenfront/services/privacy/privacy_state.dart';
import 'package:tokenfront/settings/game_preferences.dart';
import 'package:tokenfront/story/story_catalog.dart';
import 'package:tokenfront/story/campaign_controller.dart';
import 'package:tokenfront/story/story_models.dart';
import 'package:tokenfront/ui/battle_screen.dart';
import 'package:tokenfront/ui/archive_sheet.dart';
import 'package:tokenfront/ui/result_screen.dart';
import 'package:tokenfront/ui/primitives.dart';

bool _hasSemanticsFlag(SemanticsNode node, SemanticsFlag flag) {
  // ignore: deprecated_member_use
  return node.hasFlag(flag);
}

final class _MemoryStateStore implements TokenfrontStateStore {
  _MemoryStateStore(this.value);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

void main() {
  testWidgets('orbital backdrop stays below units and is non-interactive', (
    tester,
  ) async {
    var unitTaps = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: TacticalBackdrop(
          child: Center(
            child: Semantics(
              label: 'runtime unit',
              child: GestureDetector(
                key: const Key('runtime-unit'),
                behavior: HitTestBehavior.opaque,
                onTap: () => unitTaps += 1,
                child: const SizedBox(width: 120, height: 120),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('runtime-unit')));
    expect(unitTaps, 1);
    expect(find.bySemanticsLabel('runtime unit'), findsOneWidget);
    expect(find.bySemanticsLabel('tokenfront_keyart.png'), findsNothing);
    semantics.dispose();
  });

  testWidgets('battle pauses and resumes without disposed focus callbacks', (
    tester,
  ) async {
    final runtime = TokenfrontRuntime(
      preferences: GamePreferences(audioEnabled: false, hapticsEnabled: false),
    );
    addTearDown(runtime.dispose);
    await tester.pumpWidget(TokenfrontApp(runtime: runtime));
    await tester.pumpAndSettle();

    expect(find.text('TOKENFRONT'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.text('SIGNAL CONDITIONING'), findsOneWidget);
    await tester.tap(find.byTooltip('Close settings'));
    await tester.pumpAndSettle();

    if (find.text('DEPLOY SIGNAL').evaluate().isNotEmpty) {
      await tester.ensureVisible(find.text('DEPLOY SIGNAL'));
      await tester.tap(find.text('DEPLOY SIGNAL'));
    } else {
      await tester.tap(find.text('SKIRMISH').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('skirmish-deploy')));
    }
    await tester.pump();
    expect(find.byType(BattleScreen), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('SIGNAL HELD  /  BATTLE PAUSED'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('SIGNAL HELD  /  BATTLE PAUSED'), findsNothing);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('fresh Command Deck shows prologue before core selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const TokenfrontApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('CHRONICLE'));
    await tester.pumpAndSettle();
    const prologue =
        'The surface has been silent for 72 years. You are a command signal without a body. The Last Relay is calling.';
    expect(find.text(prologue), findsOneWidget);
    expect(find.text('OP-01  //  WAKE // DEAD ORBIT'), findsOneWidget);
    expect(
      find.text(
        'DIRECTIVE: Maintain one uninterrupted command link for 45 seconds.',
      ),
      findsOneWidget,
    );
    expect(find.text('DIRECTIVE BONUS  15 WT'), findsOneWidget);
    expect(find.textContaining('03:00'), findsOneWidget);
    expect(find.text('AMETHYST'), findsOneWidget);
    expect(find.text('COBALT'), findsOneWidget);
    expect(find.text('VOLT'), findsOneWidget);
    expect(find.text('PRISM'), findsOneWidget);
    expect(find.text('ARCHIVE'), findsWidgets);
    expect(find.text('SKIRMISH'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('COMMAND DECK //')), findsOneWidget);
    await tester.tap(find.byKey(const Key('skirmish-mode')));
    await tester.pumpAndSettle();
    expect(find.textContaining('15:00'), findsOneWidget);
  });

  testWidgets(
    'locked Chronicle cores are read-only and Archive hides locked detail',
    (tester) async {
      final runtime = TokenfrontRuntime(platform: ClientPlatform.web);
      addTearDown(runtime.dispose);
      runtime.lockChronicleCore(Faction.amethyst);
      await tester.pumpWidget(TokenfrontApp(runtime: runtime));
      await tester.pumpAndSettle();
      expect(find.textContaining('OP-01'), findsWidgets);
      final lockedCards = find.bySemanticsLabel(RegExp('DIRECTIVE LOCKED'));
      expect(lockedCards, findsNWidgets(4));
      for (var index = 0; index < lockedCards.evaluate().length; index++) {
        final semantics = tester.getSemantics(lockedCards.at(index));
        final flags = semantics.getSemanticsData().flagsCollection;
        expect(flags.isButton, isFalse);
        expect(
          _hasSemanticsFlag(semantics, SemanticsFlag.isFocusable),
          isFalse,
        );
      }
      await tester.tap(find.byKey(const Key('skirmish-mode')));
      await tester.pumpAndSettle();
      final skirmishDeploy = tester.getSemantics(
        find.byKey(const Key('skirmish-deploy')),
      );
      final skirmishFlags = skirmishDeploy.getSemanticsData().flagsCollection;
      expect(skirmishFlags.isButton, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(tester.binding.focusManager.primaryFocus, isNotNull);
      await tester.ensureVisible(find.byKey(const Key('archive-action')));
      await tester.tap(find.byKey(const Key('archive-action')));
      await tester.pumpAndSettle();
      expect(find.text('OP-01  //  WAKE // DEAD ORBIT'), findsOneWidget);
      expect(find.text('CURRENT OPERATION'), findsOneWidget);
      expect(
        find.text('Maintain one uninterrupted command link for 45 seconds.'),
        findsOneWidget,
      );
      expect(find.text('OP-02'), findsOneWidget);
      expect(find.text('OP-02  //  ECHO // BORROWED BODIES'), findsNothing);
      expect(find.text('TRANSMISSION LOCKED'), findsNothing);
      expect(find.text('DIRECTIVE LOCKED // BONUS READY'), findsNothing);
      expect(find.text('DIRECTIVE MISSED'), findsNothing);
      expect(find.textContaining('DIRECTIVE BONUS'), findsNothing);
    },
  );

  testWidgets('Skirmish mode selects configuration before separate deploy', (
    tester,
  ) async {
    await tester.pumpWidget(const TokenfrontApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('skirmish-mode')));
    await tester.pumpAndSettle();
    expect(find.byType(BattleScreen), findsNothing);
    expect(find.byKey(const Key('skirmish-deploy')), findsOneWidget);
    expect(find.text('ARCHIVE SIMULATION // NON-CANONICAL'), findsNothing);
  });

  testWidgets('Archive restart resets story while preserving wallet', (
    tester,
  ) async {
    final runtime = TokenfrontRuntime(platform: ClientPlatform.web);
    addTearDown(runtime.dispose);
    runtime.lockChronicleCore(Faction.volt);
    final before = runtime.wallet.balance;
    await tester.pumpWidget(TokenfrontApp(runtime: runtime));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('archive-action')));
    await tester.tap(find.byKey(const Key('archive-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RESTART CHRONICLE'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Campaign core'), findsOneWidget);
    await tester.tap(find.text('RESTART CHRONICLE').last);
    await tester.pumpAndSettle();
    expect(runtime.storyProgress, StoryProgress.initial());
    expect(runtime.wallet.balance, before);
  });

  testWidgets('ending Archive exposes the non-canonical replay disclosure', (
    tester,
  ) async {
    final progress = StoryProgress(
      campaignFaction: Faction.amethyst,
      concludedOperations: StoryOperationId.values,
      medals: StoryOperationId.values,
      recoveredTransmissions: StoryOperationId.values,
      ending: EndingChoice.claimRelay,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showSignalArchive(
              context: context,
              storyProgress: progress,
              rewardLedger: ProfileRewardLedger.empty(),
              onReplay: (_) {},
            ),
            child: const Text('OPEN ARCHIVE'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN ARCHIVE'));
    await tester.pumpAndSettle();
    expect(find.text('ARCHIVE SIMULATION // NON-CANONICAL'), findsWidgets);
    expect(find.text('RETRY DIRECTIVE'), findsNWidgets(5));
  });

  testWidgets('completed Chronicle without ending exposes persistent choices', (
    tester,
  ) async {
    final operations = StoryOperationId.values
        .map((operation) => operation.name)
        .toList();
    final runtime = await TokenfrontRuntime.restore(
      platform: ClientPlatform.web,
      stateStore: _MemoryStateStore(
        jsonEncode({
          'version': 2,
          'wallet': {
            'balance': 0,
            'unlockedIds': <String>[],
            'equippedIds': <String, String>{},
          },
          'preferences': {
            'lowSpecMode': false,
            'forceReducedMotion': false,
            'mouseCameraEnabled': true,
            'hapticsEnabled': false,
            'audioEnabled': false,
            'languageCode': 'en',
          },
          'privacy': {
            'analyticsSharingAllowed': false,
            'adRequestsAllowed': false,
          },
          'story': {
            'campaignFaction': 'amethyst',
            'concludedOperations': operations,
            'medals': <String>[],
            'recoveredTransmissions': operations,
            'ending': null,
          },
          'rewardLedger': {'claimedDirectiveBonusIds': <String>[]},
        }),
      ),
    );
    addTearDown(runtime.dispose);
    await tester.pumpWidget(TokenfrontApp(runtime: runtime));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('claim-ending')), findsOneWidget);
    expect(find.byKey(const Key('open-ending')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-ending')));
    await tester.pumpAndSettle();
    expect(runtime.storyProgress.ending, EndingChoice.openRelay);
    expect(find.byKey(const Key('open-ending')), findsNothing);
  });

  testWidgets('Command Deck and Archive fit 320x568', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const TokenfrontApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('CHRONICLE'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(tester.binding.focusManager.primaryFocus, isNotNull);
    await tester.ensureVisible(find.byKey(const Key('archive-action')));
    await tester.tap(find.byKey(const Key('archive-action')));
    await tester.pumpAndSettle();
    expect(find.text('ARCHIVE'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chronicle construction failure keeps Skirmish deployable', (
    tester,
  ) async {
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

  testWidgets('Chronicle elimination debrief advances to OP-02', (
    tester,
  ) async {
    final runtime = TokenfrontRuntime(
      platform: ClientPlatform.web,
      preferences: GamePreferences(audioEnabled: false, hapticsEnabled: false),
    );
    addTearDown(runtime.dispose);
    await tester.pumpWidget(TokenfrontApp(runtime: runtime));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CHRONICLE'));
    await tester.pumpAndSettle();
    expect(find.textContaining('OP-01'), findsWidgets);
    await tester.tap(find.text('AMETHYST').first);
    await tester.ensureVisible(find.text('DEPLOY OP-01'));
    await tester.tap(find.text('DEPLOY OP-01'));
    await tester.pump();

    final battle = tester.widget<BattleScreen>(find.byType(BattleScreen));
    for (final unit in battle.game.simulation.units) {
      if (unit.faction == Faction.amethyst) {
        unit.alive = false;
        unit.state = AiState.dead;
      }
    }
    battle.game.update(1 / 30);
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(
      runtime.analytics.pendingEvents.where(
        (e) => e.event.name == 'tutorial_completed',
      ),
      hasLength(1),
    );
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.textContaining('OP-02'), findsWidgets);
  });

  testWidgets('Skirmish elimination preserves spectator battle', (
    tester,
  ) async {
    final runtime = TokenfrontRuntime(platform: ClientPlatform.web);
    addTearDown(runtime.dispose);
    await tester.pumpWidget(TokenfrontApp(runtime: runtime));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SKIRMISH').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('skirmish-deploy')));
    await tester.tap(find.byKey(const Key('skirmish-deploy')));
    await tester.pump();
    final battle = tester.widget<BattleScreen>(find.byType(BattleScreen));
    for (final unit in battle.game.simulation.units) {
      if (unit.faction == Faction.amethyst) {
        unit.alive = false;
        unit.state = AiState.dead;
      }
    }
    battle.game.update(1 / 30);
    await tester.pump();
    expect(find.byType(BattleScreen), findsOneWidget);
    expect(find.byType(ResultScreen), findsNothing);
  });

  testWidgets('Chronicle uses its locked core for later operations', (
    tester,
  ) async {
    final runtime = TokenfrontRuntime(
      platform: ClientPlatform.web,
      preferences: GamePreferences(audioEnabled: false, hapticsEnabled: false),
    );
    addTearDown(runtime.dispose);
    await tester.pumpWidget(TokenfrontApp(runtime: runtime));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CHRONICLE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AMETHYST').first);
    await tester.ensureVisible(find.text('DEPLOY OP-01'));
    await tester.tap(find.text('DEPLOY OP-01'));
    await tester.pump();
    final firstBattle = tester.widget<BattleScreen>(find.byType(BattleScreen));
    for (final unit in firstBattle.game.simulation.units) {
      if (unit.faction == Faction.amethyst) {
        unit.alive = false;
        unit.state = AiState.dead;
      }
    }
    firstBattle.game.update(1 / 30);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('COBALT').first);
    await tester.ensureVisible(find.text('DEPLOY OP-02'));
    await tester.tap(find.text('DEPLOY OP-02'));
    await tester.pump();
    final secondBattle = tester.widget<BattleScreen>(find.byType(BattleScreen));
    expect(secondBattle.game.mode, GameMode.chronicle);
    expect(secondBattle.game.playerFaction, Faction.amethyst);
    expect(runtime.storyProgress.campaignFaction, Faction.amethyst);
  });

  testWidgets(
    'Chronicle rematch is a non-canonical replay on the locked core',
    (tester) async {
      final runtime = TokenfrontRuntime(
        platform: ClientPlatform.web,
        preferences: GamePreferences(
          audioEnabled: false,
          hapticsEnabled: false,
        ),
      );
      addTearDown(runtime.dispose);
      await tester.pumpWidget(TokenfrontApp(runtime: runtime));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CHRONICLE'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('DEPLOY OP-01'));
      await tester.tap(find.text('DEPLOY OP-01'));
      await tester.pump();
      final battle = tester.widget<BattleScreen>(find.byType(BattleScreen));
      for (final unit in battle.game.simulation.units) {
        if (unit.faction == Faction.amethyst) {
          unit.alive = false;
          unit.state = AiState.dead;
        }
      }
      battle.game.update(1 / 30);
      await tester.pumpAndSettle();
      expect(
        runtime.storyProgress.concludedOperations,
        contains(StoryOperationId.wake),
      );
      final currentBeforeReplay = runtime.storyProgress.currentOperation;
      final endingBeforeReplay = runtime.storyProgress.ending;
      await tester.tap(find.text('RETRY DIRECTIVE'));
      await tester.pump();
      expect(find.text('ARCHIVE SIMULATION // NON-CANONICAL'), findsNothing);

      final replay = tester.widget<BattleScreen>(find.byType(BattleScreen));
      expect(replay.game.mode, GameMode.chronicle);
      expect(replay.game.operation?.id, StoryOperationId.wake);
      expect(replay.game.playerFaction, Faction.amethyst);
      for (final unit in replay.game.simulation.units) {
        if (unit.faction == Faction.amethyst) {
          unit.alive = false;
          unit.state = AiState.dead;
        }
      }
      replay.game.update(1 / 30);
      await tester.pumpAndSettle();
      expect(runtime.storyProgress.concludedOperations, {
        StoryOperationId.wake,
      });
      expect(runtime.storyProgress.currentOperation, currentBeforeReplay);
      expect(runtime.storyProgress.ending, endingBeforeReplay);
      expect(
        runtime.analytics.pendingEvents.where(
          (event) => event.event.name == 'tutorial_completed',
        ),
        hasLength(1),
      );
    },
  );

  testWidgets('incomplete Chronicle catalog fails closed after continue', (
    tester,
  ) async {
    final runtime = TokenfrontRuntime(
      platform: ClientPlatform.web,
      preferences: GamePreferences(audioEnabled: false, hapticsEnabled: false),
    );
    addTearDown(runtime.dispose);
    await tester.pumpWidget(
      TokenfrontApp(
        runtime: runtime,
        storyOperationsProvider: () => [StoryCatalog.operations.first],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CHRONICLE'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('DEPLOY OP-01'));
    await tester.tap(find.text('DEPLOY OP-01'));
    await tester.pump();
    final battle = tester.widget<BattleScreen>(find.byType(BattleScreen));
    for (final unit in battle.game.simulation.units) {
      if (unit.faction == Faction.amethyst) {
        unit.alive = false;
        unit.state = AiState.dead;
      }
    }
    battle.game.update(1 / 30);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text('CHRONICLE UNAVAILABLE'), findsOneWidget);
    expect(find.byKey(const Key('chronicle-deploy-disabled')), findsOneWidget);
    await tester.tap(find.byKey(const Key('skirmish-deploy')));
    await tester.pump();
    expect(find.byType(BattleScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lobby exposes factions and deploy action', (tester) async {
    await tester.pumpWidget(const TokenfrontApp());
    await tester.pumpAndSettle();

    expect(find.text('TOKENFRONT'), findsOneWidget);
    expect(find.text('AMETHYST'), findsOneWidget);
    expect(find.text('COBALT'), findsOneWidget);
    expect(find.text('VOLT'), findsOneWidget);
    expect(find.text('PRISM'), findsOneWidget);
    expect(find.text('1000 UNITS'), findsNWidgets(4));
    expect(find.text('4,000'), findsOneWidget);
    await tester.tap(find.byKey(const Key('skirmish-mode')));
    await tester.pumpAndSettle();
    expect(find.text('DEPLOY TO ORBIT'), findsOneWidget);
  });

  testWidgets('lobby remains usable on a narrow mobile surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TokenfrontApp());
    await tester.pumpAndSettle();

    expect(find.text('TOKENFRONT'), findsOneWidget);
    expect(find.text('DEPLOY TO ORBIT'), findsNothing);
    await tester.tap(find.byKey(const Key('skirmish-mode')));
    await tester.pumpAndSettle();
    expect(find.text('DEPLOY TO ORBIT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deploy enters the Flame battle surface', (tester) async {
    final runtime = TokenfrontRuntime(
      preferences: GamePreferences(audioEnabled: false, hapticsEnabled: false),
    );
    addTearDown(runtime.dispose);
    await tester.pumpWidget(TokenfrontApp(runtime: runtime));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('skirmish-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AMETHYST').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('skirmish-deploy')));
    await tester.tap(find.byKey(const Key('skirmish-deploy')));
    await tester.pump();

    expect(find.byType(BattleScreen), findsOneWidget);
    expect(find.textContaining('LV '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'app records first deploy, skipped handoff, and platform FPS fields',
    (tester) async {
      final runtime = TokenfrontRuntime(
        platform: ClientPlatform.web,
        preferences: GamePreferences(
          audioEnabled: false,
          hapticsEnabled: false,
        ),
      );
      addTearDown(runtime.dispose);
      await tester.pumpWidget(TokenfrontApp(runtime: runtime));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('skirmish-mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AMETHYST').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('skirmish-deploy')));
      await tester.tap(find.byKey(const Key('skirmish-deploy')));
      await tester.pump();

      var events = runtime.analytics.pendingEvents
          .map((envelope) => envelope.event)
          .toList(growable: false);
      expect(
        events.where((event) => event.name == 'tutorial_completed'),
        isEmpty,
      );
      expect(
        events
            .singleWhere((event) => event.name == 'match_started')
            .parameters['is_first_match'],
        isTrue,
      );

      final battle = tester.widget<BattleScreen>(find.byType(BattleScreen));
      final game = battle.game;
      for (final unit in game.simulation.units) {
        if (unit.faction == Faction.amethyst) {
          unit.alive = false;
          unit.state = AiState.dead;
        }
      }
      game.update(1 / 30);
      await tester.pump();

      events = runtime.analytics.pendingEvents
          .map((envelope) => envelope.event)
          .toList(growable: false);
      expect(
        events
            .where((event) => event.name == 'handoff_outcome')
            .single
            .parameters['outcome'],
        HandoffAnalyticsOutcome.skipped.name,
      );

      game.simulation.finalizeAtTimeLimit();
      game.update(1 / 60);
      await tester.pump();

      events = runtime.analytics.pendingEvents
          .map((envelope) => envelope.event)
          .toList(growable: false);
      final performance = events.singleWhere(
        (event) => event.name == 'performance_sample',
      );
      expect(performance.parameters['platform'], ClientPlatform.web.name);
      expect(performance.parameters['device_tier'], 'standard');
      expect(performance.parameters['average_fps'], isA<double>());
      expect(performance.parameters['one_percent_low_fps'], isA<double>());

      await tester.tap(find.text('REMATCH'));
      await tester.pump();
      await tester.pump();
      expect(
        runtime.analytics.pendingEvents.where(
          (envelope) => envelope.event.name == 'tutorial_completed',
        ),
        isEmpty,
      );
    },
  );

  testWidgets('lobby opens settings and the cosmetics-only locker', (
    tester,
  ) async {
    await tester.pumpWidget(const TokenfrontApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('SIGNAL SETTINGS'));
    await tester.pumpAndSettle();
    expect(find.text('SIGNAL CONDITIONING'), findsOneWidget);
    expect(find.text('SHARE ANALYTICS'), findsOneWidget);
    expect(find.text('AD REQUESTS'), findsOneWidget);
    expect(find.textContaining('Both choices start off'), findsOneWidget);

    await tester.tap(find.byTooltip('Close settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('LOCKER'));
    await tester.pumpAndSettle();
    expect(find.text('SIGNAL LOCKER'), findsOneWidget);
    expect(
      find.textContaining('Combat strength never changes'),
      findsOneWidget,
    );
    expect(find.text('EQUIPPED'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('result reward doubles only after a completed rewarded offer', (
    tester,
  ) async {
    final standings = <FactionStanding>[
      const FactionStanding(
        faction: Faction.amethyst,
        survivors: 12,
        levelSum: 72,
        kills: 88,
      ),
      const FactionStanding(
        faction: Faction.cobalt,
        survivors: 0,
        levelSum: 0,
        kills: 81,
      ),
      const FactionStanding(
        faction: Faction.volt,
        survivors: 0,
        levelSum: 0,
        kills: 77,
      ),
      const FactionStanding(
        faction: Faction.prism,
        survivors: 0,
        levelSum: 0,
        kills: 66,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ResultScreen(
          result: MatchResult(
            reason: MatchEndReason.elimination,
            winner: Faction.amethyst,
            standings: standings,
          ),
          matchId: 'match-test',
          playerFaction: Faction.amethyst,
          relays: 2,
          elapsed: 90,
          baseReward: 40,
          warTokenBalance: 40,
          bannerVisible: false,
          onDoubleReward: () async => const RewardedClaim(
            adResult: AdResult(AdStatus.rewardEarned),
            credited: 40,
            alreadyClaimed: false,
          ),
          onOpenSettings: () {},
          onOpenLocker: () {},
          onRematch: () {},
          onLobby: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('DOUBLE REWARD'));
    await tester.pumpAndSettle();

    expect(find.text('REWARD DOUBLED'), findsOneWidget);
    expect(find.text('+40 War Tokens secured.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chronicle OP-05 loss exposes both persistent ending choices', (
    tester,
  ) async {
    EndingChoice? selected;
    final standings = <FactionStanding>[
      const FactionStanding(
        faction: Faction.cobalt,
        survivors: 12,
        levelSum: 72,
        kills: 88,
      ),
      const FactionStanding(
        faction: Faction.amethyst,
        survivors: 0,
        levelSum: 0,
        kills: 81,
      ),
    ];
    final progress = StoryProgress(
      campaignFaction: Faction.amethyst,
      concludedOperations: StoryOperationId.values,
      medals: const [],
      recoveredTransmissions: StoryOperationId.values,
      ending: null,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ResultScreen(
          result: MatchResult(
            reason: MatchEndReason.elimination,
            winner: Faction.cobalt,
            standings: standings,
          ),
          matchId: 'op05-loss',
          playerFaction: Faction.amethyst,
          relays: 0,
          elapsed: 180,
          baseReward: 40,
          warTokenBalance: 40,
          bannerVisible: false,
          onDoubleReward: () async => const RewardedClaim(
            adResult: AdResult(AdStatus.unavailable),
            credited: 0,
            alreadyClaimed: false,
          ),
          onOpenSettings: () {},
          onOpenLocker: () {},
          onRematch: () {},
          onLobby: () {},
          operation: StoryCatalog.byId(StoryOperationId.lastInstruction),
          campaignTransition: CampaignTransition(
            nextProgress: StoryProgress.initial(),
            nextLedger: ProfileRewardLedger.empty(),
            directiveSucceeded: false,
            directiveBonusCredit: 0,
            firstConclusion: true,
          ),
          storyProgress: progress,
          rewardLedger: ProfileRewardLedger.empty(),
          onChooseEnding: (choice) => selected = choice,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('CLAIM THE RELAY'), findsOneWidget);
    expect(find.text('OPEN THE RELAY'), findsOneWidget);
    await tester.ensureVisible(find.text('OPEN THE RELAY'));
    await tester.tap(find.text('OPEN THE RELAY'));
    expect(selected, EndingChoice.openRelay);
  });

  testWidgets('Chronicle OP-05 win renders the stored ending epilogue', (
    tester,
  ) async {
    final progress = StoryProgress(
      campaignFaction: Faction.amethyst,
      concludedOperations: StoryOperationId.values,
      medals: StoryOperationId.values,
      recoveredTransmissions: StoryOperationId.values,
      ending: EndingChoice.claimRelay,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ResultScreen(
          result: MatchResult(
            reason: MatchEndReason.elimination,
            winner: Faction.amethyst,
            standings: const [
              FactionStanding(
                faction: Faction.amethyst,
                survivors: 12,
                levelSum: 72,
                kills: 88,
              ),
            ],
          ),
          matchId: 'op05-win',
          playerFaction: Faction.amethyst,
          relays: 2,
          elapsed: 180,
          baseReward: 40,
          warTokenBalance: 40,
          bannerVisible: false,
          onDoubleReward: () async => const RewardedClaim(
            adResult: AdResult(AdStatus.unavailable),
            credited: 0,
            alreadyClaimed: false,
          ),
          onOpenSettings: () {},
          onOpenLocker: () {},
          onRematch: () {},
          onLobby: () {},
          operation: StoryCatalog.byId(StoryOperationId.lastInstruction),
          campaignTransition: CampaignTransition(
            nextProgress: progress,
            nextLedger: ProfileRewardLedger.empty(),
            directiveSucceeded: true,
            directiveBonusCredit: 40,
            firstConclusion: true,
          ),
          storyProgress: progress,
          rewardLedger: ProfileRewardLedger.empty(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'One core inherits Orbit 00. The other three survive only as checksum scars.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('settings and locker remain usable on a narrow surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TokenfrontApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('TUNE'));
    await tester.pumpAndSettle();
    expect(find.text('SIGNAL CONDITIONING'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
