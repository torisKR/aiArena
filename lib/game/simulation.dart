import 'dart:convert';
import 'dart:math' as math;

/// The four armies used by the MVP.
enum Faction { claude, codex, grok, gemini }

extension FactionLabel on Faction {
  String get label => switch (this) {
    Faction.claude => 'Claude',
    Faction.codex => 'Codex',
    Faction.grok => 'Grok',
    Faction.gemini => 'Gemini',
  };
}

/// AI states are intentionally UI-agnostic so they can be rendered in Flame,
/// logged by a CLI, or exercised in a plain Dart test.
enum AiState { spawn, seek, chase, engage, recover, flee, dead }

/// A small immutable vector used by the simulation instead of a Flutter or
/// Flame vector type.
class Vec2 {
  const Vec2(this.x, this.y);

  static const zero = Vec2(0, 0);

  final double x;
  final double y;

  double get lengthSquared => x * x + y * y;
  double get length => math.sqrt(lengthSquared);

  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);
  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);
  Vec2 operator *(double scalar) => Vec2(x * scalar, y * scalar);
  Vec2 operator /(double scalar) => Vec2(x / scalar, y / scalar);

  double distanceSquaredTo(Vec2 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return dx * dx + dy * dy;
  }

  double distanceTo(Vec2 other) => math.sqrt(distanceSquaredTo(other));

  Vec2 normalized() {
    final magnitude = length;
    return magnitude <= 1e-12 ? zero : this / magnitude;
  }

  Vec2 clamp({
    required double minX,
    required double maxX,
    required double minY,
    required double maxY,
  }) => Vec2(x.clamp(minX, maxX).toDouble(), y.clamp(minY, maxY).toDouble());

  @override
  bool operator ==(Object other) =>
      other is Vec2 && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Vec2($x, $y)';
}

/// Stable xorshift32 PRNG. Its sequence does not depend on dart:math's
/// implementation and is therefore suitable for replaying matches.
class SeededRandom {
  SeededRandom(int seed) : _state = _sanitize(seed);

  SeededRandom.fromState(int state) : _state = _sanitize(state);

  static const int _mask32 = 0xffffffff;
  static const int _nonZeroFallback = 0x6d2b79f5;

  int _state;

  int get state => _state;

  void reset(int seed) => _state = _sanitize(seed);

  static int _sanitize(int value) {
    final masked = value & _mask32;
    return masked == 0 ? _nonZeroFallback : masked;
  }

  int nextUint32() {
    var value = _state;
    value ^= (value << 13) & _mask32;
    value ^= value >>> 17;
    value ^= (value << 5) & _mask32;
    _state = value & _mask32;
    return _state;
  }

  double nextDouble() => nextUint32() / 0x100000000;

  bool nextBool() => nextDouble() < 0.5;

  int nextInt(int maxExclusive) {
    if (maxExclusive <= 0) {
      throw ArgumentError.value(maxExclusive, 'maxExclusive', 'must be > 0');
    }
    return nextUint32() % maxExclusive;
  }

  double nextSignedDouble() => nextDouble() * 2 - 1;

  void shuffle<T>(List<T> values) {
    for (var i = values.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final value = values[i];
      values[i] = values[j];
      values[j] = value;
    }
  }

  /// Creates a deterministic independent stream without advancing this one.
  SeededRandom fork(int salt) => SeededRandom(_state ^ salt);
}

class BattleConfig {
  const BattleConfig({
    this.unitsPerFaction = 1000,
    this.minLevel = 1,
    this.maxLevel = 10,
    this.worldWidth = 3600,
    this.worldHeight = 2400,
    this.gridCellSize = 96,
    this.unitRadius = 8,
    this.combatRange = 22,
    this.visionRange = 300,
    this.moveSpeed = 64,
    this.dashMultiplier = 1.9,
    this.aiDecisionInterval = 1 / 12,
    this.farAiDistance = 720,
    this.farAiDecisionInterval = 1 / 5,
    this.combatLockDuration = 0.42,
    this.recoverDuration = 0.42,
    this.fleeDistance = 190,
    this.lowLevelThreshold = 4,
    this.lowLevelFleeChance = 0.68,
    this.separationRadius = 22,
    this.separationStrength = 0.28,
    this.handoffSafetyRadius = 420,
    this.handoffDeadlineSeconds = 1.5,
    this.simulationHz = 30,
    this.matchLimitSeconds = 900,
  }) : assert(unitsPerFaction > 0),
       assert(minLevel > 0 && maxLevel >= minLevel),
       assert(gridCellSize > 0),
       assert(aiDecisionInterval >= 1 / 15),
       assert(aiDecisionInterval <= 1 / 10),
       assert(farAiDistance > 0),
       assert(farAiDecisionInterval * 0.9 > 1 / 10),
       assert(handoffDeadlineSeconds > 0),
       assert(simulationHz > 0),
       assert(matchLimitSeconds > 0);

  final int unitsPerFaction;
  final int minLevel;
  final int maxLevel;
  final double worldWidth;
  final double worldHeight;
  final double gridCellSize;
  final double unitRadius;
  final double combatRange;
  final double visionRange;
  final double moveSpeed;
  final double dashMultiplier;
  final double aiDecisionInterval;
  final double farAiDistance;
  final double farAiDecisionInterval;
  final double combatLockDuration;
  final double recoverDuration;
  final double fleeDistance;
  final int lowLevelThreshold;
  final double lowLevelFleeChance;
  final double separationRadius;
  final double separationStrength;
  final double handoffSafetyRadius;
  final double handoffDeadlineSeconds;
  final int simulationHz;
  final double matchLimitSeconds;

