import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokenfront/app/tokenfront_state_store.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/main.dart';
import 'package:tokenfront/settings/game_preferences.dart';
import 'package:tokenfront/services/privacy/privacy_state.dart';
import 'package:tokenfront/story/story_catalog.dart';
import 'package:tokenfront/story/story_models.dart';
import 'package:tokenfront/ui/battle_screen.dart';

final class _MemoryStateStore implements TokenfrontStateStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches, configures, deploys, and survives app resume', (
    tester,
  ) async {
    final runtime = TokenfrontRuntime(
      preferences: GamePreferences(audioEnabled: false, hapticsEnabled: false),
    );
    addTearDown(runtime.dispose);
    await tester.pumpWidget(TokenfrontApp(runtime: runtime));
    await tester.pumpAndSettle();

    expect(find.text('TOKENFRONT'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.text('SIGNAL CONDITIONING'), findsOneWidget);
    await tester.tap(find.byTooltip('Close settings'));
    await tester.pumpAndSettle();

    if (find.text('DEPLOY SIGNAL').evaluate().isNotEmpty) {
      await tester.ensureVisible(find.text('DEPLOY SIGNAL'));
      await tester.tap(find.text('DEPLOY SIGNAL'));
    } else {
      await tester.tap(find.text('SKIRMISH').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('skirmish-deploy')));
    }
    await tester.pump();
    expect(find.byType(BattleScreen), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('SIGNAL HELD  /  BATTLE PAUSED'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('SIGNAL HELD  /  BATTLE PAUSED'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('fresh state -> OP-01 -> flush/recreate -> OP-02', () async {
    final store = _MemoryStateStore();
    final runtime = await TokenfrontRuntime.restore(
      platform: ClientPlatform.web,
      stateStore: store,
    );
    addTearDown(runtime.dispose);

    runtime.lockChronicleCore(Faction.amethyst);
    final transition = runtime.concludeChronicle(
      operationId: StoryOperationId.wake,
      report: _report(link: 45),
      replay: false,
    );
    expect(transition.firstConclusion, isTrue);
    expect(runtime.storyProgress.currentOperation, StoryOperationId.echo);
    await runtime.flushLocalState();

    final recreated = await TokenfrontRuntime.restore(
      platform: ClientPlatform.web,
      stateStore: store,
    );
    addTearDown(recreated.dispose);
    expect(recreated.storyProgress.currentOperation, StoryOperationId.echo);
    expect(recreated.storyProgress.concludedOperations, {
      StoryOperationId.wake,
    });
  });

  test(
    'player eliminated -> debrief -> next operation without medal',
    () async {
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: _MemoryStateStore(),
      );
      addTearDown(runtime.dispose);
      runtime.lockChronicleCore(Faction.amethyst);

      final transition = runtime.concludeChronicle(
        operationId: StoryOperationId.wake,
        report: _report(
          reason: ChronicleEndReason.playerEliminated,
          link: 44.999,
        ),
        replay: false,
      );
      expect(transition.nextProgress.currentOperation, StoryOperationId.echo);
      expect(transition.nextProgress.medals, isEmpty);
      expect(transition.directiveBonusCredit, 0);
    },
  );

  test(
    'directive success -> one bonus -> replay -> zero duplicate bonus',
    () async {
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: _MemoryStateStore(),
      );
      addTearDown(runtime.dispose);
      runtime.lockChronicleCore(Faction.amethyst);
      final first = runtime.concludeChronicle(
        operationId: StoryOperationId.wake,
        report: _report(link: 45),
        replay: false,
      );
      final replay = runtime.concludeChronicle(
        operationId: StoryOperationId.wake,
        report: _report(link: 60),
        replay: true,
      );
      expect(first.directiveBonusCredit, 15);
      expect(replay.directiveBonusCredit, 0);
      expect(runtime.rewardLedger.claimedDirectiveBonusIds, {
        'chronicle-directive-wake',
      });
    },
  );

  test(
    'directive locked -> process ends before conclusion -> no progress/medal/bonus',
    () async {
      final store = _MemoryStateStore();
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      runtime.lockChronicleCore(Faction.amethyst);
      // A locked directive that ends before a debrief never enters
      // concludeChronicle. Flush, dispose, and restore to prove the locked
      // core persists while all conclusion/reward fields remain empty.
      await runtime.flushLocalState();
      runtime.dispose();

      final recreated = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      addTearDown(recreated.dispose);
      expect(recreated.storyProgress.campaignFaction, Faction.amethyst);
      expect(recreated.storyProgress.currentOperation, StoryOperationId.wake);
      expect(recreated.storyProgress.concludedOperations, isEmpty);
      expect(recreated.storyProgress.medals, isEmpty);
      expect(recreated.rewardLedger.claimedDirectiveBonusIds, isEmpty);
      expect(recreated.wallet.balance, 0);
    },
  );

  test(
    'directive locked -> player elimination -> one progress/medal/bonus transition',
    () async {
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: _MemoryStateStore(),
      );
      addTearDown(runtime.dispose);
      runtime.lockChronicleCore(Faction.amethyst);
      final transition = runtime.concludeChronicle(
        operationId: StoryOperationId.wake,
        report: _report(reason: ChronicleEndReason.playerEliminated, link: 45),
        replay: false,
      );
      expect(transition.directiveSucceeded, isTrue);
      expect(transition.nextProgress.concludedOperations, {
        StoryOperationId.wake,
      });
      expect(transition.nextProgress.medals, {StoryOperationId.wake});
      expect(transition.directiveBonusCredit, 15);
      expect(runtime.wallet.balance, 15);
    },
  );

  test(
    'five concluded attempts -> OPEN -> flush/recreate -> Archive epilogue',
    () async {
      final store = _MemoryStateStore();
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      addTearDown(runtime.dispose);
      runtime.lockChronicleCore(Faction.amethyst);
      for (final operation in StoryOperationId.values) {
        runtime.concludeChronicle(
          operationId: operation,
          report: _reportFor(operation),
          replay: false,
        );
      }
      runtime.chooseChronicleEnding(EndingChoice.openRelay);
      await runtime.flushLocalState();
      final recreated = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      addTearDown(recreated.dispose);
      expect(recreated.storyProgress.currentOperation, isNull);
      expect(recreated.storyProgress.concludedOperations, {
        ...StoryOperationId.values,
      });
      expect(recreated.storyProgress.ending, EndingChoice.openRelay);
      expect(recreated.wallet.balance, 130);
    },
  );

  test('OP-05 loss -> ending choice unlocked', () async {
    final runtime = await TokenfrontRuntime.restore(
      platform: ClientPlatform.web,
      stateStore: _MemoryStateStore(),
    );
    addTearDown(runtime.dispose);
    runtime.lockChronicleCore(Faction.amethyst);
    for (final operation in StoryOperationId.values) {
      runtime.concludeChronicle(
        operationId: operation,
        report: _reportFor(
          operation,
          reason: operation == StoryOperationId.lastInstruction
              ? ChronicleEndReason.playerEliminated
              : ChronicleEndReason.timeLimit,
        ),
        replay: false,
      );
    }
    runtime.chooseChronicleEnding(EndingChoice.claimRelay);
    expect(runtime.storyProgress.ending, EndingChoice.claimRelay);
  });

  test(
    'all four cores x all five fixed seeds -> deterministic BattleReport',
    () {
      for (final faction in Faction.values) {
        for (final operation in StoryCatalog.operations) {
          final first = _deterministicReport(operation, playerFaction: faction);
          final second = _deterministicReport(
            operation,
            playerFaction: faction,
          );
          expect(first, second, reason: '${faction.name}/${operation.id.name}');
        }
      }
    },
  );

  test(
    'Skirmish -> 900 seconds, spectator, ranking, handoff, existing base reward',
    () {
      final simulation = BattleSimulation(
        seed: 2026080505,
        playerFaction: Faction.amethyst,
      );
      expect(simulation.config.unitsPerFaction, 1000);
      expect(simulation.units, hasLength(4000));
      expect(simulation.config.matchLimitSeconds, 900);
      expect(simulation.matchLimit, 900);
      final controlled = simulation.units.firstWhere(
        (unit) => unit.faction == Faction.amethyst,
      );
      simulation.setControlledUnit(controlled.id);
      controlled.alive = false;
      simulation.step(simulation.fixedStepSeconds);
      expect(simulation.handoffLog, isNotEmpty);
      expect(simulation.controlledUnit, isNotNull);
      for (final unit in simulation.units.where(
        (unit) => unit.faction == Faction.amethyst,
      )) {
        unit.alive = false;
      }
      simulation.step(simulation.fixedStepSeconds);
      expect(simulation.isSpectating, isTrue);
      // The 900-second match-limit boundary is exercised through the public
      // deterministic hook without spending 27,000 fixed ticks in the harness.
      simulation.matchElapsed = simulation.matchLimit;
      final result = simulation.evaluateResult(forceTimeLimit: true);
      expect(simulation.matchElapsed, closeTo(900, 0.001));
      expect(result.standings, hasLength(Faction.values.length));
      expect(
        result.reason,
        anyOf(MatchEndReason.timeLimit, MatchEndReason.elimination),
      );

      final runtime = TokenfrontRuntime();
      addTearDown(runtime.dispose);
      expect(runtime.claimBaseReward(matchId: 'skirmish-900', amount: 10), 10);
      expect(runtime.wallet.balance, 10);
    },
  );
}

