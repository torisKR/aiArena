import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/design/tokens.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/game/tokenfront_game.dart';
import 'package:tokenfront/l10n/l10n.dart';
import 'package:tokenfront/story/story_models.dart';
import 'package:tokenfront/story/story_catalog.dart';
import 'package:tokenfront/ui/battle_screen.dart';

TokenfrontGame _game({
  StoryOperation? operation,
  RelayRoute? relayRoute,
  bool reduceMotion = false,
  bool lowSpecMode = false,
  bool mouseCameraEnabled = true,
  BattleConfig config = const BattleConfig(unitsPerFaction: 20),
  ValueChanged<BattleReport>? onBattleConcluded,
}) => TokenfrontGame(
  playerFaction: Faction.amethyst,
  mode: operation == null ? GameMode.skirmish : GameMode.chronicle,
  operation: operation,
  relayRoute: relayRoute,
  config: config,
  reduceMotion: reduceMotion,
  lowSpecMode: lowSpecMode,
  mouseCameraEnabled: mouseCameraEnabled,
  hapticsEnabled: false,
  audioEnabled: false,
  onBattleConcluded: onBattleConcluded ?? (_) {},
);

const _relayOperation = StoryOperation(
  id: StoryOperationId.wake,
  seed: 2026080505,
  duration: Duration(seconds: 180),
  directive: Directive(kind: DirectiveKind.commandRelays, target: 1),
  oneTimeBonus: 25,
);

TokenfrontGame _relayGame({RelayRoute route = RelayRoute.preserve}) => _game(
  operation: _relayOperation,
  relayRoute: route,
  config: const BattleConfig(unitsPerFaction: 2),
);

void _isolateRelayUnits(TokenfrontGame game) {
  final controlled = game.simulation.controlledUnit!;
  final enemy = game.simulation.units.firstWhere(
    (unit) => unit.faction != controlled.faction,
  );
  for (final unit in game.simulation.units) {
    unit
      ..alive = unit.faction == controlled.faction || unit.id == enemy.id
      ..state = unit.faction == controlled.faction
          ? AiState.seek
          : AiState.dead;
  }
  enemy.state = AiState.seek;
  enemy
    ..position = const Vec2(2100, 1300)
    ..state = AiState.recover
    ..recoverRemaining = 1000;
  controlled.position = const Vec2(500, 500);
  final target = game.simulation.units.firstWhere(
    (unit) => unit.faction == controlled.faction && unit.id != controlled.id,
  );
  target.position = const Vec2(680, 560);
  game.simulation.rebuildSpatialGrid();
}

KeyDownEvent _keyDown(
  PhysicalKeyboardKey physical,
  LogicalKeyboardKey logical,
) => KeyDownEvent(
  physicalKey: physical,
  logicalKey: logical,
  timeStamp: Duration.zero,
);

void _advance(TokenfrontGame game, double seconds) {
  var remaining = seconds;
  while (remaining > 1e-9) {
    final step = math.min(.025, remaining);
    game.update(step);
    remaining -= step;
  }
}