  double get simulationStepSeconds => 1 / simulationHz;
}

class Unit {
  Unit({
    required this.id,
    required this.faction,
    required this.level,
    required this.position,
    this.velocity = Vec2.zero,
    this.alive = true,
    this.kills = 0,
    this.state = AiState.spawn,
    this.combatLockRemaining = 0,
    this.recoverRemaining = 0,
    this.targetId,
    this.aiDecisionRemaining = 0,
    this.aiDecisionCount = 0,
    this.normalAiDecisionCount = 0,
    this.throttledAiDecisionCount = 0,
  }) : assert(level > 0);

  final int id;
  final Faction faction;
  final int level;
  Vec2 position;
  Vec2 velocity;
  bool alive;
  int kills;
  AiState state;
  double combatLockRemaining;
  double recoverRemaining;
  int? targetId;
  double aiDecisionRemaining;
  int aiDecisionCount;
  int normalAiDecisionCount;
  int throttledAiDecisionCount;

  bool get isCombatLocked => combatLockRemaining > 0;
  bool get isRecovering => recoverRemaining > 0 || state == AiState.recover;
  bool get isEngaged =>
      state == AiState.engage || isCombatLocked || isRecovering;

  @override
  String toString() =>
      'Unit($id, ${faction.label}, Lv.$level, $state, alive: $alive)';
}

/// Uniform spatial hash. Queries visit only the cells touched by the radius,
/// which turns nearest-target and collision searches into local operations.
class _SpatialBucket {
  _SpatialBucket()
    : byFaction = List<List<Unit>>.generate(
        Faction.values.length,
        (_) => <Unit>[],
        growable: false,
      );

  final List<List<Unit>> byFaction;
  int length = 0;

  void clear() {
    for (final units in byFaction) {
      units.clear();
    }
    length = 0;
  }

  void add(Unit unit) {
    byFaction[unit.faction.index].add(unit);
    length += 1;
  }
}

class SpatialGrid {
  SpatialGrid({required this.cellSize}) : assert(cellSize > 0);

  final double cellSize;
  final Map<int, _SpatialBucket> _cells = {};
  int _occupiedCellCount = 0;

  /// Lightweight counters let performance tests verify that the simulation
  /// stays on the local-query path instead of regressing to all-pairs scans.
  int totalQueries = 0;
  int totalCellsVisited = 0;
  int totalCandidateVisits = 0;

  int get occupiedCellCount => _occupiedCellCount;

  int _cellX(Vec2 position) => (position.x / cellSize).floor();
  int _cellY(Vec2 position) => (position.y / cellSize).floor();
  int _cellKey(int x, int y) => (x << 32) ^ (y & 0xffffffff);

  void resetMetrics() {
    totalQueries = 0;
    totalCellsVisited = 0;
    totalCandidateVisits = 0;
  }

  void clear() {
    _cells.clear();
    _occupiedCellCount = 0;
  }

  void insert(Unit unit) {
    if (!unit.alive) return;
    final key = _cellKey(_cellX(unit.position), _cellY(unit.position));
    var bucket = _cells[key];
    if (bucket == null) {
      bucket = _SpatialBucket();
      _cells[key] = bucket;
    }
    if (bucket.length == 0) _occupiedCellCount++;
    bucket.add(unit);
  }

  void rebuild(Iterable<Unit> units) {
    // Keep previously allocated cell buckets and reuse them on following
    // frames. The arena is bounded, so the map quickly reaches a steady size.
    for (final bucket in _cells.values) {
      bucket.clear();
    }
    _occupiedCellCount = 0;
    for (final unit in units) {
      insert(unit);
    }
  }

