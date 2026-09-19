import 'simulation.dart';

enum RecoveryOutcome { recovered, timeout, alliesLost }

/// Match-owned objective state. A command transfer never resets this state.
final class RecoveryState {
  static const config = BattleConfig(
    unitsPerFaction: 100,
    worldWidth: 1200,
    worldHeight: 800,
    matchLimitSeconds: 90,
  );
  static const requiredSeconds = 8.0;
  static const midwaySeconds = 5.0;
  static const radius = 64.0;
  static const destinations = [Vec2(300, 240), Vec2(900, 240), Vec2(600, 600)];
  final List<double> _seconds = [0, 0, 0];
  final List<bool> _midwayCued = [false, false, false];
  int selected = 0;
  RecoveryOutcome? outcome;

  List<double> get seconds => List.unmodifiable(_seconds);
  int get recoveredCount =>
      _seconds.where((value) => value >= requiredSeconds).length;
  bool get succeeded => outcome == RecoveryOutcome.recovered;
  int get reward =>
      succeeded ? (recoveredCount * 20 < 40 ? 40 : recoveredCount * 20) : 0;

  void reset() {
    _seconds.fillRange(0, 3, 0);
    _midwayCued.fillRange(0, 3, false);
    selected = 0;
    outcome = null;
  }

  bool select(int index) {
    if (outcome != null ||
        index < 0 ||
        index >= 3 ||
        _seconds[index] >= requiredSeconds) {
      return false;
    }
    selected = index;
    return true;
  }

  /// Returns destination indices that crossed [midwaySeconds] this tick.
  List<int> advanceMidwayCues() {
    final cues = <int>[];
    for (var index = 0; index < 3; index++) {
      if (_midwayCued[index]) continue;
      if (_seconds[index] >= midwaySeconds &&
          _seconds[index] < requiredSeconds) {
        _midwayCued[index] = true;
        cues.add(index);
      }
    }
    return cues;
  }

  Vec2 direction(Unit unit) {
    final delta = destinations[selected] - unit.position;
    return delta.length <= radius * .5 ? Vec2.zero : delta.normalized();
  }

  void advance({
    required Unit? unit,
    required double dt,
    required bool alliesLost,
    required bool deadline,
  }) {
    if (outcome != null) return;
    if (unit != null &&
        unit.alive &&
        unit.position.distanceTo(destinations[selected]) <= radius) {
      _seconds[selected] = (_seconds[selected] + dt).clamp(0, requiredSeconds);
      if (_seconds[selected] >= requiredSeconds - 1e-9) {
        _seconds[selected] = requiredSeconds;
        for (var index = 0; index < 3; index++) {
          if (_seconds[index] < requiredSeconds) {
            selected = index;
            break;
          }
        }
      }
    }
    // Objective completion on the last tick takes precedence over the deadline.
    if (recoveredCount == 3) {
      outcome = RecoveryOutcome.recovered;
    } else if (alliesLost) {
      outcome = RecoveryOutcome.alliesLost;
    } else if (deadline) {
      outcome = RecoveryOutcome.timeout;
    }
  }
}