Widget _localizedBattle(Widget home, {Locale locale = const Locale('en')}) =>
    MaterialApp(
      key: ValueKey(locale),
      locale: locale,
      theme: buildTokenfrontTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  group('input contract', () {
    test('test games can inject a compact simulation config', () {
      final game = _game();

      expect(game.simulation.units, hasLength(80));
      expect(game.hud.value.aliveByFaction[Faction.amethyst], 20);
    });

    test('WASD and arrows normalize movement while Tab remains available', () {
      final game = _game();

      final result = game.onKeyEvent(
        _keyDown(PhysicalKeyboardKey.keyW, LogicalKeyboardKey.keyW),
        {LogicalKeyboardKey.keyW, LogicalKeyboardKey.keyD},
      );

      expect(result, KeyEventResult.handled);
      expect(game.debugKeyboardInput.x, closeTo(math.sqrt1_2, 1e-9));
      expect(game.debugKeyboardInput.y, closeTo(-math.sqrt1_2, 1e-9));

      final arrowResult = game.onKeyEvent(
        _keyDown(PhysicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowLeft),
        {LogicalKeyboardKey.arrowLeft},
      );
      expect(arrowResult, KeyEventResult.handled);
      expect(game.debugKeyboardInput, const Vec2(-1, 0));

      final tabResult = game.onKeyEvent(
        _keyDown(PhysicalKeyboardKey.tab, LogicalKeyboardKey.tab),
        {LogicalKeyboardKey.tab},
      );
      expect(tabResult, KeyEventResult.ignored);
    });

    test('Space triggers dash and touch input is clamped', () {
      final game = _game();

      game.setTouchInput(const Vec2(3, 4));
      expect(game.debugTouchInput.x, closeTo(.6, 1e-9));
      expect(game.debugTouchInput.y, closeTo(.8, 1e-9));

      game.onKeyEvent(
        _keyDown(PhysicalKeyboardKey.space, LogicalKeyboardKey.space),
        {LogicalKeyboardKey.space},
      );
      expect(game.debugDashActive, isTrue);

      game.clearInputs();
      expect(game.debugTouchInput, Vec2.zero);
      expect(game.debugDashActive, isFalse);
    });

    test('mouse pan, wheel zoom, and preference gates are exposed', () async {
      final game = _game();
      await game.onLoad();
      final start = game.debugCameraCenter;

      game.beginMouseCameraPan();
      game.updateMouseCameraPan(const Offset(80, -30));
      game.endMouseCameraPan();
      expect(game.debugCameraCenter.x, lessThan(start.x));
      expect(game.debugCameraCenter.y, greaterThan(start.y));

      final zoomBefore = game.debugManualZoom;
      game.applyMouseWheel(-120);
      expect(game.debugManualZoom, greaterThan(zoomBefore));

      game.setMouseCameraEnabled(false);
      final disabledCenter = game.debugCameraCenter;
      game.beginMouseCameraPan();
      game.updateMouseCameraPan(const Offset(100, 100));
      expect(game.debugCameraCenter, disabledCenter);

      game.applyMouseWheel(10000);
      game.setMouseCameraEnabled(true);
      game.applyMouseWheel(10000);
      expect(game.debugManualZoom, closeTo(.68, 1e-9));
      game.setLowSpecMode(true);
      expect(game.debugManualZoom, greaterThanOrEqualTo(.9));
      expect(game.hud.value.lowSpecMode, isTrue);
    });

    test(
      'minimap camera pan works even when mouse camera is disabled',
      () async {
        final game = _game(mouseCameraEnabled: false);
        await game.onLoad();

        game.beginMinimapCameraPan();
        game.updateMinimapCamera(
          Vec2(
            game.simulation.config.worldWidth,
            game.simulation.config.worldHeight,
          ),
        );
        expect(
          game.debugCameraCenter,
          Vec2(
            game.simulation.config.worldWidth,
            game.simulation.config.worldHeight,
          ),
        );
        game.endMinimapCameraPan();
      },
    );
  });

  group('handoff presentation contract', () {
    test('timeline maps all five exact phases and time scales', () {
      expect(HandoffTimeline.stageAt(0), HandoffStage.impactHold);
      expect(HandoffTimeline.stageAt(.249), HandoffStage.impactHold);
      expect(HandoffTimeline.stageAt(.25), HandoffStage.casualtyFocus);
      expect(HandoffTimeline.stageAt(.55), HandoffStage.successorScan);
      expect(HandoffTimeline.stageAt(.85), HandoffStage.relayTravel);
      expect(HandoffTimeline.stageAt(1.35), HandoffStage.signalLock);

      expect(HandoffTimeline.simulationScaleAt(0), 0);
      expect(HandoffTimeline.simulationScaleAt(.25), .5);
      expect(HandoffTimeline.simulationScaleAt(.85), .5);
      expect(HandoffTimeline.simulationScaleAt(1.35), .5);
      expect(HandoffTimeline.simulationScaleAt(1.425), closeTo(.75, 1e-9));
      expect(HandoffTimeline.simulationScaleAt(1.5), 1);
    });

    test('reduced motion preserves the full 1.5-second handoff contract', () {
      final game = _game(reduceMotion: true);
      final fallen = game.simulation.controlledUnit!;
      fallen.alive = false;
      fallen.state = AiState.dead;

      game.update(.04);
      expect(game.simulation.handoffLog, hasLength(1));
      expect(game.handoffStage, HandoffStage.impactHold);
      _advance(game, .86);
      expect(game.handoffStage, HandoffStage.relayTravel);
      _advance(game, .5);
      expect(game.handoffStage, HandoffStage.signalLock);
      _advance(game, .15);
      expect(game.handoffStage, isNull);
      expect(game.simulation.controlledUnit, isNotNull);
      expect(game.simulation.controlledUnit!.faction, Faction.amethyst);
    });

    test(
      'Chronicle manual relay starts ready and consumes charge on event',
      () {
        final game = _relayGame(route: RelayRoute.force);
        _isolateRelayUnits(game);
        final source = game.simulation.controlledUnit!;

        expect(game.selectedRelayRoute, RelayRoute.force);
        expect(game.manualRelayCharge, 1);
        expect(game.manualRelayReady, isTrue);
        expect(game.hud.value.manualRelayReady, isTrue);
        expect(game.triggerManualRelay(), isTrue);
        expect(game.manualRelayCharge, 1);
        expect(game.manualRelayPending, isTrue);

        game.update(.04);

        expect(game.simulation.handoffLog, hasLength(1));
        expect(game.simulation.handoffLog.single.kind, HandoffKind.manual);
        expect(game.simulation.handoffLog.single.route, RelayRoute.force);
        expect(game.manualRelayCharge, 0);
        expect(game.manualRelayReady, isFalse);
        expect(game.debugFallenUnitId, isNull);
        expect(source.alive, isTrue);
        expect(game.handoffElapsed, 0);

        _advance(game, HandoffTimeline.duration + .1);
        expect(game.handoffStage, isNull);
        expect(game.commandRelays, 1);
        expect(game.manualRelayCount, 1);
      },
    );

    test('manual relay recharge uses exactly 45 simulation seconds', () {
      final game = _relayGame();
      _isolateRelayUnits(game);
      expect(game.triggerManualRelay(), isTrue);
      game.update(.04);
      final eventTimestamp = game.simulation.handoffLog.single.timestamp;
      _advance(game, HandoffTimeline.duration);
      expect(game.manualRelayCharge, lessThan(1));
      var guard = 0;
      while (game.manualRelayCharge! < 1 - 1e-9 && guard < 2000) {
        game.update(.025);
        guard += 1;
      }
      expect(game.manualRelayCharge, closeTo(1, 1e-9));
      expect(
        game.simulation.matchElapsed - eventTimestamp,
        greaterThanOrEqualTo(45),
      );
      expect(game.simulation.matchElapsed - eventTimestamp, lessThan(45.1));
      expect(game.manualRelayReady, isTrue);
    });

    test(
      'failed manual relay keeps a full charge and Skirmish is disabled',
      () {
        final game = _game(
          operation: _relayOperation,
          config: const BattleConfig(unitsPerFaction: 1),
        );
        expect(game.manualRelayCharge, 1);
        expect(game.hud.value.manualRelayCharge, 1);
        expect(game.triggerManualRelay(), isTrue);
        game.update(.04);

        expect(game.simulation.handoffLog, isEmpty);
        expect(game.manualRelayCharge, 1);
        expect(game.manualRelayReady, isTrue);
        expect(game.hud.value.manualRelayPending, isFalse);

        final skirmish = _game();
        expect(skirmish.selectedRelayRoute, isNull);
        expect(skirmish.manualRelayCharge, isNull);
        expect(skirmish.manualRelayReady, isFalse);
        expect(skirmish.triggerManualRelay(), isFalse);
      },
    );

    test('manual relay report separates total/manual counts and route', () {
      final reports = <BattleReport>[];
      final game = _game(
        operation: _relayOperation,
        relayRoute: RelayRoute.force,
        config: const BattleConfig(unitsPerFaction: 2),
        onBattleConcluded: reports.add,
      );
      _isolateRelayUnits(game);
      expect(game.triggerManualRelay(), isTrue);
      game.update(.04);
      _advance(game, HandoffTimeline.duration + .1);
      game.simulation.finalizeAtTimeLimit();
      game.update(.04);

      expect(reports, hasLength(1));
      expect(reports.single.commandRelays, 1);
      expect(reports.single.manualRelays, 1);
      expect(reports.single.casualtyRelays, 0);
      expect(reports.single.relayRoute, RelayRoute.force);
    });

    test('manual receiver loss fails current relay before queued casualty', () {
      final game = _game(
        operation: _relayOperation,
        config: const BattleConfig(unitsPerFaction: 3),
      );
      _isolateRelayUnits(game);
      final source = game.simulation.controlledUnit!;
      final receiver = game.simulation.units.firstWhere(
        (unit) => unit.faction == source.faction && unit.id != source.id,
      );
      final casualtySuccessor = game.simulation.units.lastWhere(
        (unit) => unit.faction == source.faction && unit.id != source.id,
      );
      expect(game.triggerManualRelay(), isTrue);
      game.update(.04);
      expect(game.simulation.handoffLog.single.kind, HandoffKind.manual);

      receiver
        ..alive = false
        ..state = AiState.dead;
      game.simulation.setControlledUnit(null, faction: source.faction);
      game.simulation.handoffLog.add(
        HandoffEvent(
          timestamp: game.simulation.matchElapsed,
          faction: source.faction,
          fromUnitId: receiver.id,
          toUnitId: casualtySuccessor.id,
          score: 0,
          kind: HandoffKind.casualty,
        ),
      );
      game.update(.04);
      expect(game.handoffStage, HandoffStage.impactHold);

      _advance(game, HandoffTimeline.duration + .1);
      expect(game.manualRelayCount, 0);
      expect(game.commandRelays, 0);
      expect(game.handoffStage, HandoffStage.impactHold);

      _advance(game, HandoffTimeline.duration + .1);
      expect(game.manualRelayCount, 0);
      expect(game.commandRelays, 1);
      expect(game.handoffStage, isNull);
    });
  });

  group('battle renderer performance', () {
    test('4000-scale atlas tokens use one batched sprite submission', () async {
      final game = _game(config: const BattleConfig());
      game.onGameResize(Vector2(844, 390));
      await game.onLoad();
      final recorder = ui.PictureRecorder();

      game.render(ui.Canvas(recorder));
      final picture = recorder.endRecording();
      addTearDown(picture.dispose);

      expect(game.debugUnitAtlasLoaded, isTrue);
      expect(game.debugAtlasBatchSubmissionCount, 1);
      expect(game.debugAtlasBatchSpriteCount, greaterThan(1000));
    });

    test('dense 4000-scale collisions cap combat flashes at 96', () {
      final game = _game(
        config: const BattleConfig(
          unitsPerFaction: 60,
          separationStrength: 0,
          lowLevelFleeChance: 0,
        ),
      );
      for (final unit in game.simulation.units) {
        unit
          ..position = const Vec2(1100, 700)
          ..state = AiState.seek;
      }
      game.simulation.rebuildSpatialGrid();

      game.update(1 / 30);

      expect(game.simulation.frameCombatEvents.length, greaterThan(96));
      expect(game.debugCombatFlashCount, 96);
    });

    test(
      'landscape battle starts closer and exposes a clamped viewport',
      () async {
        final game = _game(reduceMotion: true);
        game.onGameResize(Vector2(844, 390));
        await game.onLoad();
        final recorder = ui.PictureRecorder();

        game.render(ui.Canvas(recorder));
        final picture = recorder.endRecording();
        addTearDown(picture.dispose);

        expect(game.cameraZoom, greaterThanOrEqualTo(.31));
        expect(game.visibleWorldBounds.left, greaterThanOrEqualTo(0));
        expect(game.visibleWorldBounds.top, greaterThanOrEqualTo(0));
        expect(
          game.visibleWorldBounds.right,
          lessThanOrEqualTo(game.simulation.config.worldWidth),
        );
        expect(
          game.visibleWorldBounds.bottom,
          lessThanOrEqualTo(game.simulation.config.worldHeight),
        );
      },
    );

    test(
      'default-motion camera transitions from overview to closer follow',
      () async {
        final game = _game();
        game.onGameResize(Vector2(844, 390));
        await game.onLoad();
        final overviewRecorder = ui.PictureRecorder();
        game.render(ui.Canvas(overviewRecorder));
        final overviewPicture = overviewRecorder.endRecording();
        addTearDown(overviewPicture.dispose);
        final overviewZoom = game.cameraZoom;

        _advance(game, 4.1);
        final followRecorder = ui.PictureRecorder();
        game.render(ui.Canvas(followRecorder));
        final followPicture = followRecorder.endRecording();
        addTearDown(followPicture.dispose);

        expect(overviewZoom, closeTo(.31, .001));
        expect(game.cameraZoom, greaterThan(overviewZoom + .08));
      },
    );

    test('relay tape safely renders a live handoff path', () async {
      final game = _game();
      final fallen = game.simulation.controlledUnit!;
      final successor = game.simulation.units.firstWhere(
        (unit) => unit.faction == fallen.faction && unit.id != fallen.id,
      );
      final enemy = game.simulation.units.firstWhere(
        (unit) => unit.faction != fallen.faction,
      );
      for (final unit in game.simulation.units) {
        unit.alive =
            unit.id == fallen.id ||
            unit.id == successor.id ||
            unit.id == enemy.id;
        unit.state = unit.alive ? AiState.seek : AiState.dead;
      }
      fallen.position = const Vec2(500, 500);
      successor.position = const Vec2(680, 560);
      enemy.position = const Vec2(1800, 1100);
      fallen.alive = false;
      fallen.state = AiState.dead;
      game.simulation.rebuildSpatialGrid();
      game.onGameResize(Vector2(400, 300));
      await game.onLoad();

      game.update(.04);
      _advance(game, .9);
      expect(game.handoffStage, HandoffStage.relayTravel);
      final recorder = ui.PictureRecorder();

      expect(() => game.render(ui.Canvas(recorder)), returnsNormally);
      final picture = recorder.endRecording();
      addTearDown(picture.dispose);
    });

    test(
      'culls live units beyond the conservative world viewport margin',
      () async {
        final game = _game(reduceMotion: true);
        final controlled = game.simulation.controlledUnit!;
        final distant = game.simulation.units.firstWhere(
          (unit) => unit.faction == Faction.prism,
        );
        for (final unit in game.simulation.units) {
          unit.alive = unit.id == controlled.id || unit.id == distant.id;
          unit.state = unit.alive ? AiState.seek : AiState.dead;
        }
        controlled.position = const Vec2(200, 200);
        distant.position = const Vec2(2100, 1300);
        game.simulation.rebuildSpatialGrid();
        game.onGameResize(Vector2(400, 300));
        await game.onLoad();
        final recorder = ui.PictureRecorder();

        game.render(ui.Canvas(recorder));
        final picture = recorder.endRecording();
        addTearDown(picture.dispose);

        expect(game.debugRenderedUnitCount, 1);
        expect(game.debugCulledUnitCount, 1);
      },
    );
  });

  group('battle accessibility and responsive layout', () {
    testWidgets(
      'live directive text and semantics stay localized while final rank is provisional',
      (tester) async {
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        final announcements = <String>[];
        messenger.setMockDecodedMessageHandler(SystemChannels.accessibility, (
          message,
        ) async {
          if (message is Map && message['type'] == 'announce') {
            announcements.add(message['data']['message'] as String);
          }
          return null;
        });
        addTearDown(
          () => messenger.setMockDecodedMessageHandler(
            SystemChannels.accessibility,
            null,
          ),
        );

        for (final locale in AppLocalizations.supportedLocales) {
          final game = _game(
            operation: StoryCatalog.byId(StoryOperationId.crown),
          );
          await tester.pumpWidget(
            _localizedBattle(BattleScreen(game: game), locale: locale),
          );
          await tester.pump(const Duration(milliseconds: 50));
          game.pauseEngine();

          final context = tester.element(
            find.byKey(const Key('directive-rail')),
          );
          final l10n = context.l10n;
          final name = l10n.directiveNameFinalRank;
          for (final rank in const <int>[1, 2]) {
            game.hud.value = BattleHudSnapshot.initial(
              unitsPerFaction: 20,
              matchLimitSeconds: 180,
              directiveProgress: DirectiveProgress(
                kind: DirectiveKind.finalRank,
                current: rank.toDouble(),
                target: 2,
              ),
            );
            await tester.pump();
            final expected = l10n.directiveOnTrack(
              l10n.directive,
              name,
              rank,
              2,
            );
            expect(find.text(expected), findsOneWidget);
            expect(find.bySemanticsLabel(expected), findsOneWidget);
            expect(find.text(l10n.directiveLocked), findsNothing);
            if (rank == 1) expect(announcements, contains(expected));
          }
        }
      },
    );

    testWidgets(
      'directive rail announces neutral completion without bonus eligibility',
      (tester) async {
        final announcements = <String>[];
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockDecodedMessageHandler(SystemChannels.accessibility, (
          message,
        ) async {
          if (message is Map && message['type'] == 'announce') {
            announcements.add(message['data']['message'] as String);
          }
          return null;
        });
        addTearDown(
          () => messenger.setMockDecodedMessageHandler(
            SystemChannels.accessibility,
            null,
          ),
        );
        final game = TokenfrontGame(
          playerFaction: Faction.amethyst,
          mode: GameMode.chronicle,
          operation: const StoryOperation(
            id: StoryOperationId.split,
            seed: 2026080503,
            duration: Duration(seconds: 180),
            directive: Directive(kind: DirectiveKind.commandKills, target: 3),
            oneTimeBonus: 25,
          ),
          config: const BattleConfig(unitsPerFaction: 20),
          reduceMotion: true,
          lowSpecMode: true,
          hapticsEnabled: false,
          audioEnabled: false,
          onBattleConcluded: (_) {},
        );
        await tester.pumpWidget(_localizedBattle(BattleScreen(game: game)));
        await tester.pump(const Duration(milliseconds: 50));
        expect(announcements, contains('DIRECTIVE // COMMAND KILLS 0 / 3'));
        game.pauseEngine();

        game.hud.value = BattleHudSnapshot.initial(
          unitsPerFaction: 20,
          matchLimitSeconds: 180,
          directiveProgress: const DirectiveProgress(
            kind: DirectiveKind.commandKills,
            current: 1,
            target: 3,
          ),
        );
        await tester.pump();
        expect(find.text('DIRECTIVE // COMMAND KILLS 1 / 3'), findsOneWidget);
        expect(announcements, contains('DIRECTIVE // COMMAND KILLS 1 / 3'));
        await tester.pump();
        expect(
          find.bySemanticsLabel('DIRECTIVE // COMMAND KILLS 1 / 3'),
          findsOneWidget,
        );

        game.hud.value = BattleHudSnapshot.initial(
          unitsPerFaction: 20,
          matchLimitSeconds: 180,
          directiveProgress: const DirectiveProgress(
            kind: DirectiveKind.commandKills,
            current: 2,
            target: 3,
          ),
        );
        await tester.pump();
        expect(find.text('DIRECTIVE // COMMAND KILLS 2 / 3'), findsOneWidget);
        expect(
          announcements.where((message) => message.contains('2 / 3')),
          isEmpty,
        );
        expect(
          find.bySemanticsLabel('DIRECTIVE // COMMAND KILLS 1 / 3'),
          findsOneWidget,
        );

        game.hud.value = BattleHudSnapshot.initial(
          unitsPerFaction: 20,
          matchLimitSeconds: 180,
          directiveProgress: const DirectiveProgress(
            kind: DirectiveKind.commandKills,
            current: 3,
            target: 3,
          ),
        );
        await tester.pump();
        expect(find.text('DIRECTIVE COMPLETE'), findsOneWidget);
        expect(find.bySemanticsLabel('DIRECTIVE COMPLETE'), findsOneWidget);
        expect(announcements, contains('DIRECTIVE COMPLETE'));
        expect(announcements, hasLength(3));
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('DIRECTIVE COMPLETE'), findsOneWidget);
      },
    );

    testWidgets('incomplete command link floors visible progress', (
      tester,
    ) async {
      final game = _game(operation: StoryCatalog.byId(StoryOperationId.wake));
      await tester.pumpWidget(_localizedBattle(BattleScreen(game: game)));
      await tester.pump(const Duration(milliseconds: 50));
      game.pauseEngine();
      game.hud.value = BattleHudSnapshot.initial(
        unitsPerFaction: 20,
        matchLimitSeconds: 180,
        directiveProgress: const DirectiveProgress(
          kind: DirectiveKind.longestCommandLink,
          current: 44.9,
          target: 45,
        ),
      );
      await tester.pump();

      expect(find.text('DIRECTIVE // COMMAND LINK 44 / 45'), findsOneWidget);
      expect(find.textContaining('45 / 45'), findsNothing);
    });

    testWidgets('releasing movement after minimap focus stops the unit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = _game();

      await tester.pumpWidget(_localizedBattle(BattleScreen(game: game)));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
      await tester.pump();
      expect(game.debugKeyboardInput, const Vec2(1, 0));

      await tester.tap(find.byKey(const Key('battle-minimap')));
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'battle-minimap');

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);
      await tester.pump();
      expect(game.debugKeyboardInput, Vec2.zero);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyW);
      await tester.pump();
      expect(game.debugKeyboardInput.x, closeTo(-math.sqrt1_2, 1e-9));
      expect(game.debugKeyboardInput.y, closeTo(-math.sqrt1_2, 1e-9));

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyW);
      await tester.pump();
      expect(game.debugKeyboardInput, Vec2.zero);
    });

    testWidgets('Space activates the focused HUD control instead of dash', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = _game();

      await tester.pumpWidget(_localizedBattle(BattleScreen(game: game)));
      await tester.pump(const Duration(milliseconds: 50));

      final lowPower = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Low power mode',
      );
      expect(lowPower, findsOneWidget);
      await tester.tap(lowPower);
      await tester.pump();
      expect(game.hud.value.lowSpecMode, isTrue);

      final lowPowerLabel = find.descendant(
        of: lowPower,
        matching: find.text('ECO'),
      );
      final buttonFocus = Focus.of(tester.element(lowPowerLabel));
      buttonFocus.requestFocus();
      await tester.pump();
      expect(buttonFocus.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(game.hud.value.lowSpecMode, isFalse);
      expect(game.debugDashActive, isFalse);
    });

    testWidgets('R reaches the game from an unrelated focused HUD control', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = _relayGame();
      _isolateRelayUnits(game);

      await tester.pumpWidget(_localizedBattle(BattleScreen(game: game)));
      await tester.pump(const Duration(milliseconds: 50));
      final lowPower = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Low power mode',
      );
      final lowPowerLabel = find.descendant(
        of: lowPower,
        matching: find.text('ECO'),
      );
      final buttonFocus = Focus.of(tester.element(lowPowerLabel));
      buttonFocus.requestFocus();
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyR);
      await tester.pump();
      expect(game.simulation.manualRelayPending, isTrue);
      expect(game.manualRelayCharge, 1);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyR);
      await tester.pump();
      expect(game.simulation.manualRelayPending, isTrue);
    });

    testWidgets('minimap arrow repeats stay camera-only', (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = _game();

      await tester.pumpWidget(_localizedBattle(BattleScreen(game: game)));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byKey(const Key('battle-minimap')));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      final afterDown = game.debugCameraCenter;
      expect(game.debugKeyboardInput, Vec2.zero);

      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(game.debugCameraCenter.x, greaterThan(afterDown.x));
      expect(game.debugKeyboardInput, Vec2.zero);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(game.debugKeyboardInput, Vec2.zero);
    });

    testWidgets('minimap arrows never leak in through another key release', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = _game();

      await tester.pumpWidget(_localizedBattle(BattleScreen(game: game)));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byKey(const Key('battle-minimap')));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyW);
      await tester.pump();
      expect(game.debugKeyboardInput, const Vec2(0, -1));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyW);
      await tester.pump();
      expect(game.debugKeyboardInput, Vec2.zero);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(game.debugKeyboardInput, Vec2.zero);
    });

    testWidgets('portrait gate clears an active joystick vector', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = _game();

      await tester.pumpWidget(
        _localizedBattle(BattleScreen(game: game, requireLandscape: true)),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final joystick = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Movement joystick',
      );
      expect(joystick, findsOneWidget);
      final joystickSurface = find.descendant(
        of: joystick,
        matching: find.byType(Listener),
      );
      expect(joystickSurface, findsOneWidget);
      final joystickRect = tester.getRect(joystickSurface);
      final gesture = await tester.startGesture(
        joystickRect.center + Offset(joystickRect.width * .25, 0),
      );
      try {
        await tester.pump();
        expect(game.debugTouchInput.x, greaterThan(.5));

        tester.view.physicalSize = const Size(390, 844);
        await tester.pump();
        expect(find.byKey(const Key('landscape-required')), findsOneWidget);
        expect(game.debugTouchInput, Vec2.zero);
      } finally {
        await gesture.up();
      }
    });

    testWidgets('portrait gate clears an active keyboard vector', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = _game();

      await tester.pumpWidget(
        _localizedBattle(BattleScreen(game: game, requireLandscape: true)),
      );
      await tester.pump(const Duration(milliseconds: 50));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
      await tester.pump();
      expect(game.debugKeyboardInput, const Vec2(1, 0));

      tester.view.physicalSize = const Size(390, 844);
      await tester.pump();
      expect(find.byKey(const Key('landscape-required')), findsOneWidget);
      expect(game.debugKeyboardInput, Vec2.zero);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);
    });

    testWidgets('short landscape expands mobile command pads without overlap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(568, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = _game();

      await tester.pumpWidget(
        _localizedBattle(BattleScreen(game: game, requireLandscape: true)),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final joystick = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Movement joystick',
      );
      final joystickSurface = find.descendant(
        of: joystick,
        matching: find.byType(Listener),
      );
      final joystickRect = tester.getRect(joystickSurface);
      final dashRect = tester.getRect(find.bySemanticsLabel('Dash'));
      final minimapRect = tester.getRect(
        find.byKey(const Key('battle-minimap')),
      );

      expect(joystickRect.width, greaterThanOrEqualTo(104));
      expect(joystickRect.height, greaterThanOrEqualTo(104));
      expect(dashRect.width, greaterThanOrEqualTo(72));
      expect(dashRect.height, greaterThanOrEqualTo(72));
      expect(joystickRect.overlaps(dashRect), isFalse);
      expect(joystickRect.overlaps(minimapRect), isFalse);
      expect(dashRect.overlaps(minimapRect), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('chronicle HUD controls fit both supported short landscapes', (
      tester,
    ) async {
      for (final size in const [Size(568, 320), Size(844, 390)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        final game = _game(
          operation: StoryCatalog.byId(StoryOperationId.split),
          reduceMotion: true,
        );
        await tester.pumpWidget(
          _localizedBattle(BattleScreen(game: game, requireLandscape: true)),
        );
        await tester.pump(const Duration(milliseconds: 50));

        final joystick = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Movement joystick',
        );
        final joystickRect = tester.getRect(
          find.descendant(of: joystick, matching: find.byType(Listener)),
        );
        final dashRect = tester.getRect(find.bySemanticsLabel('Dash'));
        final minimapRect = tester.getRect(
          find.byKey(const Key('battle-minimap')),
        );
        final directiveRect = tester.getRect(
          find.byKey(const Key('directive-rail')),
        );
        final pauseRect = tester.getRect(find.byKey(const Key('battle-pause')));

        expect(joystickRect.width, greaterThanOrEqualTo(104));
        expect(joystickRect.height, greaterThanOrEqualTo(104));
        expect(dashRect.width, greaterThanOrEqualTo(72));
        expect(dashRect.height, greaterThanOrEqualTo(72));
        for (final pair in [
          (joystickRect, dashRect),
          (joystickRect, minimapRect),
          (joystickRect, directiveRect),
          (joystickRect, pauseRect),
          (dashRect, minimapRect),
          (dashRect, directiveRect),
          (dashRect, pauseRect),
          (minimapRect, directiveRect),
          (minimapRect, pauseRect),
          (directiveRect, pauseRect),
        ]) {
          expect(pair.$1.overlaps(pair.$2), isFalse);
        }
        for (final rect in [
          joystickRect,
          dashRect,
          minimapRect,
          directiveRect,
          pauseRect,
        ]) {
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('pause button toggles a localized overlay and clears input', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = _game();
      await tester.pumpWidget(_localizedBattle(BattleScreen(game: game)));
      await tester.pump(const Duration(milliseconds: 50));
      game.setTouchInput(const Vec2(1, 0));
      await tester.pump();

      final pause = find.bySemanticsLabel('PAUSE');
      expect(pause, findsOneWidget);
      await tester.tap(pause);
      await tester.pump();
      expect(game.paused, isTrue);
      expect(game.debugTouchInput, Vec2.zero);
      expect(find.text('SIGNAL HELD  /  BATTLE PAUSED'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('RESUME'));
      await tester.pump();
      expect(game.paused, isFalse);
      expect(find.text('SIGNAL HELD  /  BATTLE PAUSED'), findsNothing);
    });

    testWidgets('pause action semantics expose the localized current action', (
      tester,
    ) async {
      for (final locale in AppLocalizations.supportedLocales) {
        final game = _game();
        await tester.pumpWidget(
          _localizedBattle(BattleScreen(game: game), locale: locale),
        );
        await tester.pump(const Duration(milliseconds: 50));
        final context = tester.element(find.byKey(const Key('battle-pause')));
        final l10n = context.l10n;
        final pause = find.bySemanticsLabel(l10n.pauseBattle);
        expect(pause, findsOneWidget);
        expect(
          tester
              .getSemantics(pause)
              .getSemanticsData()
              .hasAction(ui.SemanticsAction.tap),
          isTrue,
        );
        await tester.tap(find.bySemanticsLabel(l10n.pauseBattle));
        await tester.pump();
        expect(find.bySemanticsLabel(l10n.resumeBattle), findsOneWidget);
        expect(find.bySemanticsLabel(l10n.pauseBattle), findsNothing);
        final overlay = find.bySemanticsLabel(l10n.battleUserPausedSemantics);
        expect(overlay, findsOneWidget);
        expect(
          tester
              .getSemantics(overlay)
              .getSemanticsData()
              .flagsCollection
              .isLiveRegion,
          isTrue,
        );
      }
    });

    testWidgets('initially inactive battle pauses before its first frame', (
      tester,
    ) async {
      final game = _game();
      addTearDown(() {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      });
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpWidget(_localizedBattle(BattleScreen(game: game)));

      expect(game.paused, isTrue);
      expect(
        find.bySemanticsLabel('Battle paused while the app is inactive'),
        findsOneWidget,
      );
    });

    testWidgets('manual pause rejects every deferred gameplay input', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = _game();
      await tester.pumpWidget(_localizedBattle(BattleScreen(game: game)));
      await tester.pump(const Duration(milliseconds: 50));

      final pause = find.bySemanticsLabel('PAUSE');
      await tester.tap(pause);
      await tester.pump();
      expect(game.paused, isTrue);
      final cameraBefore = game.debugCameraCenter;

      game.onFocusedMovementKeyEvent(
        _keyDown(PhysicalKeyboardKey.keyD, LogicalKeyboardKey.keyD),
      );
      game.onKeyEvent(
        _keyDown(PhysicalKeyboardKey.space, LogicalKeyboardKey.space),
        {LogicalKeyboardKey.space},
      );
      game.setTouchInput(const Vec2(1, 0));
      game.triggerDash();
      game.beginMinimapCameraPan();
      game.updateMinimapCamera(const Vec2(999, 999));
      final joystick = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Movement joystick',
      );
      final joystickSurface = find.descendant(
        of: joystick,
        matching: find.byType(Listener),
      );
      final gesture = await tester.startGesture(
        tester.getRect(joystickSurface).center + const Offset(20, 0),
      );
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(game.debugKeyboardInput, Vec2.zero);
      expect(game.debugTouchInput, Vec2.zero);
      expect(game.debugDashActive, isFalse);
      expect(game.debugCameraCenter, cameraBefore);

      await tester.tap(find.bySemanticsLabel('RESUME'));
      await tester.pump();
      expect(game.paused, isFalse);
      game.update(.3);
      expect(game.debugKeyboardInput, Vec2.zero);
      expect(game.debugTouchInput, Vec2.zero);
      expect(game.debugDashActive, isFalse);
    });

    testWidgets('directive completion cue respects normal and reduced motion', (
      tester,
    ) async {
      Future<void> complete(TokenfrontGame game) async {
        game.pauseEngine();
        game.hud.value = BattleHudSnapshot.initial(
          unitsPerFaction: 20,
          matchLimitSeconds: 180,
          directiveProgress: const DirectiveProgress(
            kind: DirectiveKind.commandKills,
            current: 3,
            target: 3,
          ),
        );
        await tester.pump();
      }

      final normal = _game(
        operation: StoryCatalog.byId(StoryOperationId.split),
      );
      await tester.pumpWidget(_localizedBattle(BattleScreen(game: normal)));
      await tester.pump(const Duration(milliseconds: 50));
      await complete(normal);
      AnimatedContainer rail() => tester.widget<AnimatedContainer>(
        find.byKey(const Key('directive-rail')),
      );
      BoxDecoration decoration() => rail().decoration! as BoxDecoration;
      expect(decoration().border!.top.color, TokenfrontColors.volt);
      await tester.pump(const Duration(seconds: 1));
      expect(decoration().border!.top.color, TokenfrontColors.volt);
      await tester.pump(const Duration(seconds: 1, milliseconds: 100));
      expect(
        decoration().border!.top.color,
        TokenfrontColors.relayIvory.withValues(alpha: .32),
      );

      final reduced = _game(
        operation: StoryCatalog.byId(StoryOperationId.split),
        reduceMotion: true,
      );
      await tester.pumpWidget(_localizedBattle(BattleScreen(game: reduced)));
      await tester.pump(const Duration(milliseconds: 50));
      await complete(reduced);
      expect(rail().duration, Duration.zero);
      expect(
        (rail().decoration! as BoxDecoration).border!.top.color,
        TokenfrontColors.volt,
      );
    });

    testWidgets('landscape HUD has a right-side draggable tactical minimap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = _game(mouseCameraEnabled: false);

      await tester.pumpWidget(
        _localizedBattle(BattleScreen(game: game, requireLandscape: true)),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final minimap = find.byKey(const Key('battle-minimap'));
      expect(minimap, findsOneWidget);
      final mapRect = tester.getRect(minimap);
      final dashRect = tester.getRect(find.bySemanticsLabel('Dash'));
      expect(mapRect.center.dx, greaterThan(844 * .75));
      expect(
        mapRect.width / mapRect.height,
        closeTo(
          game.simulation.config.worldWidth /
              game.simulation.config.worldHeight,
          .08,
        ),
      );
      expect(mapRect.overlaps(dashRect), isFalse);
      expect(find.bySemanticsLabel('Movement joystick'), findsOneWidget);
      expect(
        tester
            .getSemantics(minimap)
            .getSemanticsData()
            .hasAction(ui.SemanticsAction.tap),
        isTrue,
      );

      await tester.tap(minimap);
      await tester.pump();
      final keyboardStart = game.debugCameraCenter;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(game.debugCameraCenter.x, greaterThan(keyboardStart.x));

      final start = game.debugCameraCenter;
      final gesture = await tester.startGesture(
        mapRect.topLeft + Offset(mapRect.width * .8, mapRect.height * .8),
      );
      await gesture.moveTo(mapRect.bottomRight - const Offset(3, 3));
      await tester.pump();
      expect(game.debugCameraCenter.x, greaterThan(start.x));
      expect(game.debugCameraCenter.y, greaterThan(start.y));
      await gesture.up();
      expect(tester.takeException(), isNull);
    });

    testWidgets('portrait phone blocks play until the display is landscape', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = _game();
      await tester.pumpWidget(
        _localizedBattle(BattleScreen(game: game, requireLandscape: true)),
      );
      await tester.pump();

      expect(find.byKey(const Key('landscape-required')), findsOneWidget);
      expect(find.text('ROTATE TO PLAY'), findsOneWidget);
      expect(find.byKey(const Key('battle-game-surface')), findsNothing);
      expect(find.bySemanticsLabel('Movement joystick'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('battle pauses and clears movement while app is inactive', (
      tester,
    ) async {
      final game = _game();
      addTearDown(() {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      });
      await tester.pumpWidget(_localizedBattle(BattleScreen(game: game)));
      await tester.pump();
      game.setTouchInput(const Vec2(1, 0));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(game.paused, isTrue);
      expect(game.debugTouchInput, Vec2.zero);
      expect(find.text('SIGNAL HELD  /  BATTLE PAUSED'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(game.paused, isFalse);
      expect(find.text('SIGNAL HELD  /  BATTLE PAUSED'), findsNothing);
    });

    testWidgets(
      'hidden lifecycle freezes simulation and resumes without catch-up',
      (tester) async {
        final game = _game();
        addTearDown(() {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
        });
        await tester.pumpWidget(_localizedBattle(BattleScreen(game: game)));
        await tester.pump();
        _advance(game, .1);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        await tester.pump();
        final hiddenElapsed = game.simulation.matchElapsed;
        final hiddenTicks = game.simulation.simulationTickCount;

        expect(game.paused, isTrue);
        await tester.pump(const Duration(seconds: 30));
        expect(game.simulation.matchElapsed, hiddenElapsed);
        expect(game.simulation.simulationTickCount, hiddenTicks);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(game.paused, isFalse);
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          game.simulation.matchElapsed - hiddenElapsed,
          lessThanOrEqualTo(game.simulation.fixedStepSeconds + 1e-9),
        );
      },
    );

    testWidgets('stale lifecycle notice clears when the host resumes Flame', (
      tester,
    ) async {
      final game = _game();
      addTearDown(() {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      });
      await tester.pumpWidget(_localizedBattle(BattleScreen(game: game)));
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(game.paused, isTrue);
      expect(find.text('SIGNAL HELD  /  BATTLE PAUSED'), findsOneWidget);

      // Some web hosts resume Flame before Flutter emits the matching
      // lifecycle callback. The overlay must reflect the live engine state.
      game.resumeEngine();
      game.update(.05);
      game.update(.05);
      await tester.pump();

      expect(game.paused, isFalse);
      expect(find.text('SIGNAL HELD  /  BATTLE PAUSED'), findsNothing);
    });

    testWidgets('game surface wires mouse drag and wheel camera controls', (
      tester,
    ) async {
      final game = _game();
      await tester.pumpWidget(_localizedBattle(BattleScreen(game: game)));
      await tester.pump();
      final surface = find.byKey(const Key('battle-game-surface'));
      final center = tester.getCenter(surface);
      final cameraBefore = game.debugCameraCenter;

      final mouse = await tester.startGesture(
        center,
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );
      await mouse.moveBy(const Offset(70, 0));
      expect(game.debugCameraCenter.x, lessThan(cameraBefore.x));
      await mouse.up();

      final zoomBefore = game.debugManualZoom;
      tester.binding.handlePointerEvent(
        PointerScrollEvent(
          position: center,
          scrollDelta: const Offset(0, -120),
        ),
      );
      await tester.pump();
      expect(game.debugManualZoom, greaterThan(zoomBefore));
    });

    testWidgets(
      'paused camera reset actions are inert for manual and lifecycle pause',
      (tester) async {
        tester.view.physicalSize = const Size(844, 390);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final game = _game();
        await tester.pumpWidget(_localizedBattle(BattleScreen(game: game)));
        await tester.pump(const Duration(milliseconds: 50));

        void offsetCamera() {
          game.beginMinimapCameraPan();
          game.updateMinimapCamera(const Vec2(100, 100));
          game.endMinimapCameraPan();
          game.applyMouseWheel(-120);
        }

        offsetCamera();
        final pause = find.bySemanticsLabel('PAUSE');
        await tester.tap(pause);
        await tester.pump();
        final manualCenter = game.debugCameraCenter;
        final manualZoom = game.debugManualZoom;

        game.resetCameraView();
        await tester.tap(
          find.bySemanticsLabel('Reset camera to controlled unit'),
        );
        await tester.tap(find.bySemanticsLabel('Tactical map'));
        await tester.pump();
        expect(game.debugCameraCenter, manualCenter);
        expect(game.debugManualZoom, manualZoom);

        await tester.tap(find.bySemanticsLabel('RESUME'));
        await tester.pump();
        offsetCamera();
        final lifecycleCenter = game.debugCameraCenter;
        final lifecycleZoom = game.debugManualZoom;
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
        expect(game.paused, isTrue);

        game.resetCameraView();
        await tester.tap(
          find.bySemanticsLabel('Reset camera to controlled unit'),
        );
        await tester.tap(find.bySemanticsLabel('Tactical map'));
        await tester.pump();
        expect(game.debugCameraCenter, lifecycleCenter);
        expect(game.debugManualZoom, lifecycleZoom);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
      },
    );
  });
}
