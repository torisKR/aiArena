import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/story/campaign_controller.dart';
import 'package:tokenfront/story/story_catalog.dart';
import 'package:tokenfront/story/story_models.dart';

void main() {
  const controller = CampaignController();

  test('directive thresholds pass at the exact boundary', () {
    final reports = <StoryOperationId, BattleReport>{
      StoryOperationId.wake: report(link: 45),
      StoryOperationId.echo: report(relays: 2),
      StoryOperationId.split: report(commandKills: 3),
      StoryOperationId.crown: report(rank: 2),
      StoryOperationId.lastInstruction: report(winner: Faction.amethyst),
    };
    for (final entry in reports.entries) {
      expect(
        controller.directiveSucceeded(
          operation: StoryCatalog.byId(entry.key),
          report: entry.value,
          campaignFaction: Faction.amethyst,
        ),
        isTrue,
      );
    }
  });

  test('directive thresholds fail immediately below the boundary', () {
    final reports = <StoryOperationId, BattleReport>{
      StoryOperationId.wake: report(link: 44.999),
      StoryOperationId.echo: report(relays: 1),
      StoryOperationId.split: report(commandKills: 2),
      StoryOperationId.crown: report(rank: 3),
      StoryOperationId.lastInstruction: report(),
    };
    for (final entry in reports.entries) {
      expect(
        controller.directiveSucceeded(
          operation: StoryCatalog.byId(entry.key),
          report: entry.value,
          campaignFaction: Faction.amethyst,
        ),
        isFalse,
      );
    }
    expect(
      controller.directiveSucceeded(
        operation: StoryCatalog.byId(StoryOperationId.lastInstruction),
        report: report(winner: Faction.cobalt),
        campaignFaction: Faction.amethyst,
      ),
      isFalse,
    );
  });

  test('OP-04 rank progress uses lower-is-better polarity', () {
    final operation = StoryCatalog.byId(StoryOperationId.crown);
    for (final rank in const [1, 2]) {
      final battleReport = report(rank: rank);
      final progress = controller.directiveProgress(
        operation: operation,
        report: battleReport,
        campaignFaction: Faction.amethyst,
      );
      expect(progress.current, rank.toDouble());
      expect(progress.target, 2);
      expect(progress.completed, isTrue, reason: 'rank $rank must pass');
      expect(
        controller.directiveSucceeded(
          operation: operation,
          report: battleReport,
          campaignFaction: Faction.amethyst,
        ),
        isTrue,
      );
    }
    for (final rank in const [3, 4]) {
      final battleReport = report(rank: rank);
      final progress = controller.directiveProgress(
        operation: operation,
        report: battleReport,
        campaignFaction: Faction.amethyst,
      );
      expect(progress.completed, isFalse, reason: 'rank $rank must miss');
      expect(
        controller.directiveSucceeded(
          operation: operation,
          report: battleReport,
          campaignFaction: Faction.amethyst,
        ),
        isFalse,
      );
    }
  });

  test('loss advances story while a missed directive pays nothing', () {
    final transition = controller.conclude(
      progress: StoryProgress.initial().lockCore(Faction.amethyst),
      ledger: ProfileRewardLedger.empty(),
      operationId: StoryOperationId.wake,
      report: report(reason: ChronicleEndReason.playerEliminated, link: 44.999),
      replay: false,
    );
    expect(transition.nextProgress.currentOperation, StoryOperationId.echo);
    expect(transition.directiveSucceeded, isFalse);
    expect(transition.directiveBonusCredit, 0);
    expect(transition.firstConclusion, isTrue);
    expect(transition.nextProgress.concludedOperations, {
      StoryOperationId.wake,
    });
    expect(transition.nextProgress.recoveredTransmissions, {
      StoryOperationId.wake,
    });
  });

  test('duplicate and replay conclusions never repay a claimed bonus', () {
    final first = controller.conclude(
      progress: StoryProgress.initial().lockCore(Faction.amethyst),
      ledger: ProfileRewardLedger.empty(),
      operationId: StoryOperationId.wake,
      report: report(link: 45),
      replay: false,
    );
    final duplicate = controller.conclude(
      progress: first.nextProgress,
      ledger: first.nextLedger,
      operationId: StoryOperationId.wake,
      report: report(link: 60),
      replay: true,
    );
    expect(first.directiveBonusCredit, 15);
    expect(first.nextLedger.claimedDirectiveBonusIds, {
      'chronicle-directive-wake',
    });
    expect(duplicate.directiveSucceeded, isTrue);
    expect(duplicate.directiveBonusCredit, 0);
    expect(duplicate.firstConclusion, isFalse);
    expect(duplicate.nextLedger, first.nextLedger);
    expect(duplicate.nextProgress, first.nextProgress);
    expect(duplicate.nextProgress.currentOperation, StoryOperationId.echo);
  });

  test('first conclusion records the selected preserve or force route', () {
    final preserve = controller.conclude(
      progress: StoryProgress.initial().lockCore(Faction.amethyst),
      ledger: ProfileRewardLedger.empty(),
      operationId: StoryOperationId.wake,
      report: report(link: 45, route: RelayRoute.preserve),
      replay: false,
    );
    expect(preserve.nextProgress.signalRoutes, {
      StoryOperationId.wake: RelayRoute.preserve,
    });

    final force = controller.conclude(
      progress: StoryProgress.initial().lockCore(Faction.amethyst),
      ledger: ProfileRewardLedger.empty(),
      operationId: StoryOperationId.wake,
      report: report(link: 45, route: RelayRoute.force),
      replay: false,
    );
    expect(force.nextProgress.signalRoutes, {
      StoryOperationId.wake: RelayRoute.force,
    });
  });

  test(
    'successful replay with the opposite route never overwrites history',
    () {
      final first = controller.conclude(
        progress: StoryProgress.initial().lockCore(Faction.amethyst),
        ledger: ProfileRewardLedger.empty(),
        operationId: StoryOperationId.wake,
        report: report(link: 45, route: RelayRoute.preserve),
        replay: false,
      );
      final replay = controller.conclude(
        progress: first.nextProgress,
        ledger: first.nextLedger,
        operationId: StoryOperationId.wake,
        report: report(link: 45, route: RelayRoute.force),
        replay: true,
      );

      expect(replay.nextProgress.signalRoutes, {
        StoryOperationId.wake: RelayRoute.preserve,
      });
    },
  );

  test('legacy report without a route does not invent route history', () {
    final transition = controller.conclude(
      progress: StoryProgress.initial().lockCore(Faction.amethyst),
      ledger: ProfileRewardLedger.empty(),
      operationId: StoryOperationId.wake,
      report: report(link: 45),
      replay: false,
    );

    expect(transition.nextProgress.signalRoutes, isEmpty);
  });

  test('OP-02 counts manual and casualty relays toward its directive', () {
    final progress = StoryProgress.initial()
        .lockCore(Faction.amethyst)
        .copyWith(
          concludedOperations: const {StoryOperationId.wake},
          recoveredTransmissions: const {StoryOperationId.wake},
        );
    final transition = controller.conclude(
      progress: progress,
      ledger: ProfileRewardLedger.empty(),
      operationId: StoryOperationId.echo,
      report: report(relays: 2, manualRelays: 1),
      replay: false,
    );

    expect(transition.directiveSucceeded, isTrue);
    expect(transition.directiveBonusCredit, 20);
    expect(transition.nextProgress.concludedOperations, {
      StoryOperationId.wake,
      StoryOperationId.echo,
    });
  });

  test(
    'successful replay restores a missing medal and unclaimed bonus only',
    () {
      final first = controller.conclude(
        progress: StoryProgress.initial().lockCore(Faction.amethyst),
        ledger: ProfileRewardLedger.empty(),
        operationId: StoryOperationId.wake,
        report: report(link: 44.999),
        replay: false,
      );
      final replay = controller.conclude(
        progress: first.nextProgress,
        ledger: first.nextLedger,
        operationId: StoryOperationId.wake,
        report: report(link: 45),
        replay: true,
      );
      expect(replay.directiveSucceeded, isTrue);
      expect(replay.directiveBonusCredit, 15);
      expect(replay.firstConclusion, isFalse);
      expect(replay.nextProgress.currentOperation, StoryOperationId.echo);
      expect(
        replay.nextProgress.concludedOperations,
        first.nextProgress.concludedOperations,
      );
      expect(
        replay.nextProgress.recoveredTransmissions,
        first.nextProgress.recoveredTransmissions,
      );
      expect(replay.nextProgress.ending, first.nextProgress.ending);
      expect(replay.nextProgress.medals, contains(StoryOperationId.wake));
      expect(replay.nextLedger.claimedDirectiveBonusIds, {
        'chronicle-directive-wake',
      });

      final failedReplay = controller.conclude(
        progress: replay.nextProgress,
        ledger: replay.nextLedger,
        operationId: StoryOperationId.wake,
        report: report(link: 44.999),
        replay: true,
      );
      expect(failedReplay.nextProgress, replay.nextProgress);
      expect(failedReplay.nextLedger, replay.nextLedger);
      expect(failedReplay.directiveBonusCredit, 0);
    },
  );

  test('first-run conclusion rejects an operation that is not unlocked', () {
    expect(
      () => controller.conclude(
        progress: StoryProgress.initial().lockCore(Faction.amethyst),
        ledger: ProfileRewardLedger.empty(),
        operationId: StoryOperationId.echo,
        report: report(relays: 2),
        replay: false,
      ),
      throwsStateError,
    );
  });

  test('OP-05 loss concludes and permits both endings', () {
    var progress = StoryProgress(
      campaignFaction: Faction.amethyst,
      concludedOperations: StoryOperationId.values.where(
        (id) => id != StoryOperationId.lastInstruction,
      ),
      medals: const [],
      recoveredTransmissions: StoryOperationId.values.where(
        (id) => id != StoryOperationId.lastInstruction,
      ),
      ending: null,
    );
    final transition = controller.conclude(
      progress: progress,
      ledger: ProfileRewardLedger.empty(),
      operationId: StoryOperationId.lastInstruction,
      report: report(reason: ChronicleEndReason.playerEliminated),
      replay: false,
    );
    progress = transition.nextProgress;
    expect(progress.currentOperation, isNull);
    expect(
      progress.concludedOperations,
      contains(StoryOperationId.lastInstruction),
    );
    expect(
      progress.recoveredTransmissions,
      contains(StoryOperationId.lastInstruction),
    );

    final claimed = controller.chooseEnding(progress, EndingChoice.claimRelay);
    expect(claimed.ending, EndingChoice.claimRelay);
    expect(
      () => controller.chooseEnding(claimed, EndingChoice.openRelay),
      throwsStateError,
    );

    final restarted = controller.restart(progress);
    expect(restarted, StoryProgress.initial());
    expect(restarted.campaignFaction, isNull);
    expect(restarted.concludedOperations, isEmpty);
    expect(restarted.recoveredTransmissions, isEmpty);
    expect(restarted.medals, isEmpty);
    expect(restarted.ending, isNull);
    final open = controller.chooseEnding(
      controller
          .conclude(
            progress: progress,
            ledger: ProfileRewardLedger.empty(),
            operationId: StoryOperationId.lastInstruction,
            report: report(),
            replay: true,
          )
          .nextProgress,
      EndingChoice.openRelay,
    );
    expect(open.ending, EndingChoice.openRelay);
  });

  test('ending is gated until OP-05 has concluded', () {
    final progress = StoryProgress.initial().lockCore(Faction.amethyst);
    expect(
      () => controller.chooseEnding(progress, EndingChoice.claimRelay),
      throwsStateError,
    );
  });
}

BattleReport report({
  ChronicleEndReason reason = ChronicleEndReason.timeLimit,
  Faction? winner,
  int relays = 0,
  int commandKills = 0,
  double link = 0,
  int rank = 4,
  int survivors = 0,
  int manualRelays = 0,
  RelayRoute? route,
  List<FactionStanding>? standings,
}) {
  return BattleReport(
    endReason: reason,
    standingsAtConclusion:
        standings ??
        const [
          FactionStanding(
            faction: Faction.amethyst,
            survivors: 0,
            levelSum: 0,
            kills: 0,
          ),
          FactionStanding(
            faction: Faction.cobalt,
            survivors: 0,
            levelSum: 0,
            kills: 0,
          ),
          FactionStanding(
            faction: Faction.volt,
            survivors: 0,
            levelSum: 0,
            kills: 0,
          ),
          FactionStanding(
            faction: Faction.prism,
            survivors: 0,
            levelSum: 0,
            kills: 0,
          ),
        ],
    globalWinner: winner,
    commandRelays: relays,
    commandKills: commandKills,
    longestCommandLinkSeconds: link,
    playerRank: rank,
    playerSurvivors: survivors,
    manualRelays: manualRelays,
    relayRoute: route,
  );
}
