import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/app/tokenfront_state_store.dart';
import 'package:tokenfront/design/tokens.dart';
import 'package:tokenfront/game/recovery.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/l10n/l10n.dart';
import 'package:tokenfront/services/privacy/privacy_state.dart';
import 'package:tokenfront/story/campaign_controller.dart';
import 'package:tokenfront/story/story_models.dart';
import 'package:tokenfront/ui/lobby_screen.dart';
import 'package:tokenfront/ui/primitives.dart';

void main() {
  const controller = CampaignController();

  group('legacy save migration', () {
    test('inline legacy JSON with an ending becomes echo cycle 2 at wake', () {
      const legacy = <String, Object?>{
        'campaignFaction': 'amethyst',
        'concludedOperations': [
          'wake',
          'echo',
          'split',
          'crown',
          'lastInstruction',
        ],
        'medals': ['wake', 'echo', 'split', 'crown', 'lastInstruction'],
        'recoveredTransmissions': [
          'wake',
          'echo',
          'split',
          'crown',
          'lastInstruction',
        ],
        'ending': 'openRelay',
        'signalRoutes': {
          'wake': 'preserve',
          'echo': 'force',
          'split': 'preserve',
          'crown': 'force',
          'lastInstruction': 'preserve',
        },
      };

      final progress = StoryProgress.fromJson(legacy);
      expect(progress.isSemanticallyValid, isTrue);
      expect(progress.campaignFaction, Faction.amethyst);
      expect(
        progress.concludedOperations,
        orderedEquals(StoryOperationId.values),
      );
      expect(progress.medals, orderedEquals(StoryOperationId.values));
      expect(
        progress.recoveredTransmissions,
        orderedEquals(StoryOperationId.values),
      );
      expect(progress.ending, EndingChoice.openRelay);
      expect(progress.signalRoutes, {
        StoryOperationId.wake: RelayRoute.preserve,
        StoryOperationId.echo: RelayRoute.force,
        StoryOperationId.split: RelayRoute.preserve,
        StoryOperationId.crown: RelayRoute.force,
        StoryOperationId.lastInstruction: RelayRoute.preserve,
      });
      expect(progress.echoCycle, 2);
      expect(progress.echoConcludedOperations, isEmpty);
      expect(progress.echoSignalRoutes, isEmpty);
      expect(progress.echoEnding, isNull);
      expect(progress.bestClearSeconds, isEmpty);
      expect(progress.currentOperation, StoryOperationId.wake);
      expect(progress.echoActive, isTrue);
      expect(progress.displayCycle, 2);
    });

    test('inline legacy JSON mid-campaign keeps echo cycle 1', () {
      const legacy = <String, Object?>{
        'campaignFaction': 'amethyst',
        'concludedOperations': ['wake', 'echo'],
        'medals': ['wake'],
        'recoveredTransmissions': ['wake', 'echo'],
        'ending': null,
        'signalRoutes': {'wake': 'preserve', 'echo': 'force'},
      };
      final progress = StoryProgress.fromJson(legacy);
      expect(progress.currentOperation, StoryOperationId.split);
      expect(progress.echoCycle, 1);
      expect(progress.echoConcludedOperations, isEmpty);
      expect(progress.echoActive, isFalse);
    });

    test('invalid echoCycle 0 throws FormatException', () {
      expect(
        () => StoryProgress.fromJson(const {
          'campaignFaction': 'amethyst',
          'concludedOperations': [
            'wake',
            'echo',
            'split',
            'crown',
            'lastInstruction',
          ],
          'medals': <String>[],
          'recoveredTransmissions': [
            'wake',
            'echo',
            'split',
            'crown',
            'lastInstruction',
          ],
          'ending': 'openRelay',
          'echoCycle': 0,
        }),
        throwsFormatException,
      );
    });

    test('schema 3 encode after echo play stays at version 3', () async {
      final store = _MemoryStore();
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      addTearDown(runtime.dispose);
      runtime.lockChronicleCore(Faction.amethyst);
      for (final id in StoryOperationId.values) {
        runtime.concludeChronicle(
          operationId: id,
          report: recoveredReport(),
          replay: false,
        );
      }
      runtime.chooseChronicleEnding(EndingChoice.openRelay);
      runtime.concludeChronicle(
        operationId: StoryOperationId.wake,
        report: recoveredReport(elapsed: 70),
        replay: false,
      );
      await runtime.flushLocalState();
      final persisted = jsonDecode(store.value!) as Map<String, dynamic>;
      expect(persisted['version'], 3);
      expect(persisted.containsKey('version'), isTrue);
      final story = persisted['story'] as Map<String, dynamic>;
      expect(story['echoCycle'], 2);
      expect(story['echoConcludedOperations'], ['wake']);
    });

    test(
      'schema 3 fixture without echo keys restores a playable ending',
      () async {
        final runtime = await TokenfrontRuntime.restore(
          platform: ClientPlatform.web,
          stateStore: _MemoryStore.withValue(
            jsonEncode({
              'version': 3,
              'wallet': {
                'balance': 275,
                'unlockedIds': <String>[],
                'equippedIds': <String, String>{},
              },
              'preferences': {
                'lowSpecMode': false,
                'forceReducedMotion': false,
                'mouseCameraEnabled': true,
                'hapticsEnabled': true,
                'audioEnabled': true,
                'languageCode': 'en',
              },
              'privacy': {
                'analyticsSharingAllowed': false,
                'adRequestsAllowed': false,
              },
              'story': {
                'campaignFaction': 'amethyst',
                'concludedOperations': [
                  'wake',
                  'echo',
                  'split',
                  'crown',
                  'lastInstruction',
                ],
                'medals': ['wake'],
                'recoveredTransmissions': [
                  'wake',
                  'echo',
                  'split',
                  'crown',
                  'lastInstruction',
                ],
                'ending': 'openRelay',
              },
              'rewardLedger': {
                'claimedDirectiveBonusIds': ['chronicle-directive-wake'],
              },
            }),
          ),
        );
        addTearDown(runtime.dispose);
        expect(runtime.storyProgress.currentOperation, StoryOperationId.wake);
        expect(runtime.storyProgress.echoCycle, 2);
        expect(runtime.storyProgress.campaignFaction, Faction.amethyst);
        expect(runtime.storyProgress.medals, {StoryOperationId.wake});
        expect(runtime.storyProgress.ending, EndingChoice.openRelay);
        expect(runtime.wallet.balance, 275);
        expect(
          runtime.rewardLedger.claimedDirectiveBonusIds,
          contains('chronicle-directive-wake'),
        );
      },
    );
  });

  group('lobby after ending', () {
    testWidgets('chronicle-deploy is enabled with echoDeploy after an ending', (
      tester,
    ) async {
      final progress = StoryProgress.fromJson(const {
        'campaignFaction': 'amethyst',
        'concludedOperations': [
          'wake',
          'echo',
          'split',
          'crown',
          'lastInstruction',
        ],
        'medals': ['wake'],
        'recoveredTransmissions': [
          'wake',
          'echo',
          'split',
          'crown',
          'lastInstruction',
        ],
        'ending': 'openRelay',
      });
      await tester.pumpWidget(_localized(_lobby(progress: progress)));
      await tester.pumpAndSettle();

      final deploy = find.byKey(const Key('chronicle-deploy'));
      expect(deploy, findsOneWidget);
      final button = tester.widget<TacticalButton>(deploy);
      expect(button.onPressed, isNotNull);
      expect(button.label, 'Recover the echo');
      expect(find.text('CHRONICLE UNAVAILABLE'), findsNothing);
      expect(find.byKey(const Key('echo-cycle-chip')), findsOneWidget);
    });

    testWidgets('OP-05 without an ending still shows the ending panel', (
      tester,
    ) async {
      final progress = StoryProgress(
        campaignFaction: Faction.amethyst,
        concludedOperations: StoryOperationId.values,
        medals: const [],
        recoveredTransmissions: StoryOperationId.values,
        ending: null,
      );
      await tester.pumpWidget(
        _localized(_lobby(progress: progress, onChooseEnding: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chronicle-deploy')), findsNothing);
      expect(find.byKey(const Key('claim-ending')), findsOneWidget);
    });
  });

  group('record preservation', () {
    test('chooseEnding keeps faction, medals, transmissions, and routes', () {
      final before = _canonicalComplete();
      final after = controller.chooseEnding(before, EndingChoice.openRelay);
      expect(after.ending, EndingChoice.openRelay);
      expect(after.echoCycle, 2);
      expect(after.campaignFaction, before.campaignFaction);
      expect(after.medals, before.medals);
      expect(after.recoveredTransmissions, before.recoveredTransmissions);
      expect(after.signalRoutes, before.signalRoutes);
      expect(after.concludedOperations, before.concludedOperations);
    });

    test('echo sequential conclude preserves medals, ending, and faction', () {
      final ended = controller.chooseEnding(
        _canonicalComplete(),
        EndingChoice.claimRelay,
      );
      final echo = controller.conclude(
        progress: ended,
        ledger: ProfileRewardLedger.empty(),
        operationId: StoryOperationId.wake,
        report: recoveredReport(elapsed: 70, route: RelayRoute.force),
        replay: false,
      );
      expect(echo.nextProgress.ending, EndingChoice.claimRelay);
      expect(echo.nextProgress.campaignFaction, Faction.amethyst);
      expect(echo.nextProgress.medals, containsAll(ended.medals));
      expect(echo.nextProgress.concludedOperations, ended.concludedOperations);
      expect(
        echo.nextProgress.recoveredTransmissions,
        ended.recoveredTransmissions,
      );
      expect(echo.nextProgress.signalRoutes, ended.signalRoutes);
      expect(echo.nextProgress.echoConcludedOperations, {
        StoryOperationId.wake,
      });
      expect(echo.nextProgress.echoSignalRoutes, {
        StoryOperationId.wake: RelayRoute.force,
      });
      expect(echo.firstConclusion, isTrue);
    });

    test('residual ending records echoEnding without mutating ending', () {
      var progress = controller.chooseEnding(
        _canonicalComplete(),
        EndingChoice.claimRelay,
      );
      for (final id in StoryOperationId.values) {
        progress = controller
            .conclude(
              progress: progress,
              ledger: ProfileRewardLedger.empty(),
              operationId: id,
              report: recoveredReport(),
              replay: false,
            )
            .nextProgress;
      }
      expect(progress.ending, EndingChoice.claimRelay);
      final residual = controller.chooseEnding(
        progress,
        EndingChoice.openRelay,
      );
      expect(residual.ending, EndingChoice.claimRelay);
      expect(residual.echoEnding, EndingChoice.openRelay);
      expect(
        () => controller.chooseEnding(residual, EndingChoice.claimRelay),
        throwsStateError,
      );
    });

    test('restart returns initial including empty echo fields', () {
      final ended = controller.chooseEnding(
        _canonicalComplete(),
        EndingChoice.openRelay,
      );
      final restarted = controller.restart(ended);
      expect(restarted, StoryProgress.initial());
      expect(restarted.echoCycle, 1);
      expect(restarted.echoConcludedOperations, isEmpty);
      expect(restarted.echoEnding, isNull);
      expect(restarted.bestClearSeconds, isEmpty);
    });
  });

  group('echo rules', () {
    test('echo timeout does not move the pointer', () {
      final ended = controller.chooseEnding(
        _canonicalComplete(),
        EndingChoice.openRelay,
      );
      final failed = controller.conclude(
        progress: ended,
        ledger: ProfileRewardLedger.empty(),
        operationId: StoryOperationId.wake,
        report: recoveredReport(outcome: RecoveryOutcome.timeout),
        replay: false,
      );
      expect(failed.nextProgress, ended);
      expect(failed.directiveBonusCredit, 0);
      expect(failed.firstConclusion, isFalse);
    });

    test('echo conclude does not repay a claimed directive bonus', () {
      final ended = controller.chooseEnding(
        _canonicalComplete(),
        EndingChoice.openRelay,
      );
      final echo = controller.conclude(
        progress: ended,
        ledger: ProfileRewardLedger(
          claimedDirectiveBonusIds: const {'chronicle-directive-wake'},
        ),
        operationId: StoryOperationId.wake,
        report: recoveredReport(),
        replay: false,
      );
      expect(echo.directiveBonusCredit, 0);
    });

    test('bestClearSeconds keeps the minimum recovered elapsed', () {
      var progress = controller.chooseEnding(
        _canonicalComplete(),
        EndingChoice.openRelay,
      );
      progress = controller
          .conclude(
            progress: progress,
            ledger: ProfileRewardLedger.empty(),
            operationId: StoryOperationId.wake,
            report: recoveredReport(elapsed: 70),
            replay: false,
          )
          .nextProgress;
      expect(progress.bestClearSeconds[StoryOperationId.wake], 70);
      progress = controller
          .conclude(
            progress: progress,
            ledger: ProfileRewardLedger.empty(),
            operationId: StoryOperationId.echo,
            report: recoveredReport(elapsed: 55),
            replay: false,
          )
          .nextProgress;
      expect(progress.bestClearSeconds[StoryOperationId.echo], 55);
      final failed = controller.conclude(
        progress: progress,
        ledger: ProfileRewardLedger.empty(),
        operationId: StoryOperationId.split,
        report: recoveredReport(outcome: RecoveryOutcome.timeout, elapsed: 12),
        replay: false,
      );
      expect(failed.nextProgress.bestClearSeconds, progress.bestClearSeconds);
      expect(
        failed.nextProgress.bestClearSeconds.containsKey(
          StoryOperationId.split,
        ),
        isFalse,
      );

      final replayFaster = controller.conclude(
        progress: progress,
        ledger: ProfileRewardLedger.empty(),
        operationId: StoryOperationId.wake,
        report: recoveredReport(elapsed: 40),
        replay: true,
      );
      expect(
        replayFaster.nextProgress.bestClearSeconds[StoryOperationId.wake],
        40,
      );
      expect(
        replayFaster.nextProgress.echoConcludedOperations,
        progress.echoConcludedOperations,
      );
    });

    test('full echo cycle queues wake at the next display cycle', () {
      var progress = controller.chooseEnding(
        _canonicalComplete(),
        EndingChoice.openRelay,
      );
      for (final id in StoryOperationId.values) {
        progress = controller
            .conclude(
              progress: progress,
              ledger: ProfileRewardLedger.empty(),
              operationId: id,
              report: recoveredReport(),
              replay: false,
            )
            .nextProgress;
      }
      expect(
        progress.echoConcludedOperations,
        unorderedEquals(StoryOperationId.values),
      );
      expect(progress.currentOperation, StoryOperationId.wake);
      expect(progress.echoCycle, 2);
      expect(progress.displayCycle, 3);
    });

    test('next wake after a full echo cycle rolls echoCycle', () {
      var progress = controller.chooseEnding(
        _canonicalComplete(),
        EndingChoice.openRelay,
      );
      for (final id in StoryOperationId.values) {
        progress = controller
            .conclude(
              progress: progress,
              ledger: ProfileRewardLedger.empty(),
              operationId: id,
              report: recoveredReport(),
              replay: false,
            )
            .nextProgress;
      }
      final rolled = controller.conclude(
        progress: progress,
        ledger: ProfileRewardLedger.empty(),
        operationId: StoryOperationId.wake,
        report: recoveredReport(),
        replay: false,
      );
      expect(rolled.nextProgress.echoCycle, 3);
      expect(rolled.nextProgress.echoConcludedOperations, {
        StoryOperationId.wake,
      });
      expect(rolled.nextProgress.echoSignalRoutes, isEmpty);
      expect(rolled.nextProgress.ending, EndingChoice.openRelay);
    });
  });

  group('cycle-1 difficulty', () {
    test('cycle 1 occupancy and battle config stay at playtest values', () {
      expect(RecoveryState.requiredSeconds, 8.0);
      expect(RecoveryState.midwaySeconds, 5.0);
      expect(RecoveryState.radius, 64.0);
      expect(RecoveryState.config.unitsPerFaction, 100);
      expect(RecoveryState.config.matchLimitSeconds, 90);
      expect(RecoveryRules.forCycle(1).battleConfig, RecoveryState.config);
      expect(RecoveryRules.forCycle(1).requiredSeconds, 8.0);
      expect(RecoveryRules.forCycle(1).midwaySeconds, 5.0);
      expect(RecoveryRules.forCycle(1).radius, 64.0);
      expect(RecoveryRules.forCycle(1).unitsPerFaction, 100);
    });

    test('later cycles shorten only the match clock', () {
      expect(RecoveryRules.forCycle(2).matchLimitSeconds, 78);
      expect(RecoveryRules.forCycle(3).matchLimitSeconds, 66);
      expect(RecoveryRules.forCycle(4).matchLimitSeconds, 54);
      expect(RecoveryRules.forCycle(99).matchLimitSeconds, 54);
      for (final cycle in [2, 3, 4]) {
        expect(RecoveryRules.forCycle(cycle).requiredSeconds, 8.0);
        expect(RecoveryRules.forCycle(cycle).midwaySeconds, 5.0);
        expect(RecoveryRules.forCycle(cycle).radius, 64.0);
        expect(RecoveryRules.forCycle(cycle).unitsPerFaction, 100);
      }
    });

    test('match WT decays after cycle 2', () {
      expect(
        RecoveryRules.matchReward(cycle: 1, succeeded: true, recoveredCount: 3),
        60,
      );
      expect(
        RecoveryRules.matchReward(cycle: 2, succeeded: true, recoveredCount: 3),
        60,
      );
      expect(
        RecoveryRules.matchReward(cycle: 3, succeeded: true, recoveredCount: 3),
        40,
      );
      expect(
        RecoveryRules.matchReward(cycle: 4, succeeded: true, recoveredCount: 3),
        20,
      );
      expect(
        RecoveryRules.matchReward(
          cycle: 1,
          succeeded: false,
          recoveredCount: 2,
        ),
        0,
      );
    });
  });

  group('economy cosmetics', () {
    test('first echo-cycle clear unlocks ECHO ORBIT once', () async {
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: _MemoryStore(),
      );
      addTearDown(runtime.dispose);
      runtime.lockChronicleCore(Faction.amethyst);
      for (final id in StoryOperationId.values) {
        runtime.concludeChronicle(
          operationId: id,
          report: recoveredReport(),
          replay: false,
        );
      }
      runtime.chooseChronicleEnding(EndingChoice.openRelay);
      expect(runtime.wallet.isUnlocked('color_echo_orbit'), isFalse);
      for (final id in StoryOperationId.values) {
        runtime.concludeChronicle(
          operationId: id,
          report: recoveredReport(),
          replay: false,
        );
      }
      expect(runtime.wallet.isUnlocked('color_echo_orbit'), isTrue);
      runtime.concludeChronicle(
        operationId: StoryOperationId.wake,
        report: recoveredReport(),
        replay: false,
      );
      expect(
        runtime.wallet.unlockedIds.where((id) => id == 'color_echo_orbit'),
        hasLength(1),
      );
    });

    test('checksum scar unlocks only when both endings are recorded', () async {
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: _MemoryStore(),
      );
      addTearDown(runtime.dispose);
      runtime.lockChronicleCore(Faction.amethyst);
      for (final id in StoryOperationId.values) {
        runtime.concludeChronicle(
          operationId: id,
          report: recoveredReport(),
          replay: false,
        );
      }
      runtime.chooseChronicleEnding(EndingChoice.claimRelay);
      expect(runtime.wallet.isUnlocked('trail_checksum_scar'), isFalse);
      for (final id in StoryOperationId.values) {
        runtime.concludeChronicle(
          operationId: id,
          report: recoveredReport(),
          replay: false,
        );
      }
      runtime.chooseChronicleEnding(EndingChoice.claimRelay);
      expect(runtime.storyProgress.echoEnding, EndingChoice.claimRelay);
      expect(runtime.wallet.isUnlocked('trail_checksum_scar'), isFalse);
      expect(
        () => runtime.chooseChronicleEnding(EndingChoice.openRelay),
        throwsStateError,
      );
    });

    test('opposite residual ending unlocks CHECKSUM SCAR', () async {
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: _MemoryStore(),
      );
      addTearDown(runtime.dispose);
      runtime.lockChronicleCore(Faction.amethyst);
      for (final id in StoryOperationId.values) {
        runtime.concludeChronicle(
          operationId: id,
          report: recoveredReport(),
          replay: false,
        );
      }
      runtime.chooseChronicleEnding(EndingChoice.claimRelay);
      for (final id in StoryOperationId.values) {
        runtime.concludeChronicle(
          operationId: id,
          report: recoveredReport(),
          replay: false,
        );
      }
      runtime.chooseChronicleEnding(EndingChoice.openRelay);
      expect(runtime.wallet.isUnlocked('trail_checksum_scar'), isTrue);
      expect(runtime.storyProgress.ending, EndingChoice.claimRelay);
      expect(runtime.storyProgress.echoEnding, EndingChoice.openRelay);
    });
  });
}

