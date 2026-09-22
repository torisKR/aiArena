import 'dart:convert';
import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/app/tokenfront_state_store.dart';
import 'package:tokenfront/design/tokens.dart';
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
import 'package:tokenfront/ui/operation_briefing_screen.dart';
import 'package:tokenfront/ui/primitives.dart';

bool _hasSemanticsFlag(SemanticsNode node, SemanticsFlag flag) {
  // ignore: deprecated_member_use
  return node.hasFlag(flag);
}

Future<void> _deployChronicleBriefing(
  WidgetTester tester, {
  RelayRoute route = RelayRoute.preserve,
}) async {
  if (find.byType(BattleScreen).evaluate().isNotEmpty) return;
  if (find.byKey(const Key('briefing-deploy')).evaluate().isEmpty) {
    await tester.ensureVisible(find.byKey(const Key('chronicle-deploy')));
    await tester.tap(find.byKey(const Key('chronicle-deploy')));
    await tester.pumpAndSettle();
  }
  if (find.byType(BattleScreen).evaluate().isNotEmpty) return;
  final routeKey = route == RelayRoute.force
      ? const Key('briefing-route-force')
      : const Key('briefing-route-preserve');
  await tester.ensureVisible(find.byKey(routeKey));
  await tester.pump();
  await tester.tap(find.byKey(routeKey));
  await tester.pump();
  await tester.ensureVisible(find.byKey(const Key('briefing-deploy')));
  await tester.tap(find.byKey(const Key('briefing-deploy')));
  await tester.pump();
  await tester.pump();
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
  testWidgets('screen transition honors runtime reduced-motion preference', (
    tester,
  ) async {
    final runtime = TokenfrontRuntime(
      preferences: GamePreferences(audioEnabled: false, hapticsEnabled: false),
    );
    addTearDown(runtime.dispose);
    await tester.pumpWidget(TokenfrontApp(runtime: runtime));
    await tester.pumpAndSettle();

    AnimatedSwitcher transition() =>
        tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher).first);
    expect(transition().duration, TokenfrontMotion.screenTransition);

    runtime.preferences.setForceReducedMotion(true);
    await tester.pump();
    expect(transition().duration, Duration.zero);
  });

  testWidgets(
    'Chronicle CTA starts recovery directly without route selection',
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

      await tester.ensureVisible(find.byKey(const Key('chronicle-deploy')));
      await tester.tap(find.byKey(const Key('chronicle-deploy')));
      await tester.pumpAndSettle();
      expect(find.byType(OperationBriefingScreen), findsNothing);
      final battle = tester.widget<BattleScreen>(find.byType(BattleScreen));
      expect(battle.game.isRecovery, isTrue);
      expect(battle.game.simulation.units.length, 400);
      expect(battle.game.simulation.matchLimit, 90);
      expect(find.byKey(const Key('recovery-destination-2')), findsOneWidget);
      await tester.tap(find.byKey(const Key('recovery-destination-2')));
      expect(battle.game.simulation.recovery!.selected, 2);
      expect(runtime.storyProgress.campaignFaction, Faction.amethyst);
    },
  );

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
      await tester.ensureVisible(find.byKey(const Key('skirmish-deploy')));
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

  testWidgets('Android Back pauses an active battle without leaving the app', (
    tester,
  ) async {
    final runtime = TokenfrontRuntime(
      preferences: GamePreferences(audioEnabled: false, hapticsEnabled: false),
    );
    addTearDown(runtime.dispose);
    await tester.pumpWidget(TokenfrontApp(runtime: runtime));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('skirmish-mode')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('skirmish-deploy')));
    await tester.tap(find.byKey(const Key('skirmish-deploy')));
    await tester.pump();
    expect(find.byType(BattleScreen), findsOneWidget);
    final battle = tester.widget<BattleScreen>(find.byType(BattleScreen));
    expect(battle.game.paused, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.byType(BattleScreen), findsOneWidget);
    expect(battle.game.paused, isTrue);
    expect(find.text('SIGNAL HELD  /  BATTLE PAUSED'), findsOneWidget);
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
    expect(find.text('Recover three signals'), findsWidgets);
    expect(find.text('DIRECTIVE BONUS  15 WT'), findsOneWidget);
    expect(find.textContaining('01:30'), findsOneWidget);
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
      final lockedCards = find.bySemanticsLabel(
        RegExp('CHRONICLE CORE LOCKED'),
      );
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

  testWidgets(
    'Chronicle core display and deployment stay aligned after Skirmish return',
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

      await tester.ensureVisible(find.text('COBALT').first);
      await tester.tap(find.text('COBALT').first);
      await tester.ensureVisible(find.byKey(const Key('skirmish-mode')));
      await tester.tap(find.byKey(const Key('skirmish-mode')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('PRISM').first);
      await tester.tap(find.text('PRISM').first);
      await tester.ensureVisible(find.byKey(const Key('skirmish-deploy')));
      await tester.tap(find.byKey(const Key('skirmish-deploy')));
      await tester.pump();
      final skirmish = tester.widget<BattleScreen>(find.byType(BattleScreen));
      skirmish.game.simulation.finalizeAtTimeLimit();
      skirmish.game.update(1 / 30);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('LOBBY'));
      await tester.tap(find.text('LOBBY'));
      await tester.pumpAndSettle();

      final cobalt = tester.getSemantics(
        find.bySemanticsLabel('Choose the COBALT AI core'),
      );
      expect(_hasSemanticsFlag(cobalt, SemanticsFlag.isSelected), isTrue);
      await _deployChronicleBriefing(tester);
      final chronicle = tester.widget<BattleScreen>(find.byType(BattleScreen));
      expect(chronicle.game.playerFaction, Faction.cobalt);
      expect(runtime.storyProgress.campaignFaction, Faction.cobalt);
    },
  );

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
    final amethyst = tester.getSemantics(
      find.bySemanticsLabel('Choose the AMETHYST AI core'),
    );
    expect(_hasSemanticsFlag(amethyst, SemanticsFlag.isSelected), isTrue);
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
    await tester.ensureVisible(find.byKey(const Key('skirmish-deploy')));
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
    await tester.ensureVisible(find.text('AMETHYST').first);
    await tester.tap(find.text('AMETHYST').first);
    await _deployChronicleBriefing(tester);

    final battle = tester.widget<BattleScreen>(find.byType(BattleScreen));
    for (final unit in battle.game.simulation.units) {
      if (unit.faction == Faction.amethyst) {
        unit.alive = false;
        unit.state = AiState.dead;
      }
    }
    for (var tick = 0; tick < 30; tick++) {
      battle.game.update(1 / 30);
      await tester.pump();
      if (find.byType(ResultScreen).evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsNothing);
    expect(runtime.storyProgress.concludedOperations, isEmpty);
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
    await tester.ensureVisible(find.text('AMETHYST').first);
    await tester.tap(find.text('AMETHYST').first);
    await _deployChronicleBriefing(tester);
    final firstBattle = tester.widget<BattleScreen>(find.byType(BattleScreen));
    for (final unit in firstBattle.game.simulation.units) {
      if (unit.faction == Faction.amethyst) {
        unit.alive = false;
        unit.state = AiState.dead;
      }
    }
    firstBattle.game.update(1 / 30);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('CONTINUE').last);
    await tester.pumpAndSettle();

    await _deployChronicleBriefing(tester);
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
      await _deployChronicleBriefing(tester);
      final battle = tester.widget<BattleScreen>(find.byType(BattleScreen));
      for (final unit in battle.game.simulation.units) {
        if (unit.faction == Faction.amethyst) {
          unit.alive = false;
          unit.state = AiState.dead;
        }
      }
      for (var tick = 0; tick < 30; tick++) {
        battle.game.update(1 / 30);
        await tester.pump();
        if (find.byType(ResultScreen).evaluate().isNotEmpty) break;
      }
      await tester.pumpAndSettle();
      expect(runtime.storyProgress.concludedOperations, isEmpty);
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
    await _deployChronicleBriefing(tester);
    final battle = tester.widget<BattleScreen>(find.byType(BattleScreen));
    for (final unit in battle.game.simulation.units) {
      if (unit.faction == Faction.amethyst) {
        unit.alive = false;
        unit.state = AiState.dead;
      }
    }
    for (var tick = 0; tick < 30; tick++) {
      battle.game.update(1 / 30);
      await tester.pump();
      if (find.byType(ResultScreen).evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle();
    expect(runtime.storyProgress.concludedOperations, isEmpty);
    expect(find.byType(BattleScreen), findsOneWidget);
  });

  testWidgets('lobby exposes factions and deploy action', (tester) async {
    await tester.pumpWidget(const TokenfrontApp());
    await tester.pumpAndSettle();

    expect(find.text('TOKENFRONT'), findsOneWidget);
    expect(find.text('AMETHYST'), findsOneWidget);
    expect(find.text('COBALT'), findsOneWidget);
    expect(find.text('VOLT'), findsOneWidget);
    expect(find.text('PRISM'), findsOneWidget);
    expect(find.text('100 AI TOKENS'), findsNWidgets(4));
    expect(find.text('AUTO MOVE · AUTO COMBAT · AUTO CONTINUE'), findsWidgets);
    expect(find.text('COMMAND THE TOKEN FLOW.'), findsOneWidget);
    expect(find.text('4,000'), findsNothing);
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

  testWidgets('deploy bar stays on screen without scrolling on a tall phone', (
    tester,
  ) async {
    // Matches the SM-F741N portrait surface (1080x2640 @ 2.75x).
    tester.view.physicalSize = const Size(1080, 2640);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final runtime = TokenfrontRuntime(
      preferences: GamePreferences(audioEnabled: false, hapticsEnabled: false),
    );
    addTearDown(runtime.dispose);
    await tester.pumpWidget(TokenfrontApp(runtime: runtime));
    await tester.pumpAndSettle();

    // Chronicle deploy is reachable with no ensureVisible / scroll.
    final chronicle = find.byKey(const Key('chronicle-deploy'));
    expect(chronicle, findsOneWidget);
    final viewport = tester.view.physicalSize / tester.view.devicePixelRatio;
    final chronicleRect = tester.getRect(chronicle);
    expect(chronicleRect.bottom, lessThanOrEqualTo(viewport.height));
    expect(chronicleRect.top, greaterThanOrEqualTo(0));

    // Same guarantee in Skirmish mode, still without ensureVisible.
    await tester.tap(find.byKey(const Key('skirmish-mode')));
    await tester.pumpAndSettle();
    final skirmish = find.byKey(const Key('skirmish-deploy'));
    final skirmishRect = tester.getRect(skirmish);
    expect(skirmishRect.bottom, lessThanOrEqualTo(viewport.height));

    // Scrolling the body must not move the pinned bar.
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(skirmish), skirmishRect);

    // Tapping without ensureVisible reaches the battle surface.
    await tester.tap(skirmish);
    await tester.pump();
    expect(find.byType(BattleScreen), findsOneWidget);
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
    expect(find.byKey(const Key('analytics-sharing-toggle')), findsNothing);
    expect(find.byKey(const Key('ad-requests-toggle')), findsNothing);
    expect(find.byKey(const Key('privacy-policy-button')), findsOneWidget);

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
          rewardedAdsAvailable: true,
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
          rewardedAdsAvailable: true,
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
          rewardedAdsAvailable: true,
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
