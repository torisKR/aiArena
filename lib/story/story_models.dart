import 'package:flutter/foundation.dart' show mapEquals, setEquals;
import 'package:tokenfront/game/simulation.dart';

enum GameMode { chronicle, skirmish }

enum StoryOperationId { wake, echo, split, crown, lastInstruction }

enum DirectiveKind {
  longestCommandLink,
  commandRelays,
  commandKills,
  finalRank,
  victory,
}

enum EndingChoice { claimRelay, openRelay }

enum ChronicleEndReason { timeLimit, globalResolution, playerEliminated }

/// The campaign-level doctrine implied by the routes selected across
/// concluded operations. This is descriptive only; it does not change combat
/// power or simulation outcomes.
enum SignalDoctrine { undecided, preserve, force, balanced }

final class Directive {
  const Directive({required this.kind, required this.target});

  final DirectiveKind kind;
  final double target;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Directive && kind == other.kind && target == other.target;

  @override
  int get hashCode => Object.hash(kind, target);
}

final class DirectiveProgress {
  const DirectiveProgress({
    required this.kind,
    required this.current,
    required this.target,
  });

  final DirectiveKind kind;
  final double current;
  final double target;

  bool get completed => switch (kind) {
    DirectiveKind.finalRank => current <= target,
    _ => current >= target,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DirectiveProgress &&
          kind == other.kind &&
          current == other.current &&
          target == other.target;

  @override
  int get hashCode => Object.hash(kind, current, target);
}

final class StoryOperation {
  const StoryOperation({
    required this.id,
    required this.seed,
    required this.duration,
    required this.directive,
    required this.oneTimeBonus,
  });

  final StoryOperationId id;
  final int seed;
  final Duration duration;
  final Directive directive;
  final int oneTimeBonus;

  String get bonusClaimId => 'chronicle-directive-${id.name}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryOperation &&
          id == other.id &&
          seed == other.seed &&
          duration == other.duration &&
          directive == other.directive &&
          oneTimeBonus == other.oneTimeBonus;

  @override
  int get hashCode => Object.hash(id, seed, duration, directive, oneTimeBonus);
}

final class BattleReport {
  BattleReport({
    required this.endReason,
    required List<FactionStanding> standingsAtConclusion,
    required this.globalWinner,
    required this.commandRelays,
    required this.commandKills,
    required this.longestCommandLinkSeconds,
    required this.playerRank,
    required this.playerSurvivors,
    this.manualRelays = 0,
    this.relayRoute,
  }) : standingsAtConclusion = List<FactionStanding>.unmodifiable(
         standingsAtConclusion,
       );

  final ChronicleEndReason endReason;
  final List<FactionStanding> standingsAtConclusion;
  final Faction? globalWinner;
  final int commandRelays;
  final int commandKills;
  final double longestCommandLinkSeconds;
  final int playerRank;
  final int playerSurvivors;
  final int manualRelays;
  final RelayRoute? relayRoute;

  /// Relays attributable to combat casualties rather than manual transfers.
  /// Persisted/legacy reports may contain inconsistent counts, so this value
  /// is deliberately clamped at zero.
  int get casualtyRelays {
    final value = commandRelays - manualRelays;
    return value < 0 ? 0 : value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BattleReport &&
          endReason == other.endReason &&
          _standingsEqual(standingsAtConclusion, other.standingsAtConclusion) &&
          globalWinner == other.globalWinner &&
          commandRelays == other.commandRelays &&
          commandKills == other.commandKills &&
          longestCommandLinkSeconds == other.longestCommandLinkSeconds &&
          playerRank == other.playerRank &&
          playerSurvivors == other.playerSurvivors &&
          manualRelays == other.manualRelays &&
          relayRoute == other.relayRoute;

  @override
  int get hashCode => Object.hash(
    endReason,
    Object.hashAll(standingsAtConclusion.map(_standingHash)),
    globalWinner,
    commandRelays,
    commandKills,
    longestCommandLinkSeconds,
    playerRank,
    playerSurvivors,
    manualRelays,
    relayRoute,
  );
}

bool _standingsEqual(List<FactionStanding> left, List<FactionStanding> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    final a = left[index];
    final b = right[index];
    if (a.faction != b.faction ||
        a.survivors != b.survivors ||
        a.levelSum != b.levelSum ||
        a.kills != b.kills) {
      return false;
    }
  }
  return true;
}

int _standingHash(FactionStanding standing) => Object.hash(
  standing.faction,
  standing.survivors,
  standing.levelSum,
  standing.kills,
);

final class StoryProgress {
  static const Object _unset = Object();

  StoryProgress({
    required this.campaignFaction,
    required Iterable<StoryOperationId> concludedOperations,
    required Iterable<StoryOperationId> medals,
    required Iterable<StoryOperationId> recoveredTransmissions,
    required this.ending,
    Map<StoryOperationId, RelayRoute> signalRoutes = const {},
  }) : concludedOperations = _orderedStoryIds(concludedOperations),
       medals = _orderedStoryIds(medals),
       recoveredTransmissions = _orderedStoryIds(recoveredTransmissions),
       signalRoutes = _orderedSignalRoutes(signalRoutes);

