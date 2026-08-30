import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/design/tokens.dart';
import 'package:tokenfront/ui/living_relay_thread.dart';

void main() {
  test('painter keeps five nodes, four route segments, and a 2 px stroke', () {
    const painter = LivingRelayThreadPainter(
      variant: LivingRelayThreadVariant.horizontalProgress,
    );
    expect(LivingRelayThread.nodeCount, 5);
    expect(LivingRelayThread.routeSegmentCount, 4);
    expect(painter.baseStrokeWidth, TokenfrontSizes.threadStroke);
    expect(
      LivingRelayThreadNode(
        state: LivingRelayThreadNodeState.active,
      ).paintColor,
      TokenfrontColors.threadCyan,
    );
    expect(
      LivingRelayThreadNode(
        state: LivingRelayThreadNodeState.confirmed,
      ).paintColor,
      TokenfrontColors.relayIvory,
    );
    expect(
      LivingRelayThreadNode(
        state: LivingRelayThreadNodeState.locked,
      ).paintColor,
      TokenfrontColors.archiveAsh,
    );
    expect(
      LivingRelayThreadNode(
        state: LivingRelayThreadNodeState.faction,
        factionColor: TokenfrontColors.amethyst,
      ).paintColor,
      TokenfrontColors.amethyst,
    );
  });

  testWidgets('all variants paint and expose caller-provided semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      for (final variant in LivingRelayThreadVariant.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 320,
                height: 200,
                child: LivingRelayThread(
                  variant: variant,
                  progress: .6,
                  charge: .4,
                  fragment: 'FOUR CORES',
                  semanticLabel: 'localized relay thread',
                  semanticHint: 'localized route status',
                  reducedMotion: true,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final customPaintFinder = find.descendant(
          of: find.byType(LivingRelayThread),
          matching: find.byType(CustomPaint),
        );
        expect(customPaintFinder, findsOneWidget);
        expect(find.bySemanticsLabel('localized relay thread'), findsOneWidget);
        final thread = tester.widget<LivingRelayThread>(
          find.byType(LivingRelayThread),
        );
        expect(thread.animationsEnabled, isFalse);
        final customPaint = tester.widget<CustomPaint>(customPaintFinder);
        expect(customPaint.painter, isA<LivingRelayThreadPainter>());
        expect(
          (customPaint.painter! as LivingRelayThreadPainter).baseStrokeWidth,
          2,
        );
        expect(tester.takeException(), isNull);
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'animation can toggle off and on without reusing a disposed ticker',
    (tester) async {
      Future<void> pumpThread({bool reducedMotion = false}) {
        return tester.pumpWidget(
          MaterialApp(
            home: LivingRelayThread(
              reducedMotion: reducedMotion,
              semanticLabel: 'relay thread',
            ),
          ),
        );
      }

      await pumpThread();
      expect(
        tester
            .widget<LivingRelayThread>(find.byType(LivingRelayThread))
            .animationsEnabled,
        isTrue,
      );
      await pumpThread(reducedMotion: true);
      await tester.pump();
      expect(
        tester
            .widget<LivingRelayThread>(find.byType(LivingRelayThread))
            .animationsEnabled,
        isFalse,
      );
      await pumpThread();
      await tester.pump();
      expect(
        tester
            .widget<LivingRelayThread>(find.byType(LivingRelayThread))
            .animationsEnabled,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('low-spec mode also disables animation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LivingRelayThread(lowSpec: true, semanticLabel: 'relay thread'),
      ),
    );
    expect(
      tester
          .widget<LivingRelayThread>(find.byType(LivingRelayThread))
          .animationsEnabled,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('animated directive cue completes so pumpAndSettle can settle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: LivingRelayThread(semanticLabel: 'relay thread')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LivingRelayThread>(find.byType(LivingRelayThread))
          .animationsEnabled,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
