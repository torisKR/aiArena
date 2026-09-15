import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/design/tokens.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/l10n/l10n.dart';
import 'package:tokenfront/story/story_models.dart';
import 'package:tokenfront/ui/archive_sheet.dart';
import 'package:tokenfront/ui/lobby_screen.dart';
import 'package:tokenfront/ui/orbital_progress_ring.dart';
import 'package:tokenfront/ui/primitives.dart';

Widget _localized(Widget child, {Locale? locale}) => MaterialApp(
  theme: buildTokenfrontTheme(),
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

LobbyScreen _lobby({StoryProgress? progress, bool reduceMotion = true}) {
  return LobbyScreen(
    selectedMode: GameMode.chronicle,
    storyProgress: progress ?? StoryProgress.initial(),
    rewardLedger: ProfileRewardLedger.empty(),
    selectedChronicleFaction: Faction.amethyst,
    selectedSkirmishFaction: Faction.amethyst,
    onSelectChronicleCore: (_) {},
    onSelectSkirmishFaction: (_) {},
    onDeployChronicle: () {},
    onDeploySkirmish: () {},
    onOpenArchive: () {},
    warTokenBalance: 0,
    onOpenSettings: () {},
    onOpenLocker: () {},
    bannerVisible: false,
    reduceMotion: reduceMotion,
  );
}

void main() {
  const locales = [Locale('en'), Locale('ko'), Locale('ja'), Locale('zh')];

  testWidgets(
    'Command Deck leads with role, current operation, voice, and Brief CTA',
    (tester) async {
      await tester.pumpWidget(_localized(_lobby()));
      await tester.pumpAndSettle();

      expect(find.text('COMMAND THE TOKEN FLOW.'), findsOneWidget);
      expect(find.text('OP-01  //  WAKE // DEAD ORBIT'), findsOneWidget);
      expect(
        find.byKey(const Key('current-operation-incident')),
        findsOneWidget,
      );
      expect(find.text('Recover three signals'), findsNWidgets(2));
      expect(find.textContaining('Tap 1, 2 or 3'), findsOneWidget);
    },
  );

  testWidgets(
    'Orbital thread exposes five nodes and reduced-motion semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _localized(
          OrbitalProgressRing(
            progress: StoryProgress.initial(),
            lowSpec: true,
            reduceMotion: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('COMMAND DECK // 0 of 5')),
        findsOneWidget,
      );
      expect(find.byType(OrbitalProgressRing), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'Archive shows canonical route, hides undecided pattern, and reveals teasers',
    (tester) async {
      final progress = StoryProgress(
        campaignFaction: Faction.amethyst,
        concludedOperations: const [StoryOperationId.wake],
        medals: const [],
        recoveredTransmissions: const [StoryOperationId.wake],
        ending: null,
        signalRoutes: const {StoryOperationId.wake: RelayRoute.preserve},
      );
      await tester.pumpWidget(
        _localized(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showSignalArchive(
                  context: context,
                  storyProgress: progress,
                  rewardLedger: ProfileRewardLedger.empty(),
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('canonical-route-wake')), findsOneWidget);
      expect(find.text('PRESERVE'), findsOneWidget);
      expect(find.byKey(const Key('routing-pattern')), findsOneWidget);
      expect(find.text('FALSE WINNER?'), findsOneWidget);
      expect(find.text('THE INSTRUCTION?'), findsOneWidget);
    },
  );

  testWidgets('Command Deck remains overflow-safe at 320x568', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_localized(_lobby(reduceMotion: true)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Deck and Archive stay clipped-safe in every supported locale', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    for (final locale in locales) {
      for (final size in [const Size(320, 568), const Size(390, 844)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(_localized(_lobby(), locale: locale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$locale $size deck');

        await tester.pumpWidget(
          _localized(
            Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showSignalArchive(
                    context: context,
                    storyProgress: StoryProgress.initial(),
                    rewardLedger: ProfileRewardLedger.empty(),
                  ),
                  child: const Text('OPEN'),
                ),
              ),
            ),
            locale: locale,
          ),
        );
        await tester.tap(find.text('OPEN'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$locale $size archive');
        expect(
          find.byKey(const Key('archive-living-relay-thread')),
          findsOneWidget,
        );
        expect(find.byType(TacticalPanel), findsNothing);
        expect(
          tester
              .getSemantics(
                find.byKey(const Key('archive-living-relay-thread')),
              )
              .label,
          isNotEmpty,
        );
        Navigator.of(
          tester.element(find.byKey(const Key('archive-living-relay-thread'))),
        ).pop();
        await tester.pumpAndSettle();
      }
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    semantics.dispose();
  });
}
