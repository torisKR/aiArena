import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/design/tokens.dart';
import 'package:tokenfront/game/recovery.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/game/tokenfront_game.dart';
import 'package:tokenfront/l10n/l10n.dart';
import 'package:tokenfront/story/story_catalog.dart';
import 'package:tokenfront/story/story_models.dart';
import 'package:tokenfront/ui/recovery_hud.dart';

TokenfrontGame _recoveryGame() => TokenfrontGame(
  playerFaction: Faction.amethyst,
  mode: GameMode.chronicle,
  operation: StoryCatalog.byId(StoryOperationId.wake),
  recoveryMode: true,
  config: RecoveryState.config,
  audioEnabled: false,
  hapticsEnabled: false,
  reduceMotion: true,
  onBattleConcluded: (_) {},
);

Offset _recoveryWorldToScreen(Vec2 world, Size canvas, {double zoom = 0.92}) {
  final cx = RecoveryState.config.worldWidth / 2;
  final cy = RecoveryState.config.worldHeight / 2;
  return Offset(
    canvas.width / 2 + (world.x - cx) * zoom,
    canvas.height / 2 + (world.y - cy) * zoom,
  );
}

void main() {
  for (final locale in ['en', 'ko', 'ja', 'zh']) {
    for (final size in [
      const Size(375, 667),
      const Size(768, 375),
      const Size(1280, 720),
      const Size(2640, 1080),
    ]) {
      testWidgets('recovery $locale fits $size and selects destination', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final game = _recoveryGame();
        addTearDown(game.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTokenfrontTheme(),
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: RecoveryHud(
                game: game,
                snapshot: game.hud.value,
                paused: false,
                enabled: true,
                onPause: () {},
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final context = tester.element(find.byType(RecoveryHud));
        expect(find.text(context.l10n.recoveryInstruction), findsOneWidget);
        expect(
          find.text(context.l10n.recoveryChooseDestination),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('recovery-destination-1')));
        await tester.pump();
        expect(game.simulation.recovery!.selected, 1);
        expect(find.text(context.l10n.recoveryInstruction), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'destination nodes and base stay inside the 2640x1080 arena viewport',
    (tester) async {
      const size = Size(2640, 1080);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final game = _recoveryGame();
      addTearDown(game.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTokenfrontTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RecoveryHud(
              game: game,
              snapshot: game.hud.value,
              paused: false,
              enabled: true,
              onPause: () {},
            ),
          ),
        ),
      );

      final dest0 = tester.getRect(
        find.byKey(const Key('recovery-destination-0')),
      );
      final dest1 = tester.getRect(
        find.byKey(const Key('recovery-destination-1')),
      );
      final dest2 = tester.getRect(
        find.byKey(const Key('recovery-destination-2')),
      );
      final pause = tester.getRect(find.byKey(const Key('battle-pause')));
      final leftRail = tester.getRect(
        find.byKey(const Key('recovery-left-rail')),
      );
      final rightRail = tester.getRect(
        find.byKey(const Key('recovery-right-rail')),
      );

      expect(dest0.right, lessThanOrEqualTo(400));
      expect(dest1.left, greaterThanOrEqualTo(2200));
      expect(dest2.left, greaterThanOrEqualTo(2200));
      expect(dest0.width, greaterThanOrEqualTo(152));
      expect(dest0.height, greaterThanOrEqualTo(72));
      expect(dest1.width, greaterThanOrEqualTo(152));
      expect(dest1.height, greaterThanOrEqualTo(72));
      expect(dest2.width, greaterThanOrEqualTo(152));
      expect(dest2.height, greaterThanOrEqualTo(72));
      expect(dest0.center.dy, greaterThanOrEqualTo(480));
      expect(dest1.center.dy, greaterThanOrEqualTo(480));
      expect(dest2.center.dy, greaterThanOrEqualTo(480));
      expect(dest1.bottom + 8, lessThanOrEqualTo(dest2.top + 0.5));
      expect(pause.bottom + 8, lessThanOrEqualTo(dest1.top));
      expect(pause.top, greaterThanOrEqualTo(8));

      const hinge = Rect.fromLTRB(1180, 0, 1460, 1080);
      expect(dest0.overlaps(hinge), isFalse);
      expect(dest1.overlaps(hinge), isFalse);
      expect(dest2.overlaps(hinge), isFalse);

      expect(dest0.width >= 700 && dest0.top >= 800, isFalse);
      expect(dest1.width >= 700 && dest1.top >= 800, isFalse);
      expect(dest2.width >= 700 && dest2.top >= 800, isFalse);
      expect(leftRail.width, lessThan(0.40 * size.width));
      expect(rightRail.width, lessThan(0.40 * size.width));

      final viewport = Rect.fromLTRB(
        leftRail.right,
        leftRail.top,
        rightRail.left,
        leftRail.bottom,
      );
      expect(viewport.width, greaterThanOrEqualTo(1900));
      expect(viewport.height, greaterThanOrEqualTo(1000));

      const zoom = 0.92;
      final clearance = viewport.deflate(16);
      for (final world in RecoveryState.destinations) {
        final center = _recoveryWorldToScreen(world, size, zoom: zoom);
        final ring = Rect.fromCircle(
          center: center,
          radius: RecoveryState.radius * zoom,
        );
        expect(clearance.contains(ring.topLeft), isTrue);
        expect(clearance.contains(ring.bottomRight), isTrue);
        expect(ring.overlaps(leftRail), isFalse);
        expect(ring.overlaps(rightRail), isFalse);
        expect(ring.overlaps(dest0), isFalse);
        expect(ring.overlaps(dest1), isFalse);
        expect(ring.overlaps(dest2), isFalse);
      }
    },
  );

  testWidgets('top HUD and dest rails respect a display-cutout inset', (
    tester,
  ) async {
    const size = Size(2640, 1080);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding.zero;
    tester.view.viewPadding = const FakeViewPadding(left: 94, top: 94);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    final game = _recoveryGame();
    addTearDown(game.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTokenfrontTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RecoveryHud(
            game: game,
            snapshot: game.hud.value,
            paused: false,
            enabled: true,
            onPause: () {},
          ),
        ),
      ),
    );

    for (final finder in [
      find.byKey(const Key('recovery-destination-0')),
      find.byKey(const Key('recovery-destination-1')),
      find.byKey(const Key('recovery-destination-2')),
      find.byKey(const Key('battle-pause')),
      find.byKey(const Key('recovery-left-rail')),
      find.byKey(const Key('recovery-right-rail')),
    ]) {
      final rect = tester.getRect(finder);
      expect(rect.left, greaterThanOrEqualTo(94));
      expect(rect.top, greaterThanOrEqualTo(94));
      expect(rect.bottom, lessThanOrEqualTo(1080));
    }

    final unclampedTop = combatFlashLabelCanvasTop(
      eventCanvasY: 5,
      minCanvasY: 8,
    );
    expect(unclampedTop, 8);

    final cutoutTop = combatFlashLabelCanvasTop(
      eventCanvasY: 5,
      minCanvasY: 94,
    );
    expect(cutoutTop, greaterThanOrEqualTo(94));
    expect(tester.takeException(), isNull);
  });

  test('combat flash label canvas top stays below a top inset', () {
    expect(combatFlashLabelCanvasTop(eventCanvasY: 40, minCanvasY: 8), 22);
    expect(combatFlashLabelCanvasTop(eventCanvasY: 10, minCanvasY: 8), 8);
    expect(combatFlashLabelCanvasTop(eventCanvasY: 10, minCanvasY: 94), 94);
  });
}
