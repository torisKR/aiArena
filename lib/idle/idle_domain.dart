import 'dart:math' as math;

final class IdleState {
  const IdleState({
    required this.lastSettledAt,
    this.credits = 0,
    this.stage = 1,
    this.progress = 0,
    this.coreLevel = 1,
  });

  factory IdleState.initial(DateTime now) => IdleState(lastSettledAt: now);

  final DateTime lastSettledAt;
  final int credits;
  final int stage;
  final int progress;
  final int coreLevel;

  IdleState copyWith({
    DateTime? lastSettledAt,
    int? credits,
    int? stage,
    int? progress,
    int? coreLevel,
  }) => IdleState(
    lastSettledAt: lastSettledAt ?? this.lastSettledAt,
    credits: credits ?? this.credits,
    stage: stage ?? this.stage,
    progress: progress ?? this.progress,
    coreLevel: coreLevel ?? this.coreLevel,
  );

  Map<String, Object> toJson() => <String, Object>{
    'lastSettledAt': lastSettledAt.toUtc().toIso8601String(),
    'credits': credits,
    'stage': stage,
    'progress': progress,
    'coreLevel': coreLevel,
  };

  factory IdleState.fromJson(Map<String, dynamic> json) {
    final timestamp = DateTime.tryParse(json['lastSettledAt'] as String? ?? '');
    if (timestamp == null) throw const FormatException('idle timestamp');
    int nonNegative(String key, [int fallback = 0]) {
      final value = json[key];
      return value is int && value >= 0 ? value : fallback;
    }
    return IdleState(
      lastSettledAt: timestamp.toUtc(),
      credits: nonNegative('credits'),
      stage: math.max(1, nonNegative('stage', 1)),
      progress: nonNegative('progress'),
      coreLevel: math.max(1, nonNegative('coreLevel', 1)),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is IdleState &&
      other.lastSettledAt == lastSettledAt &&
      other.credits == credits &&
      other.stage == stage &&
      other.progress == progress &&
      other.coreLevel == coreLevel;

  @override
  int get hashCode => Object.hash(lastSettledAt, credits, stage, progress, coreLevel);
}

final class IdleSettlement {
  const IdleSettlement({required this.state, required this.elapsed, required this.creditsEarned});
  final IdleState state;
  final Duration elapsed;
  final int creditsEarned;
  int get credits => creditsEarned;
}

abstract final class IdleSimulation {
  static const offlineCap = Duration(hours: 8);
  // One stage is a 20-second level-1 loop; upgrade speed shortens it.
  static const stageGoal = 20;

  static int progressPerSecond(IdleState state) => state.coreLevel;
  // Provisional economy: level 1 yields 2.5 credits/s (integer settlement
  // floors half credits), while each core level doubles combat throughput.
  static int creditsPerSecond(IdleState state) => state.coreLevel * 5;

  static IdleSettlement settle(IdleState state, DateTime now) {
    final raw = now.toUtc().difference(state.lastSettledAt.toUtc());
    final elapsed = raw.isNegative
        ? Duration.zero
        : raw > offlineCap
        ? offlineCap
        : raw;
    final seconds = elapsed.inSeconds;
    final totalProgress = state.progress + seconds * progressPerSecond(state);
    final stagesCleared = totalProgress ~/ stageGoal;
    final nextProgress = totalProgress % stageGoal;
    final earned = seconds * creditsPerSecond(state) ~/ 2;
    return IdleSettlement(
      state: state.copyWith(
        lastSettledAt: state.lastSettledAt.add(elapsed),
        credits: state.credits + earned,
        stage: state.stage + stagesCleared,
        progress: nextProgress,
      ),
      elapsed: elapsed,
      creditsEarned: earned,
    );
  }

  // Provisional tuning: level 1 earns 5 credits/s, doubles combat progress per level;
  // level-n costs 50 * 2^(n-1), keeping the first upgrade within 10 seconds.
  static int upgradeCost(int level) => 50 * (1 << (level - 1));

  static IdleState? tryBuyUpgrade(IdleState state) {
    final cost = upgradeCost(state.coreLevel);
    if (state.credits < cost) return null;
    return state.copyWith(
      credits: state.credits - cost,
      coreLevel: state.coreLevel + 1,
    );
  }

  static IdleState buyUpgrade(IdleState state) => tryBuyUpgrade(state) ?? state;
}