  /// Returns the exact-radius subset found by scanning only overlapping cells.
  List<Unit> queryNearby(Vec2 position, {required double radius}) {
    if (radius < 0) {
      throw ArgumentError.value(radius, 'radius', 'must be >= 0');
    }
    final minX = ((position.x - radius) / cellSize).floor();
    final maxX = ((position.x + radius) / cellSize).floor();
    final minY = ((position.y - radius) / cellSize).floor();
    final maxY = ((position.y + radius) / cellSize).floor();
    final radiusSquared = radius * radius;
    final result = <Unit>[];
    totalQueries++;

    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        totalCellsVisited++;
        final bucket = _cells[_cellKey(x, y)];
        if (bucket == null) continue;
        for (final factionUnits in bucket.byFaction) {
          for (final unit in factionUnits) {
            totalCandidateVisits++;
            if (unit.alive &&
                unit.position.distanceSquaredTo(position) <= radiusSquared) {
              result.add(unit);
            }
          }
        }
      }
    }
    result.sort((a, b) => a.id.compareTo(b.id));
    return result;
  }

  /// Returns units from the immediate cell neighborhood. Core radius queries
  /// use the same contiguous-cell walk with a radius-derived neighborhood.
  List<Unit> queryAdjacent(Vec2 position, {int cellRadius = 1}) {
    if (cellRadius < 0) {
      throw ArgumentError.value(cellRadius, 'cellRadius', 'must be >= 0');
    }
    final centerX = _cellX(position);
    final centerY = _cellY(position);
    final result = <Unit>[];
    totalQueries++;
    for (var y = centerY - cellRadius; y <= centerY + cellRadius; y++) {
      for (var x = centerX - cellRadius; x <= centerX + cellRadius; x++) {
        totalCellsVisited++;
        final bucket = _cells[_cellKey(x, y)];
        if (bucket == null) continue;
        for (final factionUnits in bucket.byFaction) {
          for (final unit in factionUnits) {
            totalCandidateVisits++;
            if (unit.alive) result.add(unit);
          }
        }
      }
    }
    result.sort((a, b) => a.id.compareTo(b.id));
    return result;
  }

  /// Allocation-free nearest-enemy query used by the per-frame core loop.
  Unit? nearestEnemy(
    Unit source, {
    required double radius,
    bool combatReadyOnly = false,
  }) {
    if (radius < 0) {
      throw ArgumentError.value(radius, 'radius', 'must be >= 0');
    }
    Unit? nearest;
    var nearestDistanceSquared = double.infinity;
    final minX = ((source.position.x - radius) / cellSize).floor();
    final maxX = ((source.position.x + radius) / cellSize).floor();
    final minY = ((source.position.y - radius) / cellSize).floor();
    final maxY = ((source.position.y + radius) / cellSize).floor();
    final radiusSquared = radius * radius;
    totalQueries++;

    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        totalCellsVisited++;
        final bucket = _cells[_cellKey(x, y)];
        if (bucket == null) continue;
        for (
          var factionIndex = 0;
          factionIndex < Faction.values.length;
          factionIndex++
        ) {
          if (factionIndex == source.faction.index) continue;
          for (final candidate in bucket.byFaction[factionIndex]) {
            totalCandidateVisits++;
            if (!candidate.alive ||
                (combatReadyOnly &&
                    (candidate.isCombatLocked || candidate.isRecovering))) {
              continue;
            }
            final distanceSquared = source.position.distanceSquaredTo(
              candidate.position,
            );
            if (distanceSquared > radiusSquared) continue;
            if (distanceSquared < nearestDistanceSquared ||
                (distanceSquared == nearestDistanceSquared &&
                    candidate.id < (nearest?.id ?? 0x7fffffff))) {
              nearest = candidate;
              nearestDistanceSquared = distanceSquared;
            }
          }
        }
      }
    }
    return nearest;
  }

  /// Allocation-free same-faction separation vector for steering.
  Vec2 separationVector(Unit source, {required double radius}) {
    if (radius <= 0) return Vec2.zero;
    final minX = ((source.position.x - radius) / cellSize).floor();
    final maxX = ((source.position.x + radius) / cellSize).floor();
    final minY = ((source.position.y - radius) / cellSize).floor();
    final maxY = ((source.position.y + radius) / cellSize).floor();
    final radiusSquared = radius * radius;
    var separationX = 0.0;
    var separationY = 0.0;
    totalQueries++;

    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        totalCellsVisited++;
        final bucket = _cells[_cellKey(x, y)];
        if (bucket == null) continue;
        for (final neighbor in bucket.byFaction[source.faction.index]) {
          totalCandidateVisits++;
          if (!neighbor.alive || neighbor.id == source.id) {
            continue;
          }
          final dx = source.position.x - neighbor.position.x;
          final dy = source.position.y - neighbor.position.y;
          final distanceSquared = dx * dx + dy * dy;
          if (distanceSquared > radiusSquared) continue;
          if (distanceSquared <= 1e-9) {
            final direction = source.id < neighbor.id ? -1.0 : 1.0;
            separationX += direction;
            separationY -= direction;
          } else {
            separationX += dx / distanceSquared;
            separationY += dy / distanceSquared;
          }
        }
      }
    }
    return Vec2(separationX, separationY);
  }
}

class CombatEvent {
  const CombatEvent({
    required this.timestamp,
    required this.winnerId,
    required this.loserId,
    required this.winnerFaction,
    required this.loserFaction,
    required this.winnerLevel,
    required this.loserLevel,
    required this.position,
    required this.tiedLevels,
  });

  final double timestamp;
  final int winnerId;
  final int loserId;
  final Faction winnerFaction;
  final Faction loserFaction;
  final int winnerLevel;
  final int loserLevel;
  final Vec2 position;
  final bool tiedLevels;

  int get attackerId => winnerId;
  int get attackerLevel => winnerLevel;

  String get replayKey =>
      '${timestamp.toStringAsFixed(4)}:$winnerId>$loserId:'
      '$winnerLevel>$loserLevel';

  Map<String, Object> toDebugMap() => <String, Object>{
    'timestamp': timestamp,
    'winnerId': winnerId,
    'loserId': loserId,
    'winnerFaction': winnerFaction.name,
    'loserFaction': loserFaction.name,
    'winnerLevel': winnerLevel,
    'loserLevel': loserLevel,
    'tiedLevels': tiedLevels,
    'position': <String, double>{'x': position.x, 'y': position.y},
  };
}

class CombatResolver {
  CombatResolver(
    this.random, {
    this.combatLockDuration = 0.42,
    this.recoverDuration = 0.42,
  });

  final SeededRandom random;
  final double combatLockDuration;
  final double recoverDuration;

  /// Returns 0 when the first level wins and 1 when the second level wins.
  int winnerIndex(int firstLevel, int secondLevel) {
    if (firstLevel == secondLevel) return random.nextBool() ? 0 : 1;
    return firstLevel > secondLevel ? 0 : 1;
  }

  bool canEngage(Unit unit) =>
      unit.alive && !unit.isCombatLocked && !unit.isRecovering;

