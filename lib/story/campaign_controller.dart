import 'story_catalog.dart';
import 'story_models.dart';
import '../game/recovery.dart';
import 'package:tokenfront/game/simulation.dart';

final class CampaignTransition {
  const CampaignTransition({
    required this.nextProgress,
    required this.nextLedger,
    required this.directiveSucceeded,
    required this.directiveBonusCredit,
    required this.firstConclusion,
  });

  final StoryProgress nextProgress;
  final ProfileRewardLedger nextLedger;
  final bool directiveSucceeded;
  final int directiveBonusCredit;
  final bool firstConclusion;
}

final class CampaignController {
  const CampaignController();

  CampaignTransition conclude({
    required StoryProgress progress,
    required ProfileRewardLedger ledger,
    required StoryOperationId operationId,
    required BattleReport report,
    required bool replay,
  }) {
    final operation = StoryCatalog.byId(operationId);
    if (report.recoveryOutcome case final outcome?
        when outcome != RecoveryOutcome.recovered) {
      return CampaignTransition(
        nextProgress: progress,
        nextLedger: ledger,
        directiveSucceeded: false,
        directiveBonusCredit: 0,
        firstConclusion: false,
      );
    }
    final alreadyConcluded = progress.concludedOperations.contains(operationId);
    final campaignFaction = progress.campaignFaction;
    final succeeded = campaignFaction == null
        ? false
        : directiveSucceeded(
            operation: operation,
            report: report,
            campaignFaction: campaignFaction,
          );

    if (progress.ending != null && !replay) {
      return _concludeEcho(
        progress: progress,
        ledger: ledger,
        operation: operation,
        operationId: operationId,
        report: report,
        succeeded: succeeded,
      );
    }

    // Duplicate non-replay delivery is observational only. A successful
    // replay may restore mastery for a concluded operation, without moving
    // the sequential campaign pointer or changing transmissions/ending.
    if (alreadyConcluded && (!replay || !succeeded)) {
      return CampaignTransition(
        nextProgress: progress,
        nextLedger: ledger,
        directiveSucceeded: succeeded,
        directiveBonusCredit: 0,
        firstConclusion: false,
      );
    }

    if (alreadyConcluded) {
      final medals = {...progress.medals, operationId};
      final hasClaim = ledger.claimedDirectiveBonusIds.contains(
        operation.bonusClaimId,
      );
      final paysBonus = !hasClaim;
      return CampaignTransition(
        nextProgress: progress.copyWith(
          medals: medals,
          bestClearSeconds: _bestClearSeconds(progress, operationId, report),
        ),
        nextLedger: paysBonus
            ? ProfileRewardLedger(
                claimedDirectiveBonusIds: {
                  ...ledger.claimedDirectiveBonusIds,
                  operation.bonusClaimId,
                },
              )
            : ledger,
        directiveSucceeded: true,
        directiveBonusCredit: paysBonus ? operation.oneTimeBonus : 0,
        firstConclusion: false,
      );
    }

    if (progress.campaignFaction == null) {
      throw StateError('campaign faction must be locked before conclusion');
    }
    if (progress.currentOperation != operationId) {
      throw StateError('story operation ${operation.id.name} is not unlocked');
    }

    final concluded = {...progress.concludedOperations, operationId};
    final transmissions = {...progress.recoveredTransmissions, operationId};
    final medals = {...progress.medals};
    final signalRoutes = {...progress.signalRoutes};
    if (succeeded) medals.add(operationId);
    if (report.relayRoute != null) {
      signalRoutes[operationId] = report.relayRoute!;
    }

    final hasClaim = ledger.claimedDirectiveBonusIds.contains(
      operation.bonusClaimId,
    );
    final paysBonus = succeeded && !hasClaim;
    final nextLedger = paysBonus
        ? ProfileRewardLedger(
            claimedDirectiveBonusIds: {
              ...ledger.claimedDirectiveBonusIds,
              operation.bonusClaimId,
            },
          )
        : ledger;

    return CampaignTransition(
      nextProgress: progress.copyWith(
        concludedOperations: concluded,
        medals: medals,
        recoveredTransmissions: transmissions,
        signalRoutes: signalRoutes,
        bestClearSeconds: _bestClearSeconds(progress, operationId, report),
      ),
      nextLedger: nextLedger,
      directiveSucceeded: succeeded,
      directiveBonusCredit: paysBonus ? operation.oneTimeBonus : 0,
      firstConclusion: true,
    );
  }