StoryProgress _canonicalComplete() => StoryProgress(
  campaignFaction: Faction.amethyst,
  concludedOperations: StoryOperationId.values,
  medals: const {StoryOperationId.wake, StoryOperationId.echo},
  recoveredTransmissions: StoryOperationId.values,
  ending: null,
  signalRoutes: const {
    StoryOperationId.wake: RelayRoute.preserve,
    StoryOperationId.echo: RelayRoute.force,
  },
);

BattleReport recoveredReport({
  RecoveryOutcome outcome = RecoveryOutcome.recovered,
  double? elapsed,
  RelayRoute? route,
}) => BattleReport(
  endReason: ChronicleEndReason.recovery,
  recoveryOutcome: outcome,
  recoveredSignals: outcome == RecoveryOutcome.recovered ? 3 : 1,
  recoveryElapsedSeconds: elapsed,
  standingsAtConclusion: const [
    FactionStanding(
      faction: Faction.amethyst,
      survivors: 4,
      levelSum: 20,
      kills: 2,
    ),
    FactionStanding(
      faction: Faction.cobalt,
      survivors: 0,
      levelSum: 0,
      kills: 0,
    ),
    FactionStanding(faction: Faction.volt, survivors: 0, levelSum: 0, kills: 0),
    FactionStanding(
      faction: Faction.prism,
      survivors: 0,
      levelSum: 0,
      kills: 0,
    ),
  ],
  globalWinner: Faction.amethyst,
  commandRelays: 0,
  commandKills: 0,
  longestCommandLinkSeconds: 0,
  playerRank: 1,
  playerSurvivors: 4,
  relayRoute: route,
);

LobbyScreen _lobby({
  required StoryProgress progress,
  ValueChanged<EndingChoice>? onChooseEnding,
}) => LobbyScreen(
  selectedMode: GameMode.chronicle,
  storyProgress: progress,
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
  onChooseEnding: onChooseEnding,
);

Widget _localized(Widget child) => MaterialApp(
  theme: buildTokenfrontTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

final class _MemoryStore implements TokenfrontStateStore {
  _MemoryStore();
  _MemoryStore.withValue(this.value);
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}