  /// Resolves and applies one atomic duel. Returning null means one unit was
  /// invalid or already locked by another duel in this simulation frame.
  CombatEvent? resolve(Unit first, Unit second, {required double timestamp}) {
    if (first.id == second.id ||
        first.faction == second.faction ||
        !canEngage(first) ||
        !canEngage(second)) {
      return null;
    }

    final tiedLevels = first.level == second.level;
    final firstWins = winnerIndex(first.level, second.level) == 0;
    final winner = firstWins ? first : second;
    final loser = firstWins ? second : first;

    // Apply all duel mutations together. The winner's lock prevents it from
    // being resolved again by a later nearby-unit iteration this frame.
    winner.kills += 1;
    winner.state = AiState.recover;
    winner.velocity = Vec2.zero;
    winner.targetId = null;
    winner.combatLockRemaining = combatLockDuration;
    winner.recoverRemaining = recoverDuration;

    loser.alive = false;
    loser.state = AiState.dead;
    loser.velocity = Vec2.zero;
    loser.targetId = null;
    loser.combatLockRemaining = 0;
    loser.recoverRemaining = 0;

    return CombatEvent(
      timestamp: timestamp,
      winnerId: winner.id,
      loserId: loser.id,
      winnerFaction: winner.faction,
      loserFaction: loser.faction,
      winnerLevel: winner.level,
      loserLevel: loser.level,
      position: (winner.position + loser.position) * 0.5,
      tiedLevels: tiedLevels,
    );
  }
}

class HandoffCandidateScore {
  const HandoffCandidateScore({
    required this.unit,
    required this.levelScore,
    required this.safetyScore,
    required this.nonCombatScore,
  });

  final Unit unit;
  final double levelScore;
  final double safetyScore;
  final double nonCombatScore;

  /// Product requirement weights: level 50%, safety 30%, non-combat 20%.
  double get total =>
      levelScore * 0.5 + safetyScore * 0.3 + nonCombatScore * 0.2;
}

class HandoffEvent {
  const HandoffEvent({
    required this.timestamp,
    required this.faction,
    required this.fromUnitId,
    required this.toUnitId,
    required this.score,
  });

  final double timestamp;
  final Faction faction;
  final int fromUnitId;
  final int? toUnitId;
  final double? score;

  bool get factionEliminated => toUnitId == null;
}

class FactionStanding {
  const FactionStanding({
    required this.faction,
    required this.survivors,
    required this.levelSum,
    required this.kills,
  });

  final Faction faction;
  final int survivors;
  final int levelSum;
  final int kills;

  /// Positive means this standing outranks [other].
  int compareScore(FactionStanding other) {
    var comparison = survivors.compareTo(other.survivors);
    if (comparison != 0) return comparison;
    comparison = levelSum.compareTo(other.levelSum);
    if (comparison != 0) return comparison;
    return kills.compareTo(other.kills);
  }
}

enum MatchEndReason { ongoing, elimination, timeLimit }

class MatchResult {
  const MatchResult({
    required this.reason,
    required this.winner,
    required this.standings,
    this.tiedFactions = const [],
  });

  final MatchEndReason reason;
  final Faction? winner;
  final List<FactionStanding> standings;
  final List<Faction> tiedFactions;

  bool get isFinished => reason != MatchEndReason.ongoing;
  bool get isDraw => isFinished && winner == null;
}

class AIController {
  AIController(this.config, this.random);

  final BattleConfig config;
  final SeededRandom random;

  void update(Unit unit, BattleSimulation simulation) {
    if (!unit.alive) {
      unit.state = AiState.dead;
      unit.velocity = Vec2.zero;
      return;
    }

    if (unit.recoverRemaining > 0 || unit.combatLockRemaining > 0) {
      unit.state = AiState.recover;
      unit.velocity = Vec2.zero;
      return;
    }
    if (unit.state == AiState.recover) {
      unit.state = AiState.seek;
      unit.aiDecisionRemaining = 0;
    }

    if (unit.aiDecisionRemaining > 1e-9) return;
    final throttled = simulation.shouldThrottleAi(unit);
    unit.aiDecisionCount += 1;
    if (throttled) {
      unit.throttledAiDecisionCount += 1;
      unit.aiDecisionRemaining =
          config.farAiDecisionInterval * (0.9 + random.nextDouble() * 0.2);
    } else {
      unit.normalAiDecisionCount += 1;
      unit.aiDecisionRemaining =
          (config.aiDecisionInterval * (0.85 + random.nextDouble() * 0.3))
              .clamp(1 / 15, 1 / 10)
              .toDouble();
    }

    switch (unit.state) {
      case AiState.spawn:
        unit.state = AiState.seek;
        _seek(unit, simulation);
      case AiState.seek:
        _seek(unit, simulation);
      case AiState.chase:
        _chase(unit, simulation);
      case AiState.engage:
        _engage(unit, simulation);
      case AiState.flee:
        _flee(unit, simulation);
      case AiState.recover:
        unit.velocity = Vec2.zero;
      case AiState.dead:
        unit.velocity = Vec2.zero;
    }
  }

  void _seek(Unit unit, BattleSimulation simulation) {
    final target = simulation.grid.nearestEnemy(
      unit,
      radius: config.visionRange,
    );
    if (target == null) {
      unit.targetId = null;
      unit.state = AiState.seek;
      _moveToward(unit, simulation.rallyPointFor(unit.faction));
      return;
    }
    unit.targetId = target.id;
    if (_shouldFlee(unit, target)) {
      unit.state = AiState.flee;
      _moveAway(unit, target.position);
      return;
    }
    unit.state = AiState.chase;
    _chase(unit, simulation, evaluateFlee: false);
  }

