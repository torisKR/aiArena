import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/game/simulation.dart';

void main() {
  test('4000-unit 30Hz performance baseline stays on spatial queries', () {
    final simulation = BattleSimulation(seed: 0x400);
    expect(simulation.units, hasLength(4000));
    final initialUnitPool = List<Unit>.of(simulation.units, growable: false);
    for (var index = 0; index < simulation.units.length; index++) {
      simulation.units[index].position = Vec2(
        1200 + (index % 100) * 10,
        900 + (index ~/ 100) * 10,
      );
    }
    simulation.rebuildSpatialGrid();

    // Force all four faction bands into one dense camera-sized region, then
    // feed a 60Hz renderer for 5 seconds. The core must produce 150 or fewer
    // fixed 30Hz ticks (fewer only if the match ends by elimination).
    final stopwatch = Stopwatch()..start();
    for (var renderFrame = 0; renderFrame < 5 * 60; renderFrame++) {
      simulation.step(1 / 60);
      if (simulation.finished) break;
    }
    stopwatch.stop();

    expect(simulation.simulationTickCount, greaterThan(0));
    expect(simulation.simulationTickCount, lessThanOrEqualTo(5 * 30));
    expect(simulation.grid.totalQueries, greaterThan(0));
    expect(simulation.grid.occupiedCellCount, greaterThan(0));
    expect(simulation.units, hasLength(4000));
    for (var index = 0; index < initialUnitPool.length; index++) {
      expect(
        identical(simulation.units[index], initialUnitPool[index]),
        isTrue,
        reason: 'Unit pool entry $index must be retained in place',
      );
    }
    expect(simulation.combatLog, isNotEmpty);
    expect(simulation.units.where((unit) => !unit.alive), isNotEmpty);

    final visitsPerTick =
        simulation.grid.totalCandidateVisits / simulation.simulationTickCount;
    const allPairsPerTick = 4000 * 4000;
    expect(
      visitsPerTick,
      lessThan(allPairsPerTick * 0.1),
      reason: 'SpatialGrid should remain well below a 4000x4000 all-pairs scan',
    );

    // This is deliberately generous across debug CI and local machines. The
    // algorithmic candidate-visit assertion above is the primary regression
    // guard; this wall-time ceiling catches catastrophic slowdowns.
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 8)));

    final report = <String, Object>{
      'unitsAllocated': simulation.units.length,
      'fixedSimulationHz': simulation.config.simulationHz,
      'sampleRenderFrames': 5 * 60,
      'simulationTicks': simulation.simulationTickCount,
      'spatialGridQueries': simulation.grid.totalQueries,
      'spatialGridCandidateVisits': simulation.grid.totalCandidateVisits,
      'candidateVisitsPerTick': visitsPerTick,
      'elapsedMilliseconds': stopwatch.elapsedMilliseconds,
    };
    debugPrint('TOKENFRONT_PERFORMANCE_BASELINE ${jsonEncode(report)}');
  });
}
