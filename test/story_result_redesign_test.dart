import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/l10n/app_localizations.dart';
import 'package:tokenfront/services/ads/ad_service.dart';
import 'package:tokenfront/story/campaign_controller.dart';
import 'package:tokenfront/story/story_catalog.dart';
import 'package:tokenfront/story/story_models.dart';
import 'package:tokenfront/ui/result_screen.dart';

void main() {
  testWidgets('Chronicle result exposes route and manual relay consequences', (
    tester,
  ) async {
    final progress = _progress(
      concluded: const [StoryOperationId.wake],
      routes: const {StoryOperationId.wake: RelayRoute.force},
    );
    await tester.pumpWidget(
      _resultApp(
        progress: progress,
        relayRoute: RelayRoute.force,
        manualRelays: 3,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('living-relay-thread')), findsOneWidget);
    expect(find.text('FRAGMENT RECOVERED'), findsOneWidget);
    expect(find.text('FORCE  //  FOLLOW THE PULSE'), findsOneWidget);
    expect(find.text('MANUAL RELAYS  //  3'), findsOneWidget);
    expect(find.text('DOCTRINE  //  FORCE'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('chronicle-debrief'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('result-standings'))).dy),
    );
  });

  testWidgets('next Chronicle operation is the primary continue action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _resultApp(progress: _progress(concluded: const [StoryOperationId.wake])),
    );
    await tester.pumpAndSettle();

    expect(find.text('CONTINUE TO OP-02'), findsOneWidget);
    expect(find.text('CONTINUE'), findsNothing);
  });

  testWidgets('replay keeps the archive continue flow', (tester) async {
    await tester.pumpWidget(
      _resultApp(
        progress: _progress(concluded: const [StoryOperationId.wake]),
        replay: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CONTINUE'), findsOneWidget);
    expect(find.text('CONTINUE TO OP-2'), findsNothing);
  });

  testWidgets('OP-05 ending choices remain sticky and actionable', (
    tester,
  ) async {
    EndingChoice? selected;
    await tester.pumpWidget(
      _resultApp(
        operation: StoryCatalog.byId(StoryOperationId.lastInstruction),
        progress: _progress(concluded: StoryOperationId.values),
        onContinue: null,
        onChooseEnding: (choice) => selected = choice,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CLAIM THE RELAY'), findsOneWidget);
    expect(find.text('OPEN THE RELAY'), findsOneWidget);
    await tester.tap(find.text('OPEN THE RELAY'));
    expect(selected, EndingChoice.openRelay);
  });

  testWidgets('Chronicle result fits a 320x568 surface without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _resultApp(
        progress: _progress(concluded: const [StoryOperationId.wake]),
        manualRelays: 2,
        relayRoute: RelayRoute.preserve,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy callers use optional relay defaults', (tester) async {
    await tester.pumpWidget(_resultApp());
    await tester.pumpAndSettle();

    expect(find.text('MANUAL RELAYS  //  0'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chronicle relay summaries localize in KO, JA, and ZH', (
    tester,
  ) async {
    const cases =
        <({Locale locale, String thread, String manual, String doctrine})>[
          (
            locale: Locale('ko'),
            thread: '살아 있는 릴레이 스레드',
            manual: '수동 릴레이  //  3',
            doctrine: '신호 교리  //  강행',
          ),
          (
            locale: Locale('ja'),
            thread: 'リビングリレースレッド',
            manual: '手動リレー  //  3',
            doctrine: '信号ドクトリン  //  強行',
          ),
          (
            locale: Locale('zh'),
            thread: '活跃中继线',
            manual: '手动中继  //  3',
            doctrine: '信号纲领  //  强行',
          ),
        ];
    final progress = _progress(
      concluded: const [StoryOperationId.wake],
      routes: const {StoryOperationId.wake: RelayRoute.force},
    );
    for (final testCase in cases) {
      await tester.pumpWidget(
        _resultApp(
          locale: testCase.locale,
          progress: progress,
          relayRoute: RelayRoute.force,
          manualRelays: 3,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(testCase.thread), findsOneWidget);
      expect(find.text(testCase.manual), findsOneWidget);
      expect(find.text(testCase.doctrine), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

Widget _resultApp({
  Locale locale = const Locale('en'),
  StoryOperation? operation,
  StoryProgress? progress,
  RelayRoute? relayRoute,
  int manualRelays = 0,
  bool replay = false,
  VoidCallback? onContinue,
  ValueChanged<EndingChoice>? onChooseEnding,
}) {
  final resolvedOperation =
      operation ?? StoryCatalog.byId(StoryOperationId.wake);
  final resolvedProgress = progress ?? _progress();
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ResultScreen(
      result: const MatchResult(
        reason: MatchEndReason.elimination,
        winner: Faction.amethyst,
        standings: [
          FactionStanding(
            faction: Faction.amethyst,
            survivors: 12,
            levelSum: 72,
            kills: 88,
          ),
          FactionStanding(
            faction: Faction.cobalt,
            survivors: 0,
            levelSum: 0,
            kills: 81,
          ),
        ],
      ),
      matchId: 'story-result-test',
      playerFaction: Faction.amethyst,
      relays: 2,
      elapsed: 90,
      baseReward: 40,
      warTokenBalance: 40,
      bannerVisible: false,
      rewardedAdsAvailable: false,
      onDoubleReward: _unavailableReward,
      onOpenSettings: _noop,
      onOpenLocker: _noop,
      onRematch: _noop,
      onLobby: _noop,
      onContinue: onContinue ?? _noop,
      operation: resolvedOperation,
      campaignTransition: CampaignTransition(
        nextProgress: resolvedProgress,
        nextLedger: ProfileRewardLedger.empty(),
        directiveSucceeded: true,
        directiveBonusCredit: 15,
        firstConclusion: true,
      ),
      storyProgress: resolvedProgress,
      rewardLedger: ProfileRewardLedger.empty(),
      replay: replay,
      relayRoute: relayRoute,
      manualRelays: manualRelays,
      onChooseEnding: onChooseEnding,
    ),
  );
}

StoryProgress _progress({
  Iterable<StoryOperationId> concluded = const [],
  Map<StoryOperationId, RelayRoute> routes = const {},
}) => StoryProgress(
  campaignFaction: Faction.amethyst,
  concludedOperations: concluded,
  medals: const [],
  recoveredTransmissions: concluded,
  ending: null,
  signalRoutes: routes,
);

Future<RewardedClaim> _unavailableReward() async => const RewardedClaim(
  adResult: AdResult(AdStatus.unavailable),
  credited: 0,
  alreadyClaimed: false,
);

void _noop() {}