  CampaignTransition _concludeEcho({
    required StoryProgress progress,
    required ProfileRewardLedger ledger,
    required StoryOperation operation,
    required StoryOperationId operationId,
    required BattleReport report,
    required bool succeeded,
  }) {
    if (progress.currentOperation != operationId) {
      throw StateError('story operation ${operation.id.name} is not unlocked');
    }

    var echoCycle = progress.echoCycle;
    var echoConcluded = {...progress.echoConcludedOperations};
    var echoRoutes = {...progress.echoSignalRoutes};
    if (echoConcluded.length == StoryOperationId.values.length) {
      echoCycle += 1;
      echoConcluded = <StoryOperationId>{};
      echoRoutes = <StoryOperationId, RelayRoute>{};
    }
    final firstConclusion = !echoConcluded.contains(operationId);
    echoConcluded.add(operationId);
    if (report.relayRoute != null) {
      echoRoutes[operationId] = report.relayRoute!;
    }
    final medals = {...progress.medals};
    if (!medals.contains(operationId)) medals.add(operationId);

    final hasClaim = ledger.claimedDirectiveBonusIds.contains(
      operation.bonusClaimId,
    );
    final paysBonus = succeeded && !hasClaim;
    final nextLedger = paysBonus
        ? ProfileRewardLedger(
            claimedDirectiveBonusIds: {
              ...ledger.claimedDirectiveBonusIds,
              operation.bonusClaimId,
            },
          )
        : ledger;

    return CampaignTransition(
      nextProgress: progress.copyWith(
        medals: medals,
        echoCycle: echoCycle,
        echoConcludedOperations: echoConcluded,
        echoSignalRoutes: echoRoutes,
        bestClearSeconds: _bestClearSeconds(progress, operationId, report),
      ),
      nextLedger: nextLedger,
      directiveSucceeded: succeeded,
      directiveBonusCredit: paysBonus ? operation.oneTimeBonus : 0,
      firstConclusion: firstConclusion,
    );
  }

  Map<StoryOperationId, double> _bestClearSeconds(
    StoryProgress progress,
    StoryOperationId operationId,
    BattleReport report,
  ) {
    final elapsed = report.recoveryElapsedSeconds;
    if (elapsed == null || !elapsed.isFinite || elapsed <= 0) {
      return progress.bestClearSeconds;
    }
    final current = progress.bestClearSeconds[operationId];
    if (current != null && current <= elapsed) {
      return progress.bestClearSeconds;
    }
    return {...progress.bestClearSeconds, operationId: elapsed};
  }

  DirectiveProgress directiveProgress({
    required StoryOperation operation,
    required BattleReport report,
    required Faction campaignFaction,
  }) {
    final current = switch (operation.directive.kind) {
      DirectiveKind.longestCommandLink => report.longestCommandLinkSeconds,
      DirectiveKind.commandRelays => report.commandRelays.toDouble(),
      DirectiveKind.commandKills => report.commandKills.toDouble(),
      DirectiveKind.finalRank => report.playerRank.toDouble(),
      DirectiveKind.victory =>
        report.globalWinner == campaignFaction ? 1.0 : 0.0,
    };
    return DirectiveProgress(
      kind: operation.directive.kind,
      current: current,
      target: operation.directive.target,
    );
  }

  bool directiveSucceeded({
    required StoryOperation operation,
    required BattleReport report,
    required Faction campaignFaction,
  }) => report.recoveryOutcome != null
      ? report.recoveryOutcome == RecoveryOutcome.recovered
      : directiveProgress(
          operation: operation,
          report: report,
          campaignFaction: campaignFaction,
        ).completed;

  StoryProgress chooseEnding(StoryProgress progress, EndingChoice choice) {
    if (!progress.concludedOperations.contains(
      StoryOperationId.lastInstruction,
    )) {
      throw StateError('OP-05 must conclude before choosing an ending');
    }
    if (progress.ending == null) {
      return progress.copyWith(
        ending: choice,
        echoCycle: progress.echoCycle < 2 ? 2 : progress.echoCycle,
      );
    }
    if (progress.echoEnding != null) {
      throw StateError('echo ending has already been chosen');
    }
    if (!progress.echoConcludedOperations.contains(
      StoryOperationId.lastInstruction,
    )) {
      throw StateError('echo OP-05 must conclude before residual ending');
    }
    return progress.copyWith(echoEnding: choice);
  }

  StoryProgress restart(StoryProgress progress) => StoryProgress.initial();
}
