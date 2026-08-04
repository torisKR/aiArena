import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/services/battle_orientation_controller.dart';
import 'package:tokenfront/services/privacy/privacy_state.dart';
import 'package:tokenfront/settings/game_preferences.dart';
import 'package:tokenfront/ui/battle_screen.dart';
import 'package:tokenfront/ui/result_screen.dart';
import 'package:tokenfront/main.dart';

void main() {
  group('BattleOrientationController', () {
    for (final platform in [ClientPlatform.android, ClientPlatform.ios]) {
      test(
        '${platform.name} phone locks landscape and restores OS defaults',
        () async {
          final calls = <List<DeviceOrientation>>[];
          final controller = BattleOrientationController(
            platform: platform,
            setter: (orientations) async => calls.add(List.of(orientations)),
          );

          expect(
            controller.requiresLandscape(logicalShortestSide: 390),
            isTrue,
          );
          await controller.enterBattle(logicalShortestSide: 390);
          await controller.restore();

          expect(calls, [
            [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
            <DeviceOrientation>[],
          ]);
        },
      );
    }

    test(
      'web phone requests a best-effort lock and gates portrait play',
      () async {
        final calls = <List<DeviceOrientation>>[];
        final controller = BattleOrientationController(
          platform: ClientPlatform.web,
          setter: (orientations) async => calls.add(List.of(orientations)),
        );

        expect(controller.requiresLandscape(logicalShortestSide: 390), isTrue);
        await controller.enterBattle(logicalShortestSide: 390);
        await controller.restore();
        expect(calls, [
          [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
          <DeviceOrientation>[],
        ]);
      },
    );

    test('desktop and 600dp Android displays are not locked', () async {
      for (final platform in [ClientPlatform.other]) {
        final calls = <List<DeviceOrientation>>[];
        final controller = BattleOrientationController(
          platform: platform,
          setter: (orientations) async => calls.add(List.of(orientations)),
        );
        expect(controller.requiresLandscape(logicalShortestSide: 390), isFalse);
        await controller.enterBattle(logicalShortestSide: 390);
        expect(calls, isEmpty);
      }

      final calls = <List<DeviceOrientation>>[];
      final tablet = BattleOrientationController(
        platform: ClientPlatform.android,
        setter: (orientations) async => calls.add(List.of(orientations)),
      );
      expect(tablet.requiresLandscape(logicalShortestSide: 600), isFalse);
      await tablet.enterBattle(logicalShortestSide: 600);
      expect(calls, isEmpty);
    });
  });

  testWidgets('portrait mobile web requests landscape and gates battle', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.display.size = const Size(390, 844);
    tester.view.display.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.display.reset);
    final calls = <List<DeviceOrientation>>[];
    final controller = BattleOrientationController(
      platform: ClientPlatform.web,
      setter: (orientations) async => calls.add(List.of(orientations)),
    );
    final runtime = TokenfrontRuntime(
      platform: ClientPlatform.web,
      preferences: GamePreferences(audioEnabled: false, hapticsEnabled: false),
    );
    addTearDown(runtime.dispose);

    await tester.pumpWidget(
      TokenfrontApp(runtime: runtime, orientationController: controller),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('skirmish-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AMETHYST').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('skirmish-deploy')));
    await tester.tap(find.byKey(const Key('skirmish-deploy')));
    await tester.pump();
    await tester.pump();

    expect(calls.single, [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    expect(find.byType(BattleScreen), findsOneWidget);
    expect(find.byKey(const Key('landscape-required')), findsOneWidget);
    expect(find.byKey(const Key('battle-game-surface')), findsNothing);
  });

  testWidgets(
    'lifecycle pause during orientation await pauses battle on mount',
    (tester) async {
      tester.view.display.size = const Size(390, 844);
      tester.view.display.devicePixelRatio = 1;
      addTearDown(tester.view.display.reset);
      addTearDown(() {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      });
      final orientationRequest = Completer<void>();
      final controller = BattleOrientationController(
        platform: ClientPlatform.web,
        setter: (_) => orientationRequest.future,
      );
      final runtime = TokenfrontRuntime(
        platform: ClientPlatform.web,
        preferences: GamePreferences(
          audioEnabled: false,
          hapticsEnabled: false,
        ),
      );
      addTearDown(runtime.dispose);
      await tester.pumpWidget(
        TokenfrontApp(runtime: runtime, orientationController: controller),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('skirmish-mode')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('skirmish-deploy')));
      await tester.tap(find.byKey(const Key('skirmish-deploy')));
      await tester.pump();
      expect(find.byType(BattleScreen), findsNothing);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      orientationRequest.complete();
      await tester.pump();
      await tester.pump();

      final battle = tester.widget<BattleScreen>(find.byType(BattleScreen));
      expect(battle.lifecycleState, AppLifecycleState.inactive);
      expect(battle.game.paused, isTrue);
    },
  );

  testWidgets('battle entry locks a phone and match end restores it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.display.size = const Size(390, 844);
    tester.view.display.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.display.reset);
    final calls = <List<DeviceOrientation>>[];
    final controller = BattleOrientationController(
      platform: ClientPlatform.android,
      setter: (orientations) async => calls.add(List.of(orientations)),
    );
    final runtime = TokenfrontRuntime(
      platform: ClientPlatform.android,
      preferences: GamePreferences(audioEnabled: false, hapticsEnabled: false),
    );
    addTearDown(runtime.dispose);

    await tester.pumpWidget(
      TokenfrontApp(runtime: runtime, orientationController: controller),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('skirmish-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AMETHYST').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('skirmish-deploy')));
    await tester.tap(find.byKey(const Key('skirmish-deploy')));
    await tester.pump();
    await tester.pump();

    expect(calls.single, [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    expect(find.byType(BattleScreen), findsOneWidget);

    final battle = tester.widget<BattleScreen>(find.byType(BattleScreen));
    battle.game.simulation.finalizeAtTimeLimit();
    battle.game.update(1 / 60);
    await tester.pump();
    await tester.pump();

    expect(calls.last, isEmpty);
    expect(find.byType(ResultScreen), findsOneWidget);
  });
}
