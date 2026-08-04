import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/game/simulation.dart';

Unit _unit({
  required int id,
  required Faction faction,
  required int level,
  Vec2 position = Vec2.zero,
}) => Unit(id: id, faction: faction, level: level, position: position);

void _leaveOnly(BattleSimulation simulation, Iterable<Unit> survivors) {
  final survivorIds = survivors.map((unit) => unit.id).toSet();
  for (final unit in simulation.units) {
    unit.alive = survivorIds.contains(unit.id);
    unit.state = unit.alive ? AiState.spawn : AiState.dead;
    unit.velocity = Vec2.zero;
    unit.combatLockRemaining = 0;
    unit.recoverRemaining = 0;
  }
  simulation.rebuildSpatialGrid();
}

void main() {
  group('army spawning', () {
    test('spawns four armies of 1000 and exactly 4000 units', () {
      final simulation = BattleSimulation(seed: 20260715);

      expect(simulation.units, hasLength(4000));
      for (final faction in Faction.values) {
        expect(simulation.aliveUnits(faction), hasLength(1000));
      }
    });

    test('every faction gets the same uniform Lv.1-10 distribution', () {
      final simulation = BattleSimulation(seed: 9);

      for (final faction in Faction.values) {
        final counts = <int, int>{};
        for (final unit in simulation.aliveUnits(faction)) {
          counts.update(unit.level, (count) => count + 1, ifAbsent: () => 1);
        }
        expect(
          counts.keys.toSet(),
          equals(Set<int>.from(List.generate(10, (i) => i + 1))),
        );
        for (var level = 1; level <= 10; level++) {
          expect(counts[level], 100, reason: '${faction.label} Lv.$level');
        }
      }
    });

    test('stages each 1000-unit army across a sparse safe quadrant', () {
      final simulation = BattleSimulation(seed: 20260715);
      final config = simulation.config;
      final occupancy = <String, int>{};

      for (final unit in simulation.units) {
        final isLeft =
            unit.faction == Faction.claude || unit.faction == Faction.grok;
        final isTop =
            unit.faction == Faction.claude || unit.faction == Faction.codex;
        expect(
          unit.position.x,
          isLeft ? inInclusiveRange(120, 1200) : inInclusiveRange(2400, 3480),
        );
        expect(
          unit.position.y,
          isTop ? inInclusiveRange(120, 800) : inInclusiveRange(1600, 2280),
        );
        final cellX = (unit.position.x / config.gridCellSize).floor();
        final cellY = (unit.position.y / config.gridCellSize).floor();
        final key = '${unit.faction.name}:$cellX:$cellY';
        occupancy.update(key, (value) => value + 1, ifAbsent: () => 1);
      }

      expect(occupancy.values.reduce(math.max), lessThanOrEqualTo(30));
      for (final unit in simulation.units) {
        expect(
          simulation.grid.nearestEnemy(unit, radius: config.combatRange),
          isNull,
        );
      }
    });

    test('expanded staging delays mass combat without stalling the battle', () {
      final simulation = BattleSimulation(seed: 20260715);

      simulation.step(3);
      expect(simulation.combatLog, isEmpty);
      expect(simulation.aliveUnits(), hasLength(4000));

      simulation.step(9);
      expect(simulation.combatLog, isNotEmpty);
      expect(simulation.aliveUnits().length, lessThan(4000));
    });
  });

  test('default movement is 64 world units per second with a 1.9x dash', () {
    const config = BattleConfig(
      unitsPerFaction: 10,
      visionRange: 1,
      combatRange: .1,
      separationStrength: 0,
    );
    expect(config.moveSpeed, 64);

    final simulation = BattleSimulation(
      seed: 64,
      config: config,
      playerFaction: Faction.claude,
    );
    final controlled = simulation.controlledUnit!;
    final start = controlled.position;

    simulation.setPlayerInput(const Vec2(1, 0));
    simulation.step(1 / config.simulationHz);
    expect(controlled.position.x - start.x, closeTo(64 / 30, 1e-9));

    final dashStart = controlled.position;
    simulation.setPlayerInput(const Vec2(1, 0), dash: true);
    simulation.step(1 / config.simulationHz);
    expect(controlled.position.x - dashStart.x, closeTo(64 * 1.9 / 30, 1e-9));
  });

  group('combat rules', () {
    test('higher level wins all 10,000 unequal-level trials', () {
      final resolver = CombatResolver(SeededRandom(123));

      for (var trial = 0; trial < 10000; trial++) {
        final highFirst = trial.isEven;
        final winner = highFirst
            ? resolver.winnerIndex(10, 1)
            : resolver.winnerIndex(1, 10);
        expect(winner, highFirst ? 0 : 1);
      }
    });

    test('equal levels stay inside a 49-51% band over 100,000 trials', () {
      final resolver = CombatResolver(SeededRandom(0x5eed));
      var firstWins = 0;

      for (var trial = 0; trial < 100000; trial++) {
        if (resolver.winnerIndex(7, 7) == 0) firstWins++;
      }

      final rate = firstWins / 100000;
      expect(rate, inInclusiveRange(0.49, 0.51));
    });

    test('duel is atomic and winner is locked through recovery', () {
      final resolver = CombatResolver(
        SeededRandom(1),
        combatLockDuration: 0.4,
        recoverDuration: 0.35,
      );
      final high = _unit(id: 1, faction: Faction.claude, level: 10);
      final low = _unit(id: 2, faction: Faction.codex, level: 1);
      final third = _unit(id: 3, faction: Faction.grok, level: 1);

      final event = resolver.resolve(high, low, timestamp: 2.0);

      expect(event?.winnerId, high.id);
      expect(low.alive, isFalse);
      expect(high.kills, 1);
      expect(high.state, AiState.recover);
      expect(high.combatLockRemaining, 0.4);
      expect(resolver.resolve(high, third, timestamp: 2.0), isNull);
    });
  });

  test(
    'SpatialGrid finds adjacent enemies without returning distant cells',
    () {
      final grid = SpatialGrid(cellSize: 50);
      final source = _unit(
        id: 1,
        faction: Faction.claude,
        level: 5,
        position: const Vec2(49, 25),
      );
      final adjacent = _unit(
        id: 2,
        faction: Faction.codex,
        level: 5,
        position: const Vec2(51, 25),
      );
      final distant = _unit(
        id: 3,
        faction: Faction.grok,
        level: 5,
        position: const Vec2(400, 25),
      );
      grid.rebuild([source, adjacent, distant]);

      expect(grid.nearestEnemy(source, radius: 30)?.id, adjacent.id);
      expect(
        grid.queryNearby(source.position, radius: 30).map((unit) => unit.id),
        containsAll([source.id, adjacent.id]),
      );
      expect(
        grid.queryNearby(source.position, radius: 30).map((unit) => unit.id),
        isNot(contains(distant.id)),
      );
      expect(
        grid.queryAdjacent(source.position).map((unit) => unit.id),
        containsAll([source.id, adjacent.id]),
      );
      expect(
        grid.queryAdjacent(source.position).map((unit) => unit.id),
        isNot(contains(distant.id)),
      );
    },
  );

  test('SpatialGrid skips allied buckets during enemy searches', () {
    final grid = SpatialGrid(cellSize: 100);
    final source = _unit(
      id: 0,
      faction: Faction.claude,
      level: 5,
      position: const Vec2(50, 50),
    );
    final allies = List<Unit>.generate(
      1000,
      (index) => _unit(
        id: index + 1,
        faction: Faction.claude,
        level: 5,
        position: const Vec2(55, 55),
      ),
    );
    final enemy = _unit(
      id: 2000,
      faction: Faction.codex,
      level: 5,
      position: const Vec2(60, 60),
    );
    grid.rebuild([source, ...allies, enemy]);
    grid.resetMetrics();

    expect(grid.nearestEnemy(source, radius: 40), same(enemy));
    expect(grid.totalCandidateVisits, 1);
  });

  test('render updates accumulate into a deterministic 30Hz simulation', () {
    final simulation = BattleSimulation(seed: 5);

    for (var renderFrame = 0; renderFrame < 3; renderFrame++) {
      simulation.step(1 / 120);
    }
    expect(simulation.simulationTickCount, 0);
    expect(simulation.matchElapsed, 0);

    simulation.step(1 / 120);
    expect(simulation.simulationTickCount, 1);
    expect(simulation.matchElapsed, closeTo(1 / 30, 1e-12));
    expect(simulation.fixedStepSeconds, 1 / 30);
  });

  test('AI decision cadence remains between 10Hz and 15Hz', () {
    const config = BattleConfig(
      moveSpeed: 0,
      visionRange: 1,
      combatRange: 0.1,
      separationStrength: 0,
    );
    final simulation = BattleSimulation(seed: 303, config: config);
    final survivors = Faction.values
        .map(
          (faction) =>
              simulation.units.firstWhere((unit) => unit.faction == faction),
        )
        .toList();
    _leaveOnly(simulation, survivors);

    simulation.step(30);

    expect(simulation.simulationTickCount, 900);
    for (final unit in survivors) {
      final decisionsPerSecond =
          unit.aiDecisionCount *
          config.simulationHz /
          simulation.simulationTickCount;
      expect(
        decisionsPerSecond,
        inInclusiveRange(10.0, 15.0),
        reason: '${unit.faction.label}: $decisionsPerSecond Hz',
      );
    }
  });

  test(
    'far idle AI is throttled while near and tactical AI stays at 10-15Hz',
    () {
      const config = BattleConfig(
        moveSpeed: 0,
        visionRange: 1,
        combatRange: 0.1,
        separationStrength: 0,
        farAiDistance: 400,
        farAiDecisionInterval: 0.2,
      );
      final simulation = BattleSimulation(
        seed: 304,
        config: config,
        playerFaction: Faction.claude,
      );
      final controlled = simulation.controlledUnit!;
      final allies = simulation.units
          .where(
            (unit) =>
                unit.faction == Faction.claude && unit.id != controlled.id,
          )
          .take(3)
          .toList();
      final nearIdle = allies[0];
      final farIdle = allies[1];
      final farTactical = allies[2];
      final target = simulation.units.firstWhere(
        (unit) => unit.faction == Faction.codex,
      );
      _leaveOnly(simulation, [
        controlled,
        nearIdle,
        farIdle,
        farTactical,
        target,
      ]);
      controlled.position = const Vec2(100, 100);
      nearIdle.position = const Vec2(250, 100);
      farIdle.position = const Vec2(2050, 1250);
      farTactical.position = const Vec2(1800, 1100);
      target.position = const Vec2(1100, 700);
      for (final unit in [nearIdle, farIdle]) {
        unit
          ..state = AiState.seek
          ..targetId = null;
      }
      farTactical
        ..state = AiState.chase
        ..targetId = target.id;
      target
        ..state = AiState.seek
        ..targetId = null;
      simulation.rebuildSpatialGrid();

      expect(simulation.shouldThrottleAi(nearIdle), isFalse);
      expect(simulation.shouldThrottleAi(farIdle), isTrue);
      expect(simulation.shouldThrottleAi(farTactical), isFalse);

      simulation.step(30);

      double rate(Unit unit) =>
          unit.aiDecisionCount /
          (simulation.simulationTickCount / config.simulationHz);

      expect(simulation.simulationTickCount, 900);
      expect(rate(nearIdle), inInclusiveRange(10.0, 15.0));
      expect(rate(farTactical), inInclusiveRange(10.0, 15.0));
      expect(rate(farIdle), inInclusiveRange(4.0, 6.0));
      expect(farIdle.throttledAiDecisionCount, greaterThan(0));
      expect(farTactical.throttledAiDecisionCount, 0);
      expect(simulation.debugThrottledAiDecisionCount, greaterThan(0));
      expect(
        simulation.debugNormalAiDecisionCount +
            simulation.debugThrottledAiDecisionCount,
        simulation.totalAiDecisions,
      );
    },
  );

  test('far AI throttling is deterministic across render frame cadences', () {
    const config = BattleConfig(unitsPerFaction: 100);
    final first = BattleSimulation(
      seed: 0x5eed,
      config: config,
      playerFaction: Faction.claude,
    );
    final second = BattleSimulation(
      seed: 0x5eed,
      config: config,
      playerFaction: Faction.claude,
    );

    for (var frame = 0; frame < 6 * 30; frame++) {
      first.step(1 / 30);
      second.step(1 / 60);
      second.step(1 / 60);
    }

    expect(first.simulationTickCount, second.simulationTickCount);
    expect(first.debugThrottledAiDecisionCount, greaterThan(0));
    expect(
      first.debugThrottledAiDecisionCount,
      second.debugThrottledAiDecisionCount,
    );
    expect(first.debugNormalAiDecisionCount, second.debugNormalAiDecisionCount);
    for (var index = 0; index < first.units.length; index++) {
      final a = first.units[index];
      final b = second.units[index];
      expect(a.position, b.position, reason: 'position for unit ${a.id}');
      expect(a.state, b.state, reason: 'state for unit ${a.id}');
      expect(
        a.aiDecisionCount,
        b.aiDecisionCount,
        reason: 'decision count for unit ${a.id}',
      );
      expect(
        a.throttledAiDecisionCount,
        b.throttledAiDecisionCount,
        reason: 'throttled count for unit ${a.id}',
      );
    }
    expect(first.exportDebugCombatLog(), second.exportDebugCombatLog());
  });

  test('low-level AI flees from a stronger nearby target', () {
    const config = BattleConfig(lowLevelFleeChance: 1, separationStrength: 0);
    final simulation = BattleSimulation(seed: 44, config: config);
    final weak = simulation.units.firstWhere(
      (unit) => unit.faction == Faction.claude && unit.level == 1,
    );
    final strong = simulation.units.firstWhere(
      (unit) => unit.faction == Faction.codex && unit.level == 10,
    );
    for (final unit in simulation.units) {
      unit.alive = unit.id == weak.id || unit.id == strong.id;
      if (!unit.alive) unit.state = AiState.dead;
    }
    weak.position = const Vec2(500, 500);
    strong.position = const Vec2(600, 500);
    weak.state = AiState.seek;
    strong.state = AiState.seek;

    simulation.step(1 / 30);

    expect(weak.state, AiState.flee);
    expect(weak.velocity.x, lessThan(0));
  });

  test('seek uses a faction rally and separation prevents ally stacking', () {
    const config = BattleConfig(
      visionRange: 1,
      separationRadius: 40,
      separationStrength: 1,
    );
    final simulation = BattleSimulation(seed: 54, config: config);
    final allies = simulation.units
        .where((unit) => unit.faction == Faction.claude)
        .take(2)
        .toList();
    final distantEnemy = simulation.units.firstWhere(
      (unit) => unit.faction == Faction.codex,
    );
    _leaveOnly(simulation, [...allies, distantEnemy]);
    for (final ally in allies) {
      ally.position = const Vec2(500, 500);
      ally.state = AiState.seek;
    }
    distantEnemy.position = const Vec2(2100, 1300);

    simulation.step(1 / 30);

    final rallyDirection =
        simulation.rallyPointFor(Faction.claude) - const Vec2(500, 500);
    for (final ally in allies) {
      final dot =
          ally.velocity.x * rallyDirection.x +
          ally.velocity.y * rallyDirection.y;
      expect(dot, greaterThan(0), reason: 'seek should face the rally point');
    }
    expect(allies[0].position, isNot(equals(allies[1].position)));
  });

  test('same seed and input reproduce spawn and core combat log', () {
    const config = BattleConfig(unitsPerFaction: 100);
    final first = BattleSimulation(
      seed: 777,
      config: config,
      playerFaction: Faction.claude,
    );
    final second = BattleSimulation(
      seed: 777,
      config: config,
      playerFaction: Faction.claude,
    );

    for (var i = 0; i < first.units.length; i++) {
      expect(first.units[i].level, second.units[i].level);
      expect(first.units[i].position, second.units[i].position);
      final local = first.units[i].id % config.unitsPerFaction;
      final clustered = Vec2(
        850 + (local % 10) * 28.0,
        520 + (local ~/ 10) * 28.0,
      );
      first.units[i].position = clustered;
      second.units[i].position = clustered;
    }
    first.setPlayerInput(const Vec2(1, 0), dash: true);
    second.setPlayerInput(const Vec2(1, 0), dash: true);

    for (var frame = 0; frame < 8; frame++) {
      first.step(1 / 30);
      second.step(1 / 60);
      second.step(1 / 60);
    }

    expect(first.combatLog, isNotEmpty);
    expect(
      first.combatLog.map((event) => event.replayKey),
      orderedEquals(second.combatLog.map((event) => event.replayKey)),
    );
    expect(first.controlledUnitId, second.controlledUnitId);

    final firstExport = first.exportDebugCombatLog();
    final secondExport = second.exportDebugCombatLog();
    expect(firstExport, equals(secondExport));
    expect(firstExport['matchSeed'], 777);
    expect(firstExport['combatCount'], first.combatLog.length);
    expect(firstExport['events'], isNotEmpty);

    final jsonExport = jsonDecode(first.exportDebugCombatLogJson());
    expect(jsonExport['matchSeed'], 777);
    expect(jsonExport['events'], hasLength(first.combatLog.length));
  });

  group('player handoff', () {
    test('weights level 50%, safety 30%, and non-combat 20%', () {
      final candidate = _unit(id: 9, faction: Faction.claude, level: 10);
      expect(
        HandoffCandidateScore(
          unit: candidate,
          levelScore: 1,
          safetyScore: 0,
          nonCombatScore: 0,
        ).total,
        0.5,
      );
      expect(
        HandoffCandidateScore(
          unit: candidate,
          levelScore: 0,
          safetyScore: 1,
          nonCombatScore: 0,
        ).total,
        0.3,
      );
      expect(
        HandoffCandidateScore(
          unit: candidate,
          levelScore: 0,
          safetyScore: 0,
          nonCombatScore: 1,
        ).total,
        0.2,
      );
    });

    test(
      'selects a live same-faction successor and excludes the fallen unit',
      () {
        final simulation = BattleSimulation(
          seed: 101,
          playerFaction: Faction.gemini,
        );
        final fallen = simulation.controlledUnit!;
        fallen.alive = false;
        fallen.state = AiState.dead;

        final successor = simulation.selectHandoff(
          faction: fallen.faction,
          fallenUnitId: fallen.id,
        );

        expect(successor, isNotNull);
        expect(successor!.alive, isTrue);
        expect(successor.faction, fallen.faction);
        expect(successor.id, isNot(fallen.id));
        final score = simulation.scoreHandoffCandidate(successor);
        expect(score.total, inInclusiveRange(0.0, 1.0));
      },
    );

    test('returns null immediately when the faction has no survivor', () {
      final simulation = BattleSimulation(
        seed: 102,
        playerFaction: Faction.grok,
      );
      for (final unit in simulation.units) {
        if (unit.faction == Faction.grok) {
          unit.alive = false;
          unit.state = AiState.dead;
        }
      }

      expect(simulation.selectHandoff(faction: Faction.grok), isNull);
    });

    test('combat hands control off in the same tick, under 1.5 seconds', () {
      const config = BattleConfig(separationStrength: 0);
      final simulation = BattleSimulation(
        seed: 180,
        config: config,
        playerFaction: Faction.claude,
      );
      final fallen = simulation.units.firstWhere(
        (unit) => unit.faction == Faction.claude && unit.level == 1,
      );
      final successor = simulation.units.firstWhere(
        (unit) => unit.faction == Faction.claude && unit.level == 10,
      );
      final attacker = simulation.units.firstWhere(
        (unit) => unit.faction == Faction.codex && unit.level == 10,
      );
      final grok = simulation.units.firstWhere(
        (unit) => unit.faction == Faction.grok,
      );
      _leaveOnly(simulation, [fallen, successor, attacker, grok]);
      fallen.position = const Vec2(500, 500);
      attacker.position = const Vec2(500, 500);
      successor.position = const Vec2(100, 100);
      grok.position = const Vec2(1800, 1100);
      simulation.setControlledUnit(fallen.id);

      simulation.step(1 / 30);

      expect(fallen.alive, isFalse);
      expect(simulation.controlledUnitId, successor.id);
      expect(simulation.handoffLog, hasLength(1));
      expect(
        simulation.handoffLog.single.timestamp,
        lessThanOrEqualTo(config.handoffDeadlineSeconds),
      );
      expect(simulation.playerFactionEliminated, isFalse);
    });

    test(
      'no successor marks player eliminated but battle keeps spectating',
      () {
        const config = BattleConfig(separationStrength: 0);
        final simulation = BattleSimulation(
          seed: 181,
          config: config,
          playerFaction: Faction.claude,
        );
        final fallen = simulation.units.firstWhere(
          (unit) => unit.faction == Faction.claude && unit.level == 1,
        );
        final attacker = simulation.units.firstWhere(
          (unit) => unit.faction == Faction.codex && unit.level == 10,
        );
        final grok = simulation.units.firstWhere(
          (unit) => unit.faction == Faction.grok,
        );
        final gemini = simulation.units.firstWhere(
          (unit) => unit.faction == Faction.gemini,
        );
        _leaveOnly(simulation, [fallen, attacker, grok, gemini]);
        fallen.position = const Vec2(500, 500);
        attacker.position = const Vec2(500, 500);
        grok.position = const Vec2(1700, 1100);
        gemini.position = const Vec2(200, 1100);
        simulation.setControlledUnit(fallen.id);

        simulation.step(1 / 30);

        expect(simulation.controlledUnitId, isNull);
        expect(simulation.playerFactionEliminated, isTrue);
        expect(simulation.playerEliminatedAt, closeTo(1 / 30, 1e-12));
        expect(simulation.isSpectating, isTrue);
        expect(simulation.finished, isFalse);
        expect(simulation.handoffLog.single.factionEliminated, isTrue);

        final elapsedAtElimination = simulation.matchElapsed;
        simulation.step(1 / 30);
        expect(simulation.matchElapsed, greaterThan(elapsedAtElimination));
        expect(simulation.isSpectating, isTrue);
      },
    );
  });

  group('15-minute ranking', () {
    BattleSimulation emptySimulation() {
      final simulation = BattleSimulation(seed: 4);
      for (final unit in simulation.units) {
        unit.alive = false;
        unit.state = AiState.dead;
        unit.kills = 0;
      }
      return simulation;
    }

    test('survivor count is the first tie-break', () {
      final simulation = emptySimulation();
      final claude = simulation.units
          .where((unit) => unit.faction == Faction.claude && unit.level == 1)
          .take(2)
          .toList();
      final codex = simulation.units.firstWhere(
        (unit) => unit.faction == Faction.codex && unit.level == 10,
      );
      for (final unit in claude) {
        unit.alive = true;
      }
      codex
        ..alive = true
        ..kills = 100;

      expect(
        simulation.evaluateResult(forceTimeLimit: true).winner,
        Faction.claude,
      );
    });

    test('level sum is the second tie-break', () {
      final simulation = emptySimulation();
      final claude = simulation.units
          .where((unit) => unit.faction == Faction.claude)
          .toList();
      final codex = simulation.units
          .where((unit) => unit.faction == Faction.codex)
          .toList();
      claude.firstWhere((unit) => unit.level == 10).alive = true;
      claude.firstWhere((unit) => unit.level == 1).alive = true;
      codex
          .where((unit) => unit.level == 5)
          .take(2)
          .forEach((unit) => unit.alive = true);

      final result = simulation.evaluateResult(forceTimeLimit: true);

      expect(result.reason, MatchEndReason.timeLimit);
      expect(result.winner, Faction.claude);
      expect(result.standings.first.survivors, 2);
      expect(result.standings.first.levelSum, 11);
    });

    test('cumulative kills, including dead units, are the final tie-break', () {
      final simulation = emptySimulation();
      final claudeAlive = simulation.units.firstWhere(
        (unit) => unit.faction == Faction.claude && unit.level == 5,
      );
      final codexAlive = simulation.units.firstWhere(
        (unit) => unit.faction == Faction.codex && unit.level == 5,
      );
      claudeAlive.alive = true;
      codexAlive.alive = true;
      simulation.units
              .firstWhere(
                (unit) =>
                    unit.faction == Faction.claude && unit.id != claudeAlive.id,
              )
              .kills =
          8;
      simulation.units
              .firstWhere(
                (unit) =>
                    unit.faction == Faction.codex && unit.id != codexAlive.id,
              )
              .kills =
          9;

      expect(
        simulation.evaluateResult(forceTimeLimit: true).winner,
        Faction.codex,
      );
    });

    test('the match automatically finalizes at the configured time limit', () {
      const config = BattleConfig(
        matchLimitSeconds: 1,
        moveSpeed: 0,
        visionRange: 1,
        combatRange: 0.1,
        separationStrength: 0,
      );
      final simulation = BattleSimulation(seed: 88, config: config);
      final claude = simulation.units.firstWhere(
        (unit) => unit.faction == Faction.claude,
      );
      final codex = simulation.units.firstWhere(
        (unit) => unit.faction == Faction.codex,
      );
      _leaveOnly(simulation, [claude, codex]);

      simulation.step(1);

      expect(simulation.matchElapsed, closeTo(1, 1e-12));
      expect(simulation.finished, isTrue);
      expect(simulation.result?.reason, MatchEndReason.timeLimit);
    });
  });
}
