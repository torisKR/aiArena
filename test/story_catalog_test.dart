import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/story/story_catalog.dart';
import 'package:tokenfront/story/story_models.dart';

void main() {
  test('catalog contains the five fixed operations in order', () {
    expect(StoryCatalog.operations.map((op) => op.id), StoryOperationId.values);
    expect(
      StoryCatalog.operations.map((op) => op.seed),
      orderedEquals(const [
        2026080501,
        2026080502,
        2026080503,
        2026080504,
        2026080505,
      ]),
    );
    expect(
      StoryCatalog.operations.every(
        (op) => op.duration == const Duration(seconds: 180),
      ),
      isTrue,
    );
    expect(
      StoryCatalog.operations.map((op) => op.directive.target),
      orderedEquals(const [45.0, 2.0, 3.0, 2.0, 1.0]),
    );
    expect(
      StoryCatalog.operations.map((op) => op.oneTimeBonus),
      orderedEquals(const [15, 20, 25, 30, 40]),
    );
  });

  test('fresh progress and reward ledger are empty', () {
    expect(StoryProgress.initial().currentOperation, StoryOperationId.wake);
    expect(StoryProgress.initial().campaignFaction, isNull);
    expect(StoryProgress.initial().ending, isNull);
    expect(ProfileRewardLedger.empty().claimedDirectiveBonusIds, isEmpty);
  });

  test('story collections defensively copy and expose no mutation path', () {
    final concluded = <StoryOperationId>{StoryOperationId.wake};
    final medals = <StoryOperationId>{StoryOperationId.wake};
    final transmissions = <StoryOperationId>{StoryOperationId.wake};
    final progress = StoryProgress(
      campaignFaction: Faction.amethyst,
      concludedOperations: concluded,
      medals: medals,
      recoveredTransmissions: transmissions,
      ending: null,
    );
    concluded.add(StoryOperationId.echo);
    medals.clear();
    transmissions.add(StoryOperationId.split);

    expect(progress.concludedOperations, {StoryOperationId.wake});
    expect(progress.medals, {StoryOperationId.wake});
    expect(progress.recoveredTransmissions, {StoryOperationId.wake});
    expect(
      () => progress.concludedOperations.add(StoryOperationId.echo),
      throwsUnsupportedError,
    );
    final encoded = progress.toJson();
    (encoded['concludedOperations']! as List<Object?>).clear();
    expect(progress.concludedOperations, {StoryOperationId.wake});

    final equivalent = StoryProgress(
      campaignFaction: Faction.amethyst,
      concludedOperations: {StoryOperationId.wake},
      medals: {StoryOperationId.wake},
      recoveredTransmissions: {StoryOperationId.wake},
      ending: null,
    );
    expect(progress, equivalent);
    expect(progress.hashCode, equivalent.hashCode);
  });

  test('ledger report and catalog collections are immutable values', () {
    final claims = <String>{'chronicle-directive-wake'};
    final ledger = ProfileRewardLedger(claimedDirectiveBonusIds: claims);
    claims.add('chronicle-directive-echo');
    expect(ledger.claimedDirectiveBonusIds, {'chronicle-directive-wake'});
    expect(
      () => ledger.claimedDirectiveBonusIds.add('chronicle-directive-split'),
      throwsUnsupportedError,
    );
    expect(
      ledger,
      ProfileRewardLedger(
        claimedDirectiveBonusIds: {'chronicle-directive-wake'},
      ),
    );
    expect(
      ledger.hashCode,
      ProfileRewardLedger(
        claimedDirectiveBonusIds: {'chronicle-directive-wake'},
      ).hashCode,
    );

    const standing = FactionStanding(
      faction: Faction.amethyst,
      survivors: 10,
      levelSum: 50,
      kills: 3,
    );
    final standings = <FactionStanding>[standing];
    final report = BattleReport(
      endReason: ChronicleEndReason.timeLimit,
      standingsAtConclusion: standings,
      globalWinner: Faction.amethyst,
      commandRelays: 1,
      commandKills: 3,
      longestCommandLinkSeconds: 45,
      playerRank: 1,
      playerSurvivors: 10,
    );
    standings.clear();
    expect(report.standingsAtConclusion, hasLength(1));
    expect(
      () => report.standingsAtConclusion.add(standing),
      throwsUnsupportedError,
    );
    final equivalentReport = BattleReport(
      endReason: ChronicleEndReason.timeLimit,
      standingsAtConclusion: const [standing],
      globalWinner: Faction.amethyst,
      commandRelays: 1,
      commandKills: 3,
      longestCommandLinkSeconds: 45,
      playerRank: 1,
      playerSurvivors: 10,
    );
    expect(report, equivalentReport);
    expect(report.hashCode, equivalentReport.hashCode);
    expect(
      () => StoryCatalog.operations.add(StoryCatalog.operations.first),
      throwsUnsupportedError,
    );
  });
}
