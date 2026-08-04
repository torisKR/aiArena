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
    StoryOperationId.wake => l10n.operationWakeTitle,
    StoryOperationId.echo => l10n.operationEchoTitle,
    StoryOperationId.split => l10n.operationSplitTitle,
    StoryOperationId.crown => l10n.operationCrownTitle,
    StoryOperationId.lastInstruction => l10n.operationLastInstructionTitle,
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

  String response(StoryOperationId id) => switch (id) {
    StoryOperationId.wake => l10n.operationWakeResponse,
    StoryOperationId.echo => l10n.operationEchoResponse,
    StoryOperationId.split => l10n.operationSplitResponse,
    StoryOperationId.crown => l10n.operationCrownResponse,
    StoryOperationId.lastInstruction => l10n.operationLastInstructionResponse,
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
}
