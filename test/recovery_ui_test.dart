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

void main() {
  for (final locale in ['en', 'ko', 'ja', 'zh']) {
    for (final size in [
      const Size(375, 667),
      const Size(768, 375),
      const Size(1280, 720),
    ]) {
      testWidgets('recovery $locale fits $size and selects destination', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final game = TokenfrontGame(
          playerFaction: Faction.amethyst,
          mode: GameMode.chronicle,
          operation: StoryCatalog.byId(StoryOperationId.wake),
          recoveryMode: true,
          config: RecoveryState.config,
          audioEnabled: false,
          hapticsEnabled: false,
          onBattleConcluded: (_) {},
        );
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
        await tester.tap(find.byKey(const Key('recovery-destination-1')));
        await tester.pump();
        expect(game.simulation.recovery!.selected, 1);
        expect(find.text(context.l10n.recoveryInstruction), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
