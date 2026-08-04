import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/l10n/l10n.dart';
import 'package:tokenfront/main.dart';
import 'package:tokenfront/services/ads/ad_service.dart';
import 'package:tokenfront/services/analytics/analytics_event.dart';
import 'package:tokenfront/services/privacy/privacy_state.dart';
import 'package:tokenfront/settings/game_preferences.dart';
import 'package:tokenfront/story/story_models.dart';
import 'package:tokenfront/ui/battle_screen.dart';
import 'package:tokenfront/ui/result_screen.dart';

void main() {
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
      await tester.tap(find.text('REMATCH'));
      await tester.pump();

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
      expect(
        runtime.analytics.pendingEvents.where(
          (event) => event.event.name == 'tutorial_completed',
        ),
        hasLength(1),
      );
    },
  );

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

    await tester.ensureVisible(find.text('DEPLOY TO ORBIT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DEPLOY TO ORBIT'));
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

      await tester.ensureVisible(find.text('DEPLOY TO ORBIT'));
      await tester.tap(find.text('DEPLOY TO ORBIT'));
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
