import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/game/tokenfront_game.dart';
import 'package:tokenfront/story/story_catalog.dart';
import 'package:tokenfront/story/story_models.dart';

/// Small deterministic harness for the Chronicle reporting contract.
class ChronicleGameHarness {
  ChronicleGameHarness({required StoryOperation operation})
    : reports = <BattleReport>[] {
    game = TokenfrontGame(
      playerFaction: Faction.amethyst,
      mode: GameMode.chronicle,
      operation: operation,
      config: const BattleConfig(
        unitsPerFaction: 3,
        worldWidth: 600,
        worldHeight: 400,
        moveSpeed: 0,
        matchLimitSeconds: 180,
      ),
      hapticsEnabled: false,
      audioEnabled: false,
      onBattleConcluded: reports.add,
    );
  }

  final List<BattleReport> reports;
  late final TokenfrontGame game;

  void resolveKillBy({required int unitId}) {
    final winner = game.simulation.unitById(unitId)!;
    final loser = game.simulation.units.firstWhere(
      (unit) => unit.alive && unit.faction != winner.faction,
    );
    winner.position = const Vec2(300, 200);
    loser.position = winner.position;
    winner.state = AiState.seek;
    loser.state = AiState.seek;
    for (final unit in game.simulation.units) {
      if (unit.id != winner.id && unit.id != loser.id) unit.alive = false;
    }
    game.simulation.rebuildSpatialGrid();
  }

  void completeHandoff() {
    final controlled = game.simulation.controlledUnit!;
    controlled.alive = false;
    controlled.state = AiState.dead;
    game.update(1 / 30);
    _advance(1.6);
  }

  void failHandoffByEliminatingFaction() {
    for (final unit in game.simulation.units.where(
      (unit) => unit.faction == Faction.amethyst,
    )) {
      unit.alive = false;
      unit.state = AiState.dead;
    }
    game.update(1 / 30);
  }

  void eliminatePlayerFaction() {
    for (final unit in game.simulation.units.where(
      (unit) => unit.faction == Faction.amethyst,
    )) {
      unit.alive = false;
      unit.state = AiState.dead;
    }
  }

  void eliminatePlayerAndAllButOneFaction() {
    final survivor = game.simulation.units.firstWhere(
      (unit) => unit.faction != Faction.amethyst,
    );
    for (final unit in game.simulation.units) {
      if (unit.id == survivor.id) continue;
      unit.alive = false;
      unit.state = AiState.dead;
    }
  }

  void _advance(double seconds) {
    var remaining = seconds;
    while (remaining > 1e-9) {
      final dt = math.min(.05, remaining);
      game.update(dt);
      remaining -= dt;
    }
  }
}

void main() {
  test('command kills use controlled ID captured before the step', () {
    final harness = ChronicleGameHarness(
      operation: StoryCatalog.byId(StoryOperationId.split),
    );
    final commandedId = harness.game.simulation.controlledUnitId;
    harness.resolveKillBy(unitId: commandedId!);
    harness.game.update(1 / 30);
    expect(harness.game.commandKills, 1);
  });

  test('completed handoffs count and failed handoffs do not', () {
    final harness = ChronicleGameHarness(
      operation: StoryCatalog.byId(StoryOperationId.echo),
    );
    harness.completeHandoff();
    harness.failHandoffByEliminatingFaction();
    expect(harness.game.commandRelays, 1);
  });

  test('player elimination reports standings without finishing simulation', () {
    final harness = ChronicleGameHarness(
      operation: StoryCatalog.byId(StoryOperationId.wake),
    );
    harness.eliminatePlayerFaction();
    harness.game.update(1 / 30);
    expect(
      harness.reports.single.endReason,
      ChronicleEndReason.playerEliminated,
    );
    expect(harness.game.simulation.result, isNull);
    expect(harness.game.simulation.finished, isFalse);
  });

  test('global resolution wins when player elimination resolves the match', () {
    final harness = ChronicleGameHarness(
      operation: StoryCatalog.byId(StoryOperationId.wake),
    );
    harness.eliminatePlayerAndAllButOneFaction();
    harness.game.update(1 / 30);

    expect(harness.reports, hasLength(1));
    expect(
      harness.reports.single.endReason,
      ChronicleEndReason.globalResolution,
    );
    expect(harness.reports.single.globalWinner, isNotNull);
    expect(harness.reports.single.playerSurvivors, 0);
  });

  test('initial final-rank directive progress uses the actual rank', () {
    final harness = ChronicleGameHarness(
      operation: StoryCatalog.byId(StoryOperationId.crown),
    );
    final expectedRank =
        harness.game.simulation.standings().indexWhere(
          (standing) => standing.faction == Faction.amethyst,
        ) +
        1;
    expect(harness.game.hud.value.directiveProgress?.current, expectedRank);
    expect(harness.game.hud.value.directiveProgress?.current, greaterThan(0));
  });
}