  void _chase(
    Unit unit,
    BattleSimulation simulation, {
    bool evaluateFlee = true,
  }) {
    final target = simulation.unitById(unit.targetId);
    if (target == null || !target.alive || target.faction == unit.faction) {
      unit.state = AiState.seek;
      unit.targetId = null;
      _seek(unit, simulation);
      return;
    }
    if (evaluateFlee && _shouldFlee(unit, target)) {
      unit.state = AiState.flee;
      _moveAway(unit, target.position);
      return;
    }
    if (unit.position.distanceSquaredTo(target.position) <=
        config.combatRange * config.combatRange) {
      unit.state = AiState.engage;
      unit.velocity = Vec2.zero;
      return;
    }
    unit.state = AiState.chase;
    _moveToward(unit, target.position);
  }

  void _engage(Unit unit, BattleSimulation simulation) {
    final target = simulation.unitById(unit.targetId);
    if (target == null || !target.alive || target.faction == unit.faction) {
      unit.state = AiState.seek;
      unit.targetId = null;
      _seek(unit, simulation);
      return;
    }
    final leash = config.combatRange * 1.25;
    if (unit.position.distanceSquaredTo(target.position) > leash * leash) {
      unit.state = AiState.chase;
      _moveToward(unit, target.position);
      return;
    }
    unit.velocity = Vec2.zero;
  }

  void _flee(Unit unit, BattleSimulation simulation) {
    final threat = simulation.unitById(unit.targetId);
    if (threat == null ||
        !threat.alive ||
        threat.faction == unit.faction ||
        threat.level <= unit.level ||
        unit.position.distanceSquaredTo(threat.position) >
            config.fleeDistance * config.fleeDistance) {
      unit.state = AiState.seek;
      unit.targetId = null;
      _seek(unit, simulation);
      return;
    }
    _moveAway(unit, threat.position);
  }

  bool _shouldFlee(Unit unit, Unit target) =>
      unit.level <= config.lowLevelThreshold &&
      target.level > unit.level &&
      random.nextDouble() < config.lowLevelFleeChance;

  void _moveToward(Unit unit, Vec2 destination) {
    unit.velocity =
        (destination - unit.position).normalized() * config.moveSpeed;
  }

  void _moveAway(Unit unit, Vec2 threat) {
    var direction = (unit.position - threat).normalized();
    if (direction == Vec2.zero) {
      direction = Vec2(
        random.nextSignedDouble(),
        random.nextSignedDouble(),
      ).normalized();
    }
    unit.velocity = direction * config.moveSpeed;
  }
}

class BattleSimulation {
  BattleSimulation({
    this.seed = 1,
    this.config = const BattleConfig(),
    this.playerFaction,
    bool autoSpawn = true,
  }) : matchLimit = config.matchLimitSeconds,
       random = SeededRandom(seed),
       grid = SpatialGrid(cellSize: config.gridCellSize),
       resolver = CombatResolver(
         SeededRandom(seed ^ 0xa341316c),
         combatLockDuration: config.combatLockDuration,
         recoverDuration: config.recoverDuration,
       ),
       aiController = AIController(config, SeededRandom(seed ^ 0xc8013ea4)) {
    if (autoSpawn) spawnArmies();
  }

  final int seed;
  final BattleConfig config;
  final SeededRandom random;
  final SpatialGrid grid;
  final CombatResolver resolver;
  final AIController aiController;
  final double matchLimit;

  /// Fixed per-match unit pool. All 4,000 [Unit] objects are allocated during
  /// [spawnArmies], dead entries stay in this list, and simulation frames only
  /// mutate existing objects rather than adding or removing units.
  final List<Unit> units = [];
  final List<CombatEvent> combatLog = [];
  final List<CombatEvent> frameCombatEvents = [];
  final List<HandoffEvent> handoffLog = [];

  double matchElapsed = 0;
  int simulationTickCount = 0;
  bool finished = false;
  MatchResult? result;
  Faction? playerFaction;
  int? controlledUnitId;
  double? playerEliminatedAt;

  Vec2 _playerMove = Vec2.zero;
  bool _playerDash = false;
  double _simulationAccumulator = 0;
  List<Vec2> _nextPositions = <Vec2>[];
  final Map<int, Unit> _unitsById = {};
  final List<int> _survivorScratch = List<int>.filled(Faction.values.length, 0);

  Faction? get winner => result?.winner;
  Unit? get controlledUnit => unitById(controlledUnitId);
  double get remainingTime => math.max(0, matchLimit - matchElapsed);
  double get fixedStepSeconds => config.simulationStepSeconds;
  double get interpolationAlpha =>
      (_simulationAccumulator / fixedStepSeconds).clamp(0, 1).toDouble();
  int get totalAiDecisions {
    var count = 0;
    for (final unit in units) {
      count += unit.aiDecisionCount;
    }
    return count;
  }

  int get debugNormalAiDecisionCount {
    var count = 0;
    for (final unit in units) {
      count += unit.normalAiDecisionCount;
    }
    return count;
  }

  int get debugThrottledAiDecisionCount {
    var count = 0;
    for (final unit in units) {
      count += unit.throttledAiDecisionCount;
    }
    return count;
  }

