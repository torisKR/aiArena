enum HandoffAnalyticsOutcome { completed, skipped, abandoned }

enum AnalyticsAdFormat { banner, interstitial, rewarded }

/// Actions needed to derive impression, exit, opt-in, reward, and failure rates.
enum AnalyticsAdAction {
  eligible,
  impression,
  dismissed,
  resultExitAfterImpression,
  rewardOptIn,
  rewardEarned,
  failed,
}

/// Versioned, typed launch analytics event.
///
/// The private constructor prevents unreviewed event names and accidental PII
/// fields from spreading through the application.
final class AnalyticsEvent {
  AnalyticsEvent._(
    this.name,
    Map<String, Object?> parameters,
    DateTime? occurredAt,
  ) : schemaVersion = 1,
      parameters = Map<String, Object?>.unmodifiable(parameters),
      occurredAt = (occurredAt ?? DateTime.now()).toUtc();

  final String name;
  final int schemaVersion;
  final DateTime occurredAt;
  final Map<String, Object?> parameters;

  factory AnalyticsEvent.tutorialStarted({DateTime? occurredAt}) =>
      AnalyticsEvent._(
        'tutorial_started',
        const <String, Object?>{},
        occurredAt,
      );

  factory AnalyticsEvent.tutorialCompleted({DateTime? occurredAt}) =>
      AnalyticsEvent._(
        'tutorial_completed',
        const <String, Object?>{},
        occurredAt,
      );

  factory AnalyticsEvent.factionSelected({
    required String faction,
    DateTime? occurredAt,
  }) {
    _requireText(faction, 'faction');
    return AnalyticsEvent._('faction_selected', <String, Object?>{
      'faction': faction,
    }, occurredAt);
  }

  factory AnalyticsEvent.matchStarted({
    required String matchId,
    bool isFirstMatch = false,
    DateTime? occurredAt,
  }) {
    _requireText(matchId, 'matchId');
    return AnalyticsEvent._('match_started', <String, Object?>{
      'match_id': matchId,
      'is_first_match': isFirstMatch,
    }, occurredAt);
  }

  factory AnalyticsEvent.matchCompleted({
    required String matchId,
    required double durationSeconds,
    required bool isFirstMatch,
    required String selectedFaction,
    required String winningFaction,
    required int killCount,
    required int handoffCount,
    DateTime? occurredAt,
  }) {
    _requireText(matchId, 'matchId');
    _requireText(selectedFaction, 'selectedFaction');
    _requireText(winningFaction, 'winningFaction');
    _requireNonNegative(durationSeconds, 'durationSeconds');
    _requireNonNegative(killCount, 'killCount');
    _requireNonNegative(handoffCount, 'handoffCount');
    return AnalyticsEvent._('match_completed', <String, Object?>{
      'match_id': matchId,
      'duration_seconds': durationSeconds,
      'is_first_match': isFirstMatch,
      'selected_faction': selectedFaction,
      'winning_faction': winningFaction,
      'won': selectedFaction == winningFaction,
      'kill_count': killCount,
      'handoff_count': handoffCount,
    }, occurredAt);
  }

  factory AnalyticsEvent.sessionSummary({
    required int matchCount,
    DateTime? occurredAt,
  }) {
    _requireNonNegative(matchCount, 'matchCount');
    return AnalyticsEvent._('session_summary', <String, Object?>{
      'match_count': matchCount,
    }, occurredAt);
  }

  factory AnalyticsEvent.retentionCheckpoint({
    required int day,
    DateTime? occurredAt,
  }) {
    if (day != 1 && day != 7) {
      throw ArgumentError.value(day, 'day', 'must be 1 or 7');
    }
    return AnalyticsEvent._('retention_checkpoint', <String, Object?>{
      'day': day,
    }, occurredAt);
  }

  factory AnalyticsEvent.unitLifecycle({
    required int level,
    required double survivalSeconds,
    required int killContribution,
    DateTime? occurredAt,
  }) {
    if (level < 1 || level > 10) {
      throw ArgumentError.value(level, 'level', 'must be between 1 and 10');
    }
    _requireNonNegative(survivalSeconds, 'survivalSeconds');
    _requireNonNegative(killContribution, 'killContribution');
    return AnalyticsEvent._('unit_lifecycle', <String, Object?>{
      'level': level,
      'survival_seconds': survivalSeconds,
      'kill_contribution': killContribution,
    }, occurredAt);
  }

  factory AnalyticsEvent.handoffStarted({DateTime? occurredAt}) =>
      AnalyticsEvent._(
        'handoff_started',
        const <String, Object?>{},
        occurredAt,
      );

  factory AnalyticsEvent.handoffOutcome({
    required HandoffAnalyticsOutcome outcome,
    DateTime? occurredAt,
  }) => AnalyticsEvent._('handoff_outcome', <String, Object?>{
    'outcome': outcome.name,
  }, occurredAt);

  factory AnalyticsEvent.adEvent({
    required AnalyticsAdFormat format,
    required AnalyticsAdAction action,
    DateTime? occurredAt,
  }) => AnalyticsEvent._('ad_event', <String, Object?>{
    'format': format.name,
    'action': action.name,
  }, occurredAt);

  factory AnalyticsEvent.performanceSample({
    required String platform,
    required String deviceTier,
    required double averageFps,
    required double onePercentLowFps,
    DateTime? occurredAt,
  }) {
    _requireText(platform, 'platform');
    _requireText(deviceTier, 'deviceTier');
    _requireNonNegative(averageFps, 'averageFps');
    _requireNonNegative(onePercentLowFps, 'onePercentLowFps');
    return AnalyticsEvent._('performance_sample', <String, Object?>{
      'platform': platform,
      'device_tier': deviceTier,
      'average_fps': averageFps,
      'one_percent_low_fps': onePercentLowFps,
    }, occurredAt);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'schema_version': schemaVersion,
    'occurred_at': occurredAt.toIso8601String(),
    'parameters': parameters,
  };

  static void _requireText(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be empty');
    }
  }

  static void _requireNonNegative(num value, String name) {
    if (value < 0) {
      throw ArgumentError.value(value, name, 'must be non-negative');
    }
  }
}
