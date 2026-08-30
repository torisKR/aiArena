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

  test('signal routes round-trip in canonical operation order', () {
    final progress = StoryProgress(
      campaignFaction: Faction.amethyst,
      concludedOperations: const {StoryOperationId.wake, StoryOperationId.echo},
      medals: const {StoryOperationId.wake, StoryOperationId.echo},
      recoveredTransmissions: const {
        StoryOperationId.wake,
        StoryOperationId.echo,
      },
      ending: null,
      signalRoutes: const {
        StoryOperationId.echo: RelayRoute.force,
        StoryOperationId.wake: RelayRoute.preserve,
      },
    );

    final decoded = StoryProgress.fromJson(progress.toJson());
    expect(decoded, progress);
    expect(
      decoded.signalRoutes.keys,
      orderedEquals(const [StoryOperationId.wake, StoryOperationId.echo]),
    );
    expect(decoded.signalDoctrine, SignalDoctrine.balanced);
    final changed = progress.copyWith(
      signalRoutes: const {StoryOperationId.wake: RelayRoute.force},
    );
    expect(progress, isNot(changed));
    expect(progress.hashCode, isNot(changed.hashCode));
    expect((progress.toJson()['signalRoutes']! as Map<String, Object?>), {
      'wake': 'preserve',
      'echo': 'force',
    });
  });

  test('old story JSON migrates with undecided signal doctrine', () {
    final oldJson = <String, Object?>{
      'campaignFaction': 'amethyst',
      'concludedOperations': ['wake'],
      'medals': ['wake'],
      'recoveredTransmissions': ['wake'],
      'ending': null,
    };
    final progress = StoryProgress.fromJson(oldJson);
    expect(progress.signalRoutes, isEmpty);
    expect(progress.signalDoctrine, SignalDoctrine.undecided);
  });

  test('signal routes defensively copy and reject unconcluded history', () {
    final routes = <StoryOperationId, RelayRoute>{
      StoryOperationId.wake: RelayRoute.preserve,
    };
    final progress = StoryProgress(
      campaignFaction: Faction.amethyst,
      concludedOperations: const {StoryOperationId.wake},
      medals: const {StoryOperationId.wake},
      recoveredTransmissions: const {StoryOperationId.wake},
      ending: null,
      signalRoutes: routes,
    );
    routes[StoryOperationId.echo] = RelayRoute.force;
    expect(progress.signalRoutes, {StoryOperationId.wake: RelayRoute.preserve});
    expect(
      () => progress.signalRoutes[StoryOperationId.echo] = RelayRoute.force,
      throwsUnsupportedError,
    );
    final encoded = progress.toJson();
    (encoded['signalRoutes']! as Map<String, Object?>)['wake'] = 'force';
    expect(progress.signalRoutes[StoryOperationId.wake], RelayRoute.preserve);

    final invalid = progress.copyWith(
      signalRoutes: const {StoryOperationId.echo: RelayRoute.force},
    );
    expect(invalid.isSemanticallyValid, isFalse);
    expect(
      () => StoryProgress.fromJson({
        ...progress.toJson(),
        'signalRoutes': {'echo': 'force'},
      }),
      throwsFormatException,
    );
    expect(
      () => StoryProgress.fromJson({
        ...progress.toJson(),
        'signalRoutes': {'wake': 'unknown'},
      }),
      throwsFormatException,
    );
  });

  test(
    'signal doctrine distinguishes preserve, force, balanced and undecided',
    () {
      StoryProgress make(Map<StoryOperationId, RelayRoute> routes) =>
          StoryProgress(
            campaignFaction: Faction.amethyst,
            concludedOperations: const {
              StoryOperationId.wake,
              StoryOperationId.echo,
              StoryOperationId.split,
            },
            medals: const {
              StoryOperationId.wake,
              StoryOperationId.echo,
              StoryOperationId.split,
            },
            recoveredTransmissions: const {
              StoryOperationId.wake,
              StoryOperationId.echo,
              StoryOperationId.split,
            },
            ending: null,
            signalRoutes: routes,
          );

      expect(StoryProgress.initial().signalDoctrine, SignalDoctrine.undecided);
      expect(
        make({StoryOperationId.wake: RelayRoute.preserve}).signalDoctrine,
        SignalDoctrine.preserve,
      );
      expect(
        make({StoryOperationId.wake: RelayRoute.force}).signalDoctrine,
        SignalDoctrine.force,
      );
      expect(
        make({
          StoryOperationId.wake: RelayRoute.preserve,
          StoryOperationId.echo: RelayRoute.force,
        }).signalDoctrine,
        SignalDoctrine.balanced,
      );
      expect(
        make({
          StoryOperationId.wake: RelayRoute.preserve,
          StoryOperationId.echo: RelayRoute.preserve,
          StoryOperationId.split: RelayRoute.force,
        }).signalDoctrine,
        SignalDoctrine.preserve,
      );
      expect(
        make({
          StoryOperationId.wake: RelayRoute.preserve,
          StoryOperationId.echo: RelayRoute.force,
          StoryOperationId.split: RelayRoute.force,
        }).signalDoctrine,
        SignalDoctrine.force,
      );
    },
  );

  test('battle report accounts for manual and casualty relays', () {
    const standing = FactionStanding(
      faction: Faction.amethyst,
      survivors: 10,
      levelSum: 50,
      kills: 3,
    );
    final report = BattleReport(
      endReason: ChronicleEndReason.timeLimit,
      standingsAtConclusion: const [standing],
      globalWinner: Faction.amethyst,
      commandRelays: 5,
      manualRelays: 2,
      relayRoute: RelayRoute.force,
      commandKills: 3,
      longestCommandLinkSeconds: 45,
      playerRank: 1,
      playerSurvivors: 10,
    );
    expect(report.casualtyRelays, 3);
    expect(
      report,
      BattleReport(
        endReason: ChronicleEndReason.timeLimit,
        standingsAtConclusion: const [standing],
        globalWinner: Faction.amethyst,
        commandRelays: 5,
        manualRelays: 2,
        relayRoute: RelayRoute.force,
        commandKills: 3,
        longestCommandLinkSeconds: 45,
        playerRank: 1,
        playerSurvivors: 10,
      ),
    );
    final changedReport = BattleReport(
      endReason: ChronicleEndReason.timeLimit,
      standingsAtConclusion: const [standing],
      globalWinner: Faction.amethyst,
      commandRelays: 5,
      manualRelays: 1,
      relayRoute: RelayRoute.force,
      commandKills: 3,
      longestCommandLinkSeconds: 45,
      playerRank: 1,
      playerSurvivors: 10,
    );
    expect(report, isNot(changedReport));
    expect(report.hashCode, isNot(changedReport.hashCode));
    expect(
      BattleReport(
        endReason: ChronicleEndReason.timeLimit,
        standingsAtConclusion: const [standing],
        globalWinner: Faction.amethyst,
        commandRelays: 1,
        manualRelays: 4,
        commandKills: 3,
        longestCommandLinkSeconds: 45,
        playerRank: 1,
        playerSurvivors: 10,
      ).casualtyRelays,
      0,
    );
  });
}