  factory StoryProgress.initial() => StoryProgress(
    campaignFaction: null,
    concludedOperations: const [],
    medals: const [],
    recoveredTransmissions: const [],
    ending: null,
    signalRoutes: const {},
  );

  factory StoryProgress.fromJson(Map<String, Object?> json) {
    final factionName = json['campaignFaction'];
    final endingName = json['ending'];
    final progress = StoryProgress(
      campaignFaction: factionName == null ? null : _decodeFaction(factionName),
      concludedOperations: _decodeStoryIds(json['concludedOperations']),
      medals: _decodeStoryIds(json['medals']),
      recoveredTransmissions: _decodeStoryIds(json['recoveredTransmissions']),
      ending: endingName == null ? null : _decodeEndingChoice(endingName),
      signalRoutes: _decodeSignalRoutes(json['signalRoutes']),
    );
    if (!progress.isSemanticallyValid) {
      throw const FormatException('story progress is semantically invalid');
    }
    return progress;
  }

  final Faction? campaignFaction;
  final Set<StoryOperationId> concludedOperations;
  final Set<StoryOperationId> medals;
  final Set<StoryOperationId> recoveredTransmissions;
  final EndingChoice? ending;
  final Map<StoryOperationId, RelayRoute> signalRoutes;

  SignalDoctrine get signalDoctrine {
    if (signalRoutes.isEmpty) return SignalDoctrine.undecided;
    var preserveCount = 0;
    var forceCount = 0;
    for (final route in signalRoutes.values) {
      switch (route) {
        case RelayRoute.preserve:
          preserveCount++;
        case RelayRoute.force:
          forceCount++;
      }
    }
    if (preserveCount == forceCount) return SignalDoctrine.balanced;
    return preserveCount > forceCount
        ? SignalDoctrine.preserve
        : SignalDoctrine.force;
  }

  /// Whether this progress can be produced by the sequential campaign rules.
  ///
  /// This is intentionally checked only when decoding persisted data. Runtime
  /// transitions remain responsible for enforcing their own preconditions.
  bool get isSemanticallyValid {
    if (!_isPrefix(concludedOperations)) return false;
    if (!concludedOperations.containsAll(medals)) return false;
    if (!setEquals(concludedOperations, recoveredTransmissions)) return false;
    if (!signalRoutes.keys.every(concludedOperations.contains)) return false;
    if (concludedOperations.isNotEmpty && campaignFaction == null) return false;
    if (ending == null) return true;
    return campaignFaction != null &&
        concludedOperations.length == StoryOperationId.values.length &&
        concludedOperations.containsAll(StoryOperationId.values);
  }

  StoryOperationId? get currentOperation {
    for (final operation in StoryOperationId.values) {
      if (!concludedOperations.contains(operation)) return operation;
    }
    return null;
  }

  StoryProgress lockCore(Faction faction) => StoryProgress(
    campaignFaction: campaignFaction ?? faction,
    concludedOperations: concludedOperations,
    medals: medals,
    recoveredTransmissions: recoveredTransmissions,
    ending: ending,
    signalRoutes: signalRoutes,
  );

  /// Returns a new progress value with only the supplied fields changed.
  ///
  /// [Object] parameters deliberately distinguish an omitted field from an
  /// explicit `null`, which lets callers clear the campaign faction or ending
  /// without exposing a mutable state path.
  StoryProgress copyWith({
    Object? campaignFaction = _unset,
    Object? concludedOperations = _unset,
    Object? medals = _unset,
    Object? recoveredTransmissions = _unset,
    Object? ending = _unset,
    Object? signalRoutes = _unset,
  }) => StoryProgress(
    campaignFaction: identical(campaignFaction, _unset)
        ? this.campaignFaction
        : campaignFaction as Faction?,
    concludedOperations: identical(concludedOperations, _unset)
        ? this.concludedOperations
        : concludedOperations as Iterable<StoryOperationId>,
    medals: identical(medals, _unset)
        ? this.medals
        : medals as Iterable<StoryOperationId>,
    recoveredTransmissions: identical(recoveredTransmissions, _unset)
        ? this.recoveredTransmissions
        : recoveredTransmissions as Iterable<StoryOperationId>,
    ending: identical(ending, _unset) ? this.ending : ending as EndingChoice?,
    signalRoutes: identical(signalRoutes, _unset)
        ? this.signalRoutes
        : signalRoutes as Map<StoryOperationId, RelayRoute>,
  );