  /// Only idle, targetless Seek units far from the live player command are
  /// eligible for low-frequency decisions. Tactical states remain at the
  /// normal 10-15Hz cadence. The extra guard radius also switches an idle unit
  /// back to normal cadence before an enemy can enter its vision range.
  bool shouldThrottleAi(Unit unit) {
    final controlled = controlledUnit;
    if (controlled == null ||
        !controlled.alive ||
        controlled.id == unit.id ||
        unit.state != AiState.seek ||
        unit.targetId != null) {
      return false;
    }
    if (unit.position.distanceSquaredTo(controlled.position) <=
        config.farAiDistance * config.farAiDistance) {
      return false;
    }

    final maximumRelativeTravel =
        config.moveSpeed *
        (config.dashMultiplier + 1) *
        (config.farAiDecisionInterval * 1.1 + config.simulationStepSeconds);
    final tacticalGuardRadius = config.visionRange + maximumRelativeTravel;
    return grid.nearestEnemy(unit, radius: tacticalGuardRadius) == null;
  }

  bool get playerFactionEliminated {
    final selectedFaction = playerFaction;
    if (selectedFaction == null) return false;
    for (final unit in units) {
      if (unit.alive && unit.faction == selectedFaction) return false;
    }
    return true;
  }

  /// Player elimination does not end the global simulation; the UI can keep
  /// rendering and follow another army while [isSpectating] is true.
  bool get isSpectating => playerFactionEliminated && !finished;

  void spawnArmies() {
    random.reset(seed);
    resolver.random.reset(seed ^ 0xa341316c);
    aiController.random.reset(seed ^ 0xc8013ea4);
    units.clear();
    _unitsById.clear();
    combatLog.clear();
    frameCombatEvents.clear();
    handoffLog.clear();
    matchElapsed = 0;
    simulationTickCount = 0;
    _simulationAccumulator = 0;
    finished = false;
    result = null;
    playerEliminatedAt = null;

    var nextId = 0;
    for (final faction in Faction.values) {
      final levels = _balancedLevels();
      random.shuffle(levels);
      final zone = _spawnZoneFor(faction);
      final columns = math.max(
        1,
        math.sqrt(config.unitsPerFaction * 1.6).ceil(),
      );
      final rows = math.max(1, (config.unitsPerFaction / columns).ceil());
      final columnStep = columns <= 1
          ? 0.0
          : (zone.maxX - zone.minX) / (columns - 1);
      final rowStep = rows <= 1 ? 0.0 : (zone.maxY - zone.minY) / (rows - 1);
      final jitterLimit = math.min(
        columnStep == 0 ? double.infinity : columnStep,
        rowStep == 0 ? double.infinity : rowStep,
      );
      final safeJitter = jitterLimit.isFinite ? jitterLimit * .08 : 0.0;
      for (var index = 0; index < config.unitsPerFaction; index++) {
        final column = index % columns;
        final row = index ~/ columns;
        final base = Vec2(
          columns <= 1
              ? (zone.minX + zone.maxX) / 2
              : zone.minX + column * columnStep,
          rows <= 1 ? (zone.minY + zone.maxY) / 2 : zone.minY + row * rowStep,
        );
        final jitter = Vec2(
          random.nextSignedDouble() * safeJitter,
          random.nextSignedDouble() * safeJitter,
        );
        final unit = Unit(
          id: nextId++,
          faction: faction,
          level: levels[index],
          position: (base + jitter).clamp(
            minX: zone.minX,
            maxX: zone.maxX,
            minY: zone.minY,
            maxY: zone.maxY,
          ),
        );
        units.add(unit);
        _unitsById[unit.id] = unit;
      }
    }
    _nextPositions = List<Vec2>.filled(units.length, Vec2.zero);
    grid.resetMetrics();
    grid.rebuild(units);

    if (playerFaction != null) {
      controlledUnitId = units
          .where((unit) => unit.faction == playerFaction)
          .reduce((a, b) => a.level > b.level ? a : b)
          .id;
    } else {
      controlledUnitId = null;
    }
  }

  List<int> _balancedLevels() {
    final levelCount = config.maxLevel - config.minLevel + 1;
    return List<int>.generate(
      config.unitsPerFaction,
      (index) => config.minLevel + (index % levelCount),
      growable: false,
    );
  }

  ({double minX, double maxX, double minY, double maxY}) _spawnZoneFor(
    Faction faction,
  ) {
    final left = faction == Faction.claude || faction == Faction.grok;
    final top = faction == Faction.claude || faction == Faction.codex;
    return (
      minX: config.worldWidth * (left ? 120 / 3600 : 2400 / 3600),
      maxX: config.worldWidth * (left ? 1200 / 3600 : 3480 / 3600),
      minY: config.worldHeight * (top ? 120 / 2400 : 1600 / 2400),
      maxY: config.worldHeight * (top ? 800 / 2400 : 2280 / 2400),
    );
  }

  Vec2 rallyPointFor(Faction faction) {
    final center = Vec2(config.worldWidth * 0.5, config.worldHeight * 0.5);
    const offset = 72.0;
    return switch (faction) {
      Faction.claude => center + const Vec2(-offset, -offset),
      Faction.codex => center + const Vec2(offset, -offset),
      Faction.grok => center + const Vec2(-offset, offset),
      Faction.gemini => center + const Vec2(offset, offset),
    };
  }

  Unit? unitById(int? id) => id == null ? null : _unitsById[id];

  List<Unit> aliveUnits([Faction? faction]) => units
      .where(
        (unit) => unit.alive && (faction == null || unit.faction == faction),
      )
      .toList(growable: false);

  void rebuildSpatialGrid() => grid.rebuild(units);

