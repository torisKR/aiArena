import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/game/recovery.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/game/tokenfront_game.dart';
import 'package:tokenfront/story/story_catalog.dart';
import 'package:tokenfront/story/story_models.dart';

void main() {
  test('recovery selection rejects invalid and recovered destinations', () {
    final state = RecoveryState();
    expect(state.select(-1), isFalse);
    expect(state.select(3), isFalse);
    expect(state.select(2), isTrue);
    final unit = Unit(
      id: 0,
      faction: Faction.amethyst,
      level: 10,
      position: RecoveryState.destinations[2],
    );
    state.advance(unit: unit, dt: 8, alliesLost: false, deadline: false);
    expect(state.select(2), isFalse);
    expect(state.selected, 0);
    expect(state.reward, 0);
  });

  test('cumulative progress survives departure and a different receiver', () {
    final state = RecoveryState();
    final unit = Unit(
      id: 0,
      faction: Faction.amethyst,
      level: 10,
      position: RecoveryState.destinations[0],
    );
    state.advance(unit: unit, dt: 4, alliesLost: false, deadline: false);
    unit.position = Vec2.zero;
    state.advance(unit: unit, dt: 4, alliesLost: false, deadline: false);
    final receiver = Unit(
      id: 1,
      faction: Faction.amethyst,
      level: 10,
      position: RecoveryState.destinations[0],
    );
    state.advance(unit: receiver, dt: 6, alliesLost: false, deadline: false);
    expect(state.seconds[0], 8);
    expect(state.selected, 1);
  });

  test('last tick completion beats deadline and conclusion is immutable', () {
    final state = RecoveryState();
    final unit = Unit(
      id: 0,
      faction: Faction.amethyst,
      level: 10,
      position: Vec2.zero,
    );
    for (var index = 0; index < 3; index++) {
      unit.position = RecoveryState.destinations[index];
      state.advance(unit: unit, dt: 8, alliesLost: false, deadline: index == 2);
    }
    expect(state.outcome, RecoveryOutcome.recovered);
    state.advance(unit: null, dt: 90, alliesLost: true, deadline: true);
    expect(state.reward, 60);
    expect(state.outcome, RecoveryOutcome.recovered);
  });

  test('midway cue fires once per node at 5s and never after completion', () {
    final state = RecoveryState();
    final unit = Unit(
      id: 0,
      faction: Faction.amethyst,
      level: 10,
      position: RecoveryState.destinations[0],
    );

    // Below midway: no cue.
    state.advance(unit: unit, dt: 4, alliesLost: false, deadline: false);
    expect(state.advanceMidwayCues(), isEmpty);

    // Crossing 5s fires exactly once for node 0.
    state.advance(unit: unit, dt: 2, alliesLost: false, deadline: false);
    expect(state.advanceMidwayCues(), [0]);
    expect(state.advanceMidwayCues(), isEmpty);

    // Completing node 0 must not re-fire the cue.
    state.advance(unit: unit, dt: 2, alliesLost: false, deadline: false);
    expect(state.seconds[0], RecoveryState.requiredSeconds);
    expect(state.advanceMidwayCues(), isEmpty);

    // A second node fires its own cue independently.
    unit.position = RecoveryState.destinations[1];
    state.advance(unit: unit, dt: 5, alliesLost: false, deadline: false);
    expect(state.advanceMidwayCues(), [1]);

    // reset() clears cue latches.
    state.reset();
    expect(state.advanceMidwayCues(), isEmpty);
  });

  test('timeout and allies lost are distinct failures', () {
    final timeout = RecoveryState()
      ..advance(unit: null, dt: 0, alliesLost: false, deadline: true);
    final lost = RecoveryState()
      ..advance(unit: null, dt: 0, alliesLost: true, deadline: false);
    expect(timeout.outcome, RecoveryOutcome.timeout);
    expect(lost.outcome, RecoveryOutcome.alliesLost);
  });

  test(
    'explicit recovery automatically moves and hands off at normal speed',
    () {
      final game = TokenfrontGame(
        playerFaction: Faction.amethyst,
        mode: GameMode.chronicle,
        operation: StoryCatalog.byId(StoryOperationId.wake),
        recoveryMode: true,
        config: RecoveryState.config,
        audioEnabled: false,
        hapticsEnabled: false,
        onBattleConcluded: (_) {},
      );
      final simulation = game.simulation;
      game.acknowledgeRecoveryInstruction();
      expect(simulation.units.length, 400);
      expect(simulation.matchLimit, 90);
      final first = simulation.controlledUnit!;
      final before = first.position;
      game.update(1 / 30);
      expect(first.position, isNot(before));
      first.alive = false;
      game.update(1 / 30);
      expect(simulation.controlledUnitId, isNot(first.id));
      expect(game.handoffElapsed, -1);
      game.update(1 / 30);
      expect(simulation.matchElapsed, closeTo(.1, 1e-8));
      expect(game.triggerManualRelay(), isFalse);
      game.triggerDash();
      expect(game.debugDashActive, isFalse);
      simulation.spawnArmies();
      expect(simulation.recovery!.seconds, [0, 0, 0]);
      expect(simulation.matchElapsed, 0);
      game.dispose();
    },
  );

  test('legacy simulation stays opt-in and uses legacy defaults', () {
    final simulation = BattleSimulation();
    expect(simulation.recovery, isNull);
    expect(simulation.units.length, 4000);
    expect(simulation.matchLimit, 900);
  });
}