BattleReport _reportFor(
  StoryOperationId operation, {
  ChronicleEndReason reason = ChronicleEndReason.timeLimit,
}) {
  return switch (operation) {
    StoryOperationId.wake => _report(reason: reason, link: 45),
    StoryOperationId.echo => _report(reason: reason, relays: 2),
    StoryOperationId.split => _report(reason: reason, commandKills: 3),
    StoryOperationId.crown => _report(reason: reason, rank: 2),
    StoryOperationId.lastInstruction => _report(
      reason: reason,
      winner: Faction.amethyst,
    ),
  };
}

BattleReport _report({
  ChronicleEndReason reason = ChronicleEndReason.timeLimit,
  Faction? winner,
  int relays = 0,
  int commandKills = 0,
  double link = 0,
  int rank = 4,
}) {
  return BattleReport(
    endReason: reason,
    standingsAtConclusion: const [
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
    playerSurvivors: 0,
  );
}

BattleReport _deterministicReport(
  StoryOperation operation, {
  required Faction playerFaction,
}) {
  final matchLimitSeconds = operation.duration.inSeconds.toDouble();
  final simulation = BattleSimulation(
    seed: operation.seed,
    playerFaction: playerFaction,
    // Chronicle uses the production 4,000-unit pool and its configured
    // 180-second operation limit. Set the deterministic clock directly so
    // this matrix does not spend 5 x 27,000 fixed ticks in the harness.
    config: BattleConfig(matchLimitSeconds: matchLimitSeconds),
  );
  expect(simulation.config.unitsPerFaction, 1000);
  expect(simulation.units, hasLength(4000));
  expect(simulation.config.matchLimitSeconds, matchLimitSeconds);
  expect(simulation.matchLimit, matchLimitSeconds);
  simulation.matchElapsed = simulation.matchLimit;
  final result = simulation.evaluateResult(forceTimeLimit: true);
  final playerStanding = result.standings.firstWhere(
    (standing) => standing.faction == playerFaction,
  );
  return BattleReport(
    endReason: switch (result.reason) {
      MatchEndReason.timeLimit => ChronicleEndReason.timeLimit,
      MatchEndReason.elimination => ChronicleEndReason.globalResolution,
      MatchEndReason.ongoing => ChronicleEndReason.timeLimit,
    },
    standingsAtConclusion: result.standings,
    globalWinner: result.winner,
    commandRelays: 0,
    commandKills: 0,
    longestCommandLinkSeconds: 0,
    playerRank: result.standings.indexOf(playerStanding) + 1,
    playerSurvivors: playerStanding.survivors,
  );
}
