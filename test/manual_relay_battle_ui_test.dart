import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/design/tokens.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/game/tokenfront_game.dart';
import 'package:tokenfront/l10n/l10n.dart';
import 'package:tokenfront/story/story_catalog.dart';
import 'package:tokenfront/story/story_models.dart';
import 'package:tokenfront/ui/battle_screen.dart';

const _relayOperation = StoryOperation(
  id: StoryOperationId.wake,
  seed: 2026080505,
  duration: Duration(seconds: 180),
  directive: Directive(kind: DirectiveKind.longestCommandLink, target: 45),
  oneTimeBonus: 25,
);

TokenfrontGame _game({
  StoryOperation? operation,
  BattleConfig config = const BattleConfig(unitsPerFaction: 2),
}) => TokenfrontGame(
  playerFaction: Faction.amethyst,
  mode: operation == null ? GameMode.skirmish : GameMode.chronicle,
  operation: operation,
  relayRoute: RelayRoute.preserve,
  config: config,
  hapticsEnabled: false,
  audioEnabled: false,
  onBattleConcluded: (_) {},
);

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  theme: buildTokenfrontTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  testWidgets('Chronicle starts with story rail and ready Relay', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = _game(operation: _relayOperation);
    await tester.pumpWidget(
      _app(BattleScreen(game: game, requireLandscape: true)),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('story-operation-title')), findsOneWidget);
    expect(find.byKey(const Key('story-operation-incident')), findsOneWidget);
    final l10nContext = tester.element(find.byKey(const Key('relay-control')));
    expect(find.text(l10nContext.l10n.relayReady), findsOneWidget);
    expect(find.byKey(const Key('living-relay-thread')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('relay-control'))),
      const Size(72, 72),
    );
    expect(
      tester.getSize(find.byKey(const Key('living-relay-thread'))).height,
      2,
    );
  });

  testWidgets('Skirmish keeps Relay hidden', (tester) async {
    final game = _game();
    await tester.pumpWidget(_app(BattleScreen(game: game)));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('relay-control')), findsNothing);
    expect(find.byKey(const Key('story-operation-title')), findsNothing);
  });

  testWidgets('queued receiver-less Relay shows localized no receiver', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = _game(
      operation: _relayOperation,
      config: const BattleConfig(unitsPerFaction: 1),
    );
    await tester.pumpWidget(_app(BattleScreen(game: game)));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(
      find.byKey(const Key('relay-control')),
      warnIfMissed: false,
    );
    game.update(.04);
    await tester.pump();
    final context = tester.element(find.byKey(const Key('relay-control')));
    expect(find.text(context.l10n.relayNoReceiver), findsOneWidget);
    expect(game.manualRelayCharge, 1);
  });

  testWidgets('Relay semantics expose route and ready state', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = _game(operation: StoryCatalog.byId(StoryOperationId.wake));
    await tester.pumpWidget(_app(BattleScreen(game: game)));
    await tester.pump(const Duration(milliseconds: 50));
    final semantics = tester.getSemantics(
      find.byKey(const Key('relay-control-semantics')),
    );
    expect(semantics.label, contains('RELAY PRESERVE'));
    expect(semantics.label, contains('RELAY READY'));
    await tester.tap(
      find.byKey(const Key('relay-control')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNotNull);
  });

  testWidgets('Relay copy and semantics are localized beyond English', (
    tester,
  ) async {
    for (final locale in AppLocalizations.supportedLocales.where(
      (value) => value.languageCode != 'en',
    )) {
      final game = _game(operation: _relayOperation);
      await tester.pumpWidget(_app(BattleScreen(game: game), locale: locale));
      await tester.pump(const Duration(milliseconds: 50));
      final context = tester.element(find.byKey(const Key('relay-control')));
      expect(find.text(context.l10n.relayReady), findsOneWidget);
      final semantics = tester.getSemantics(
        find.byKey(const Key('relay-control-semantics')),
      );
      expect(semantics.label, contains(context.l10n.relayAction));
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