  void setPlayerInput(Vec2 direction, {bool dash = false}) {
    _playerMove = direction.lengthSquared > 1
        ? direction.normalized()
        : direction;
    _playerDash = dash;
  }

  void setControlledUnit(int? unitId, {Faction? faction}) {
    if (unitId == null) {
      controlledUnitId = null;
      if (faction != null) playerFaction = faction;
      return;
    }
    final unit = unitById(unitId);
    if (unit == null || !unit.alive) {
      throw ArgumentError.value(unitId, 'unitId', 'must identify a live unit');
    }
    if (faction != null && unit.faction != faction) {
      throw ArgumentError('Controlled unit does not belong to $faction');
    }
    playerFaction = faction ?? unit.faction;
    controlledUnitId = unitId;
  }

  void step(double deltaSeconds) {
    if (deltaSeconds < 0 || !deltaSeconds.isFinite) {
      throw ArgumentError.value(
        deltaSeconds,
        'deltaSeconds',
        'must be finite and >= 0',
      );
    }
    frameCombatEvents.clear();
    if (finished || deltaSeconds == 0) return;

    // Rendering may call this at 60/120Hz. Simulation, combat, and movement
    // advance only in deterministic 30Hz ticks.
    _simulationAccumulator += deltaSeconds;
    while (_simulationAccumulator + 1e-12 >= fixedStepSeconds && !finished) {
      _simulationAccumulator -= fixedStepSeconds;
      if (_simulationAccumulator < 0) _simulationAccumulator = 0;
      _simulateTick(fixedStepSeconds);
    }
    if (finished) _simulationAccumulator = 0;
  }

  void _simulateTick(double requestedDt) {
    final remaining = math.max(0.0, matchLimit - matchElapsed);
    final dt = math.min(requestedDt, remaining);
    if (dt <= 0) {
      _finishAtTimeLimit();
      return;
    }
    simulationTickCount += 1;
    matchElapsed += dt;

    for (final unit in units) {
      if (!unit.alive) continue;
      unit.combatLockRemaining = math.max(0.0, unit.combatLockRemaining - dt);
      unit.recoverRemaining = math.max(0.0, unit.recoverRemaining - dt);
      unit.aiDecisionRemaining = math.max(0.0, unit.aiDecisionRemaining - dt);
    }

    grid.rebuild(units);
    final controlled = controlledUnit;
    for (final unit in units) {
      if (!unit.alive) continue;
      if (controlled != null && unit.id == controlled.id) {
        _updateControlledUnit(unit);
      } else {
        aiController.update(unit, this);
      }
    }

    _moveUnits(dt);
    grid.rebuild(units);
    _resolveNearbyCombats();
    _handoffIfNeeded();
    _finishIfNeeded();
  }

  void _updateControlledUnit(Unit unit) {
    if (unit.recoverRemaining > 0 || unit.combatLockRemaining > 0) {
      unit.state = AiState.recover;
      unit.velocity = Vec2.zero;
      return;
    }
    final multiplier = _playerDash ? config.dashMultiplier : 1.0;
    unit.velocity = _playerMove * (config.moveSpeed * multiplier);
    if (unit.state == AiState.recover || unit.state == AiState.spawn) {
      unit.state = AiState.seek;
    }
  }

  void _moveUnits(double dt) {
    if (_nextPositions.length != units.length) {
      _nextPositions = List<Vec2>.filled(units.length, Vec2.zero);
    }
    for (var index = 0; index < units.length; index++) {
      final unit = units[index];
      if (!unit.alive) {
        _nextPositions[index] = unit.position;
        continue;
      }
      var velocity = unit.velocity;
      if (velocity.lengthSquared > 0 && config.separationStrength > 0) {
        final separation = grid.separationVector(
          unit,
          radius: config.separationRadius,
        );
        if (separation.lengthSquared > 0) {
          velocity =
              (velocity.normalized() +
                      separation.normalized() * config.separationStrength)
                  .normalized() *
              velocity.length;
        }
      }
      unit.velocity = velocity;
      _nextPositions[index] = (unit.position + velocity * dt).clamp(
        minX: config.unitRadius,
        maxX: config.worldWidth - config.unitRadius,
        minY: config.unitRadius,
        maxY: config.worldHeight - config.unitRadius,
      );
    }
    for (var index = 0; index < units.length; index++) {
      if (units[index].alive) units[index].position = _nextPositions[index];
    }
  }

  void _resolveNearbyCombats() {
    for (final unit in units) {
      if (!resolver.canEngage(unit)) continue;
      final target = grid.nearestEnemy(
        unit,
        radius: config.combatRange,
        combatReadyOnly: true,
      );
      if (target == null) continue;
      unit.state = AiState.engage;
      target.state = AiState.engage;
      final event = resolver.resolve(unit, target, timestamp: matchElapsed);
      if (event != null) {
        frameCombatEvents.add(event);
        combatLog.add(event);
      }
    }
  }

  HandoffCandidateScore scoreHandoffCandidate(Unit candidate) {
    if (!candidate.alive) {
      return HandoffCandidateScore(
        unit: candidate,
        levelScore: 0,
        safetyScore: 0,
        nonCombatScore: 0,
      );
    }
    final levelRange = math.max(1, config.maxLevel - config.minLevel);
    final levelScore = ((candidate.level - config.minLevel) / levelRange)
        .clamp(0, 1)
        .toDouble();
    final nearestEnemy = grid.nearestEnemy(
      candidate,
      radius: config.handoffSafetyRadius,
    );
    final safetyScore = nearestEnemy == null
        ? 1.0
        : (candidate.position.distanceTo(nearestEnemy.position) /
                  config.handoffSafetyRadius)
              .clamp(0, 1)
              .toDouble();
    final nonCombatScore = candidate.isEngaged ? 0.0 : 1.0;
    return HandoffCandidateScore(
      unit: candidate,
      levelScore: levelScore,
      safetyScore: safetyScore,
      nonCombatScore: nonCombatScore,
    );
  }

