import '../game/faction_visuals.dart';
import '../l10n/app_localizations.dart';
import '../game/simulation.dart';
import 'story_models.dart';

/// Stable presentation mapping for the Signal Chronicle story.
///
/// Story identifiers remain English enum values and are deliberately mapped
/// with exhaustive switches. Localized arrays are avoided so a newly inserted
/// operation cannot silently display another operation's copy.
final class StoryLocalizations {
  const StoryLocalizations(this.l10n);

  final AppLocalizations l10n;

  String get prologue => l10n.chroniclePrologue;

  String operationTitle(StoryOperationId id) => switch (id) {
    StoryOperationId.wake => l10n.operationWakeTitle(operationNumber(id)),
    StoryOperationId.echo => l10n.operationEchoTitle(operationNumber(id)),
    StoryOperationId.split => l10n.operationSplitTitle(operationNumber(id)),
    StoryOperationId.crown => l10n.operationCrownTitle(operationNumber(id)),
    StoryOperationId.lastInstruction => l10n.operationLastInstructionTitle(
      operationNumber(id),
    ),
  };

  int operationNumber(StoryOperationId id) => switch (id) {
    StoryOperationId.wake => 1,
    StoryOperationId.echo => 2,
    StoryOperationId.split => 3,
    StoryOperationId.crown => 4,
    StoryOperationId.lastInstruction => 5,
  };

  String briefing(StoryOperationId id) => switch (id) {
    StoryOperationId.wake => l10n.operationWakeBriefing,
    StoryOperationId.echo => l10n.operationEchoBriefing,
    StoryOperationId.split => l10n.operationSplitBriefing,
    StoryOperationId.crown => l10n.operationCrownBriefing,
    StoryOperationId.lastInstruction => l10n.operationLastInstructionBriefing,
  };

  String transmission(StoryOperationId id) => switch (id) {
    StoryOperationId.wake => l10n.operationWakeTransmission,
    StoryOperationId.echo => l10n.operationEchoTransmission,
    StoryOperationId.split => l10n.operationSplitTransmission,
    StoryOperationId.crown => l10n.operationCrownTransmission,
    StoryOperationId.lastInstruction =>
      l10n.operationLastInstructionTransmission,
  };

  /// The operation's localized narrative reveal shown after its transmission.
  ///
  /// Keep this mapping exhaustive so each operation can only display its own
  /// reveal, even when operations are inserted or reordered in the catalog.
  String reveal(StoryOperationId id) => switch (id) {
    StoryOperationId.wake => l10n.operationWakeResponse,
    StoryOperationId.echo => l10n.operationEchoResponse,
    StoryOperationId.split => l10n.operationSplitResponse,
    StoryOperationId.crown => l10n.operationCrownResponse,
    StoryOperationId.lastInstruction => l10n.operationLastInstructionResponse,
  };

  /// Backwards-compatible name for callers that still refer to the reveal as
  /// a response.
  String response(StoryOperationId id) => reveal(id);

  /// The approved incident hook shown at the top of an operation briefing.
  String incident(StoryOperationId id) => switch (id) {
    StoryOperationId.wake => l10n.operationWakeIncident,
    StoryOperationId.echo => l10n.operationEchoIncident,
    StoryOperationId.split => l10n.operationSplitIncident,
    StoryOperationId.crown => l10n.operationCrownIncident,
    StoryOperationId.lastInstruction => l10n.operationLastIncident,
  };

  String routeLabel(RelayRoute route) => switch (route) {
    RelayRoute.preserve => l10n.routePreserve,
    RelayRoute.force => l10n.routeForce,
  };

  /// The operation-specific action copy for a Preserve/Force choice.
  String routeAction(StoryOperationId id, RelayRoute route) => switch ((
    id,
    route,
  )) {
    (StoryOperationId.wake, RelayRoute.preserve) => l10n.operationWakePreserve,
    (StoryOperationId.wake, RelayRoute.force) => l10n.operationWakeForce,
    (StoryOperationId.echo, RelayRoute.preserve) => l10n.operationEchoPreserve,
    (StoryOperationId.echo, RelayRoute.force) => l10n.operationEchoForce,
    (StoryOperationId.split, RelayRoute.preserve) =>
      l10n.operationSplitPreserve,
    (StoryOperationId.split, RelayRoute.force) => l10n.operationSplitForce,
    (StoryOperationId.crown, RelayRoute.preserve) =>
      l10n.operationCrownPreserve,
    (StoryOperationId.crown, RelayRoute.force) => l10n.operationCrownForce,
    (StoryOperationId.lastInstruction, RelayRoute.preserve) =>
      l10n.operationLastPreserve,
    (StoryOperationId.lastInstruction, RelayRoute.force) =>
      l10n.operationLastForce,
  };

  String routeEffect(RelayRoute route) => switch (route) {
    RelayRoute.preserve => l10n.routePreserveEffect,
    RelayRoute.force => l10n.routeForceEffect,
  };

  String coreVoice(Faction faction) => switch (faction) {
    Faction.amethyst => l10n.coreAmethystVoice,
    Faction.cobalt => l10n.coreCobaltVoice,
    Faction.volt => l10n.coreVoltVoice,
    Faction.prism => l10n.corePrismVoice,
  };

  String signalDoctrineLabel(SignalDoctrine doctrine) => switch (doctrine) {
    SignalDoctrine.undecided => l10n.signalDoctrineUndecided,
    SignalDoctrine.preserve => l10n.signalDoctrinePreserve,
    SignalDoctrine.force => l10n.signalDoctrineForce,
    SignalDoctrine.balanced => l10n.signalDoctrineBalanced,
  };

