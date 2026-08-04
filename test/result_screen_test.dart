import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/l10n/app_localizations_en.dart';
import 'package:tokenfront/l10n/l10n.dart';
import 'package:tokenfront/services/ads/ad_service.dart';
import 'package:tokenfront/story/campaign_controller.dart';
import 'package:tokenfront/story/story_catalog.dart';
import 'package:tokenfront/story/story_localizations.dart';
import 'package:tokenfront/story/story_models.dart';
import 'package:tokenfront/ui/result_screen.dart';

void main() {
  testWidgets('Chronicle debrief renders every operation reveal', (
    tester,
  ) async {
    final copy = StoryLocalizations(AppLocalizationsEn());
    for (final id in StoryOperationId.values) {
      await tester.pumpWidget(_resultApp(StoryCatalog.byId(id)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chronicle-debrief')), findsOneWidget);
      expect(find.text(copy.reveal(id)), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('narrow Chronicle actions stay below the final scroll content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _resultApp(StoryCatalog.byId(StoryOperationId.wake)),
    );
    await tester.pumpAndSettle();

    final actionLayer = find.byKey(const Key('chronicle-action-layer'));
    expect(actionLayer, findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
    expect(find.text('RETRY DIRECTIVE'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('result-scroll-end')));
    await tester.pump();

    final actionRect = tester.getRect(actionLayer);
    final contentEndRect = tester.getRect(
      find.byKey(const Key('result-scroll-end')),
    );
    expect(contentEndRect.bottom, lessThanOrEqualTo(actionRect.top));
    expect(actionRect.bottom, lessThanOrEqualTo(568));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'narrow OP-05 ending actions stay below the final scroll content',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final progress = StoryProgress(
        campaignFaction: Faction.amethyst,
        concludedOperations: StoryOperationId.values,
        medals: const [],
        recoveredTransmissions: StoryOperationId.values,
        ending: null,
      );
      await tester.pumpWidget(
        _resultApp(
          StoryCatalog.byId(StoryOperationId.lastInstruction),
          progressOverride: progress,
          onContinue: null,
          onChooseEnding: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      final actionLayer = find.byKey(const Key('chronicle-action-layer'));
      expect(actionLayer, findsOneWidget);
      expect(find.text('CLAIM THE RELAY'), findsOneWidget);
      expect(find.text('OPEN THE RELAY'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('result-scroll-end')));
      await tester.pump();
      expect(
        tester.getRect(find.byKey(const Key('result-scroll-end'))).bottom,
        lessThanOrEqualTo(tester.getRect(actionLayer).top),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _resultApp(
  StoryOperation operation, {
  StoryProgress? progressOverride,
  VoidCallback? onContinue,
  ValueChanged<EndingChoice>? onChooseEnding,
}) {
  final progress =
      progressOverride ??
      StoryProgress(
        campaignFaction: Faction.amethyst,
        concludedOperations: const [],
        medals: const [],
        recoveredTransmissions: const [],
        ending: null,
      );
  return MaterialApp(
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
      matchId: 'result-test',
      playerFaction: Faction.amethyst,
      relays: 2,
      elapsed: 90,
      baseReward: 40,
      warTokenBalance: 40,
      bannerVisible: false,
      rewardedAdsAvailable: true,
      onDoubleReward: _unavailableReward,
      onOpenSettings: _noop,
      onOpenLocker: _noop,
      onRematch: _noop,
      onLobby: _noop,
      onContinue: onContinue ?? _noop,
      operation: operation,
      campaignTransition: CampaignTransition(
        nextProgress: progress,
        nextLedger: ProfileRewardLedger.empty(),
        directiveSucceeded: false,
        directiveBonusCredit: 0,
        firstConclusion: true,
      ),
      storyProgress: progress,
      rewardLedger: ProfileRewardLedger.empty(),
      onChooseEnding: onChooseEnding,
    ),
  );
}

Future<RewardedClaim> _unavailableReward() async => const RewardedClaim(
  adResult: AdResult(AdStatus.unavailable),
  credited: 0,
  alreadyClaimed: false,
);

void _noop() {}