  Unit? selectHandoff({Faction? faction, int? fallenUnitId}) {
    faction ??= unitById(fallenUnitId)?.faction ?? playerFaction;
    if (faction == null) return null;
    grid.rebuild(units);

    HandoffCandidateScore? best;
    for (final candidate in units) {
      if (!candidate.alive ||
          candidate.faction != faction ||
          candidate.id == fallenUnitId) {
        continue;
      }
      final score = scoreHandoffCandidate(candidate);
      if (best == null ||
          score.total > best.total + 1e-12 ||
          ((score.total - best.total).abs() <= 1e-12 &&
              candidate.id < best.unit.id)) {
        best = score;
      }
    }
    return best?.unit;
  }

  void _handoffIfNeeded() {
    final previousId = controlledUnitId;
    if (previousId == null) return;
    final previous = unitById(previousId);
    if (previous == null || previous.alive) return;
    final successor = selectHandoff(
      faction: previous.faction,
      fallenUnitId: previous.id,
    );
    final score = successor == null ? null : scoreHandoffCandidate(successor);
    controlledUnitId = successor?.id;
    if (successor == null && previous.faction == playerFaction) {
      playerEliminatedAt ??= matchElapsed;
    }
    handoffLog.add(
      HandoffEvent(
        timestamp: matchElapsed,
        faction: previous.faction,
        fromUnitId: previous.id,
        toUnitId: successor?.id,
        score: score?.total,
      ),
    );
  }

  List<FactionStanding> standings() {
    final result = <FactionStanding>[];
    for (final faction in Faction.values) {
      var survivors = 0;
      var levelSum = 0;
      var kills = 0;
      for (final unit in units) {
        if (unit.faction != faction) continue;
        kills += unit.kills;
        if (unit.alive) {
          survivors += 1;
          levelSum += unit.level;
        }
      }
      result.add(
        FactionStanding(
          faction: faction,
          survivors: survivors,
          levelSum: levelSum,
          kills: kills,
        ),
      );
    }
    result.sort((a, b) {
      final score = b.compareScore(a);
      return score != 0 ? score : a.faction.index.compareTo(b.faction.index);
    });
    return List.unmodifiable(result);
  }

  MatchResult evaluateResult({bool forceTimeLimit = false}) {
    final currentStandings = standings();
    final active = currentStandings
        .where((standing) => standing.survivors > 0)
        .toList(growable: false);
    if (active.length == 1) {
      return MatchResult(
        reason: MatchEndReason.elimination,
        winner: active.single.faction,
        standings: currentStandings,
      );
    }
    if (active.isEmpty) {
      return MatchResult(
        reason: MatchEndReason.elimination,
        winner: null,
        standings: currentStandings,
        tiedFactions: Faction.values,
      );
    }
    if (!forceTimeLimit && matchElapsed + 1e-9 < matchLimit) {
      return MatchResult(
        reason: MatchEndReason.ongoing,
        winner: null,
        standings: currentStandings,
      );
    }

    final best = currentStandings.first;
    final tied = currentStandings
        .where((standing) => standing.compareScore(best) == 0)
        .map((standing) => standing.faction)
        .toList(growable: false);
    return MatchResult(
      reason: MatchEndReason.timeLimit,
      winner: tied.length == 1 ? best.faction : null,
      standings: currentStandings,
      tiedFactions: tied.length > 1 ? tied : const [],
    );
  }

  Faction? determineWinner({bool forceTimeLimit = false}) =>
      evaluateResult(forceTimeLimit: forceTimeLimit).winner;

  /// Dependency-free payload for debug replay audits and bug reports. The
  /// caller decides where to persist it; release builds need not expose it.
  Map<String, Object?> exportDebugCombatLog() => <String, Object?>{
    'schemaVersion': 1,
    'matchSeed': seed,
    'playerFaction': playerFaction?.name,
    'matchElapsed': matchElapsed,
    'simulationHz': config.simulationHz,
    'combatCount': combatLog.length,
    'randomState': <String, int>{
      'spawn': random.state,
      'combat': resolver.random.state,
      'ai': aiController.random.state,
    },
    'events': combatLog
        .map((event) => event.toDebugMap())
        .toList(growable: false),
  };

  String exportDebugCombatLogJson() => jsonEncode(exportDebugCombatLog());

  MatchResult finalizeAtTimeLimit() {
    result = evaluateResult(forceTimeLimit: true);
    finished = true;
    return result!;
  }

  void _finishIfNeeded() {
    _survivorScratch.fillRange(0, _survivorScratch.length, 0);
    for (final unit in units) {
      if (unit.alive) _survivorScratch[unit.faction.index] += 1;
    }
    var activeFactions = 0;
    for (final survivors in _survivorScratch) {
      if (survivors > 0) activeFactions++;
    }
    if (activeFactions <= 1 || matchElapsed + 1e-9 >= matchLimit) {
      result = evaluateResult();
      finished = true;
    }
  }

  void _finishAtTimeLimit() {
    result = evaluateResult(forceTimeLimit: true);
    finished = true;
  }
}
