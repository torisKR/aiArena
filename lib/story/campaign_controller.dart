import 'story_catalog.dart';
import 'story_models.dart';
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
    final alreadyConcluded = progress.concludedOperations.contains(operationId);
    final campaignFaction = progress.campaignFaction;
    final succeeded = campaignFaction == null
        ? false
        : directiveSucceeded(
            operation: operation,
            report: report,
            campaignFaction: campaignFaction,
          );

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
        nextProgress: progress.copyWith(medals: medals),
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
    if (succeeded) medals.add(operationId);

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
      ),
      nextLedger: nextLedger,
      directiveSucceeded: succeeded,
      directiveBonusCredit: paysBonus ? operation.oneTimeBonus : 0,
      firstConclusion: true,
    );
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
  }) => directiveProgress(
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
    if (progress.ending != null) {
      throw StateError('campaign ending has already been chosen');
    }
    return progress.copyWith(ending: choice);
  }

  StoryProgress restart(StoryProgress progress) => StoryProgress.initial();
}
