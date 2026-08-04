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
import 'package:tokenfront/ui/battle_screen.dart';

TokenfrontGame _game({
  bool reduceMotion = false,
  bool lowSpecMode = false,
  bool mouseCameraEnabled = true,
  BattleConfig config = const BattleConfig(unitsPerFaction: 20),
}) => TokenfrontGame(
  playerFaction: Faction.amethyst,
  config: config,
  reduceMotion: reduceMotion,
  lowSpecMode: lowSpecMode,
  mouseCameraEnabled: mouseCameraEnabled,
  hapticsEnabled: false,
  audioEnabled: false,
  onBattleConcluded: (_) {},
);

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

Widget _localizedBattle(Widget home) => MaterialApp(
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
  });
}