  /// Alias used by callers that treat doctrine copy as a localized value.
  String signalDoctrine(SignalDoctrine doctrine) =>
      signalDoctrineLabel(doctrine);

  String relayCharging(num current, num target) =>
      l10n.relayCharging(current, target);

  String get relayReady => l10n.relayReady;
  String get relayNoReceiver => l10n.relayNoReceiver;
  String get relayLinkResetWarning => l10n.relayLinkResetWarning;
  String get livingRelayThread => l10n.livingRelayThread;
  String get relayRouting => l10n.relayRouting;
  String get relayAction => l10n.relayAction;
  String get relayKeyboardHint => l10n.relayKeyboardHint;
  String manualRelaysSummary(int count) => l10n.manualRelaysSummary(count);
  String doctrineSummary(SignalDoctrine doctrine) =>
      l10n.doctrineSummary(signalDoctrineLabel(doctrine));
  String get signalFork => l10n.signalFork;
  String get routePreserve => l10n.routePreserve;
  String get routeForce => l10n.routeForce;
  String get routePreserveEffect => l10n.routePreserveEffect;
  String get routeForceEffect => l10n.routeForceEffect;
  String get storyRoleTitle => l10n.storyRoleTitle;
  String get storyRoleBody => l10n.storyRoleBody;
  String get fragmentRecovered => l10n.fragmentRecovered;
  String get simulationComplete => l10n.simulationComplete;
  String get battleDetails => l10n.battleDetails;

  String continueToOperation(StoryOperationId id) =>
      l10n.continueToOperation(operationNumber(id).toString().padLeft(2, '0'));

  String routingPattern(String pattern) => l10n.routingPattern(pattern);

  String patternLabel(String pattern) => switch (pattern) {
    'CONTINUITY' => l10n.patternContinuity,
    'PRESSURE' => l10n.patternPressure,
    'ADAPTIVE' => l10n.patternAdaptive,
    _ => pattern,
  };

  String directiveLabel(DirectiveKind kind, {num? target}) => switch (kind) {
    DirectiveKind.longestCommandLink => l10n.directiveLongestCommandLink(
      (target ?? 45).round(),
    ),
    DirectiveKind.commandRelays => l10n.directiveCommandRelays(
      (target ?? 2).round(),
    ),
    DirectiveKind.commandKills => l10n.directiveCommandKills(
      (target ?? 3).round(),
    ),
    DirectiveKind.finalRank => l10n.directiveFinalRank((target ?? 2).round()),
    DirectiveKind.victory => l10n.directiveVictory,
  };

  String directiveBonus(int amount) => l10n.directiveBonus(amount);

  String coreName(Faction faction) => faction.visual.name;

  String coreIdentity(Faction faction) => switch (faction) {
    Faction.amethyst => l10n.coreArchiveIdentity,
    Faction.cobalt => l10n.coreBastionIdentity,
    Faction.volt => l10n.coreSurgeIdentity,
    Faction.prism => l10n.coreMirrorIdentity,
  };

  String coreProtocol(Faction faction) => switch (faction) {
    Faction.amethyst => l10n.coreArchive,
    Faction.cobalt => l10n.coreBastion,
    Faction.volt => l10n.coreSurge,
    Faction.prism => l10n.coreMirror,
  };

  String coreResponse(String coreName) => l10n.coreResponse(coreName);

  String endingLabel(EndingChoice ending) => switch (ending) {
    EndingChoice.claimRelay => l10n.endingClaimRelay,
    EndingChoice.openRelay => l10n.endingOpenRelay,
  };

  String endingEpilogue(EndingChoice ending) => switch (ending) {
    EndingChoice.claimRelay => l10n.endingClaimEpilogue,
    EndingChoice.openRelay => l10n.endingOpenEpilogue,
  };

  String echoCycleChip(int cycle) => l10n.echoCycleChip(cycle);

  String echoBanner(EndingChoice ending) => switch (ending) {
    EndingChoice.claimRelay => l10n.echoBannerClaim,
    EndingChoice.openRelay => l10n.echoBannerOpen,
  };

  String? echoDoctrine(SignalDoctrine doctrine) => switch (doctrine) {
    SignalDoctrine.undecided => null,
    SignalDoctrine.preserve => l10n.echoDoctrinePreserve,
    SignalDoctrine.force => l10n.echoDoctrineForce,
    SignalDoctrine.balanced => l10n.echoDoctrineBalanced,
  };

  String get echoResidualHeading => l10n.echoResidualHeading;

  String echoBestClear(int seconds) => l10n.echoBestClear(seconds);

  String echoArchiveCaption(int cycle) => l10n.echoArchiveCaption(cycle);

  String get chronicle => l10n.chronicle;
  String get skirmish => l10n.skirmish;
  String get archive => l10n.archive;
  String get restart => l10n.restartChronicle;
  String get briefingHeading => l10n.briefing;
  String get directiveHeading => l10n.directive;
  String get debriefHeading => l10n.debrief;
  String get endingHeading => l10n.ending;
  String get directiveLocked => l10n.directiveLocked;
  String get directiveMissed => l10n.directiveMissed;
  String get bonusClaimed => l10n.bonusClaimed;
  String get archiveSimulation => l10n.archiveSimulation;
  String get transmissionRecovered => l10n.transmissionRecovered;
  String get retryDirective => l10n.retryDirective;
  String get continueCampaign => l10n.continueCampaign;
  String get commandDeck => l10n.commandDeck;
  String get currentOperation => l10n.currentOperation;
}