  Map<String, Object?> toJson() => {
    'campaignFaction': campaignFaction?.name,
    'concludedOperations': concludedOperations
        .map((operation) => operation.name)
        .toList(),
    'medals': medals.map((operation) => operation.name).toList(),
    'recoveredTransmissions': recoveredTransmissions
        .map((operation) => operation.name)
        .toList(),
    'ending': ending?.name,
    'signalRoutes': {
      for (final entry in signalRoutes.entries)
        entry.key.name: entry.value.name,
    },
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryProgress &&
          campaignFaction == other.campaignFaction &&
          setEquals(concludedOperations, other.concludedOperations) &&
          setEquals(medals, other.medals) &&
          setEquals(recoveredTransmissions, other.recoveredTransmissions) &&
          ending == other.ending &&
          mapEquals(signalRoutes, other.signalRoutes);

  @override
  int get hashCode => Object.hash(
    campaignFaction,
    Object.hashAll(concludedOperations),
    Object.hashAll(medals),
    Object.hashAll(recoveredTransmissions),
    ending,
    Object.hashAll(
      signalRoutes.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );
}

final class ProfileRewardLedger {
  ProfileRewardLedger({required Iterable<String> claimedDirectiveBonusIds})
    : claimedDirectiveBonusIds = Set<String>.unmodifiable(
        claimedDirectiveBonusIds.toList()..sort(),
      );

  factory ProfileRewardLedger.empty() =>
      ProfileRewardLedger(claimedDirectiveBonusIds: const []);

  factory ProfileRewardLedger.fromJson(Map<String, Object?> json) {
    final values = json['claimedDirectiveBonusIds'];
    if (values == null) return ProfileRewardLedger.empty();
    if (values is! Iterable) {
      throw const FormatException('claimedDirectiveBonusIds must be a list');
    }
    return ProfileRewardLedger(claimedDirectiveBonusIds: values.cast<String>());
  }

  final Set<String> claimedDirectiveBonusIds;

  Map<String, Object?> toJson() => {
    'claimedDirectiveBonusIds': claimedDirectiveBonusIds.toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileRewardLedger &&
          setEquals(claimedDirectiveBonusIds, other.claimedDirectiveBonusIds);

  @override
  int get hashCode => Object.hashAll(claimedDirectiveBonusIds);
}

Set<StoryOperationId> _orderedStoryIds(Iterable<StoryOperationId> source) {
  final present = source.toSet();
  return Set<StoryOperationId>.unmodifiable(
    StoryOperationId.values.where(present.contains),
  );
}

bool _isPrefix(Set<StoryOperationId> operations) {
  var missingEarlierOperation = false;
  for (final operation in StoryOperationId.values) {
    if (operations.contains(operation)) {
      if (missingEarlierOperation) return false;
    } else {
      missingEarlierOperation = true;
    }
  }
  return true;
}

Iterable<StoryOperationId> _decodeStoryIds(Object? value) {
  if (value == null) return const [];
  if (value is! Iterable) {
    throw const FormatException('story operation IDs must be lists');
  }
  return value.map((item) {
    if (item is! String) {
      throw const FormatException('story operation IDs must be strings');
    }
    return _decodeStoryOperationId(item);
  });
}

Faction _decodeFaction(Object value) {
  if (value is! String) {
    throw const FormatException('campaign faction must be a name');
  }
  try {
    return Faction.values.byName(value);
  } on ArgumentError {
    throw FormatException('unknown campaign faction: $value');
  }
}

EndingChoice _decodeEndingChoice(Object value) {
  if (value is! String) {
    throw const FormatException('ending must be a name');
  }
  try {
    return EndingChoice.values.byName(value);
  } on ArgumentError {
    throw FormatException('unknown ending choice: $value');
  }
}

Map<StoryOperationId, RelayRoute> _orderedSignalRoutes(
  Map<StoryOperationId, RelayRoute> source,
) {
  final ordered = <StoryOperationId, RelayRoute>{};
  for (final operation in StoryOperationId.values) {
    final route = source[operation];
    if (route != null) ordered[operation] = route;
  }
  return Map<StoryOperationId, RelayRoute>.unmodifiable(ordered);
}

Map<StoryOperationId, RelayRoute> _decodeSignalRoutes(Object? value) {
  if (value == null) return const {};
  if (value is! Map) {
    throw const FormatException('signalRoutes must be a map');
  }
  final routes = <StoryOperationId, RelayRoute>{};
  for (final entry in value.entries) {
    if (entry.key is! String || entry.value is! String) {
      throw const FormatException('signalRoutes must map names to names');
    }
    final operation = _decodeStoryOperationId(entry.key as String);
    final route = _decodeRelayRoute(entry.value as String);
    routes[operation] = route;
  }
  return routes;
}

StoryOperationId _decodeStoryOperationId(String name) {
  try {
    return StoryOperationId.values.byName(name);
  } on ArgumentError {
    throw FormatException('unknown story operation ID: $name');
  }
}

RelayRoute _decodeRelayRoute(String name) {
  try {
    return RelayRoute.values.byName(name);
  } on ArgumentError {
    throw FormatException('unknown relay route: $name');
  }
}
