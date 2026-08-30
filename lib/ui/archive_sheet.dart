import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../game/simulation.dart';
import '../l10n/l10n.dart';
import '../story/story_catalog.dart';
import '../story/story_localizations.dart';
import '../story/story_models.dart';
import 'living_relay_thread.dart';
import 'primitives.dart';

Future<void> showSignalArchive({
  required BuildContext context,
  required StoryProgress storyProgress,
  required ProfileRewardLedger rewardLedger,
  VoidCallback? onRestart,
  ValueChanged<StoryOperationId>? onReplay,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: TokenfrontColors.deepField,
  shape: const BeveledRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(TokenfrontRadii.control * 2),
    ),
  ),
  builder: (context) => _ArchiveSheet(
    storyProgress: storyProgress,
    rewardLedger: rewardLedger,
    onRestart: onRestart,
    onReplay: onReplay,
  ),
);

final class _ArchiveSheet extends StatelessWidget {
  const _ArchiveSheet({
    required this.storyProgress,
    required this.rewardLedger,
    this.onRestart,
    this.onReplay,
  });

  final StoryProgress storyProgress;
  final ProfileRewardLedger rewardLedger;
  final VoidCallback? onRestart;
  final ValueChanged<StoryOperationId>? onReplay;

  Future<void> _confirmRestart(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: TokenfrontColors.deepField,
        title: Text(l10n.restartChronicle),
        content: Text(l10n.restartDisclosure),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.restartChronicle),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      onRestart?.call();
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = StoryLocalizations(context.l10n);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TokenfrontSpacing.lg,
          TokenfrontSpacing.lg,
          TokenfrontSpacing.lg,
          TokenfrontSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    copy.archive,
                    style: TokenfrontType.display.copyWith(fontSize: 26),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: TokenfrontSpacing.xs),
            if (storyProgress.ending != null)
              Text(
                copy.archiveSimulation,
                style: TokenfrontType.instrument.copyWith(
                  color: TokenfrontColors.archiveAsh,
                  fontSize: 9,
                ),
              ),
            const SizedBox(height: TokenfrontSpacing.md),
            _ArchiveTimeline(
              progress: storyProgress,
              rewardLedger: rewardLedger,
              onReplay: onReplay,
            ),
            if (storyProgress.signalDoctrine != SignalDoctrine.undecided)
              _RoutingPattern(progress: storyProgress, copy: copy),
            if (storyProgress.ending case final ending?) ...[
              const SizedBox(height: TokenfrontSpacing.lg),
              TacticalPanel(
                borderColor: TokenfrontColors.volt.withValues(alpha: .7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(copy.endingHeading, style: TokenfrontType.instrument),
                    const SizedBox(height: TokenfrontSpacing.sm),
                    Text(
                      copy.endingEpilogue(ending),
                      style: TokenfrontType.body,
                    ),
                    const SizedBox(height: TokenfrontSpacing.md),
                    Text(
                      copy.archiveSimulation,
                      style: TokenfrontType.instrument.copyWith(
                        color: TokenfrontColors.volt,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: TokenfrontSpacing.lg),
            OutlinedButton.icon(
              onPressed: onRestart == null
                  ? null
                  : () => _confirmRestart(context),
              icon: const Icon(Icons.restart_alt, size: 18),
              label: Text(copy.restart),
              style: OutlinedButton.styleFrom(
                foregroundColor: TokenfrontColors.danger,
                minimumSize: const Size.fromHeight(
                  TokenfrontSpacing.xxl + TokenfrontSpacing.lg,
                ),
                side: BorderSide(
                  color: TokenfrontColors.danger.withValues(alpha: .65),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ArchiveTimeline extends StatelessWidget {
  const _ArchiveTimeline({
    required this.progress,
    required this.rewardLedger,
    required this.onReplay,
  });

  final StoryProgress progress;
  final ProfileRewardLedger rewardLedger;
  final ValueChanged<StoryOperationId>? onReplay;

  List<LivingRelayThreadNode> _nodes() => [
    for (final operation in StoryOperationId.values)
      LivingRelayThreadNode(
        identifier: 'OP-${(operation.index + 1).toString().padLeft(2, '0')}',
        state: progress.concludedOperations.contains(operation)
            ? LivingRelayThreadNodeState.confirmed
            : progress.currentOperation == operation
            ? LivingRelayThreadNodeState.current
            : LivingRelayThreadNodeState.locked,
      ),
  ];

  List<LivingRelayThreadSegment> _segments() => [
    for (var index = 0; index < LivingRelayThread.routeSegmentCount; index++)
      LivingRelayThreadSegment(
        state:
            progress.concludedOperations.contains(
              StoryOperationId.values[index],
            )
            ? progress.signalRoutes[StoryOperationId.values[index]] ==
                      RelayRoute.force
                  ? LivingRelayThreadNodeState.fault
                  : LivingRelayThreadNodeState.confirmed
            : progress.currentOperation == StoryOperationId.values[index]
            ? LivingRelayThreadNodeState.current
            : LivingRelayThreadNodeState.locked,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final copy = StoryLocalizations(context.l10n);
    return Semantics(
      key: const Key('archive-living-relay-thread'),
      container: true,
      label: '${copy.archive} // ${copy.livingRelayThread}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: TokenfrontSpacing.xl,
            child: LivingRelayThread(
              variant: LivingRelayThreadVariant.verticalArchive,
              nodes: _nodes(),
              segments: _segments(),
              progress: 0,
              animate: false,
              semanticLabel: null,
              height: TokenfrontSpacing.xxl * 5 + TokenfrontSpacing.lg,
            ),
          ),
          const SizedBox(width: TokenfrontSpacing.md),
          Expanded(
            child: Column(
              children: [
                for (final operation in StoryCatalog.operations)
                  _ArchiveRow(
                    operation: operation,
                    progress: progress,
                    rewardLedger: rewardLedger,
                    onReplay: onReplay,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({
    required this.operation,
    required this.progress,
    required this.rewardLedger,
    required this.onReplay,
  });

  final StoryOperation operation;
  final StoryProgress progress;
  final ProfileRewardLedger rewardLedger;
  final ValueChanged<StoryOperationId>? onReplay;

  @override
  Widget build(BuildContext context) {
    final copy = StoryLocalizations(context.l10n);
    final concluded = progress.concludedOperations.contains(operation.id);
    final current = progress.currentOperation == operation.id;
    final locked = !concluded && !current;
    if (locked) {
      return Padding(
        padding: const EdgeInsets.only(bottom: TokenfrontSpacing.sm),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            TokenfrontSpacing.md,
            TokenfrontSpacing.md,
            TokenfrontSpacing.sm,
            TokenfrontSpacing.md,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: TokenfrontColors.archiveAsh.withValues(alpha: .35),
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lock_outline,
                size: 18,
                color: TokenfrontColors.archiveAsh,
              ),
              const SizedBox(width: TokenfrontSpacing.md),
              Text(
                'OP-${(operation.id.index + 1).toString().padLeft(2, '0')}',
                style: TokenfrontType.instrument.copyWith(
                  color: TokenfrontColors.archiveAsh,
                  fontSize: 11,
                ),
              ),
              const SizedBox(
                width: TokenfrontSpacing.sm + TokenfrontSpacing.xs,
              ),
              Expanded(
                child: Text(
                  _lockedTeaser(operation, copy),
                  key: Key('locked-teaser-${operation.id.name}'),
                  style: TokenfrontType.body.copyWith(
                    color: TokenfrontColors.archiveAsh,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (current) {
      return Padding(
        padding: const EdgeInsets.only(bottom: TokenfrontSpacing.sm),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            TokenfrontSpacing.md,
            TokenfrontSpacing.md,
            TokenfrontSpacing.sm,
            TokenfrontSpacing.md,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: TokenfrontColors.threadCyan),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.operationTitle(operation.id),
                style: TokenfrontType.instrument.copyWith(
                  color: TokenfrontColors.relayIvory,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: TokenfrontSpacing.sm),
              Text(
                copy.currentOperation,
                style: TokenfrontType.instrument.copyWith(
                  color: TokenfrontColors.volt,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: TokenfrontSpacing.xs),
              Text(
                copy.incident(operation.id),
                key: Key('archive-incident-${operation.id.name}'),
                style: TokenfrontType.body.copyWith(
                  color: TokenfrontColors.relayIvory,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: TokenfrontSpacing.sm),
              Text(
                copy.directiveLabel(
                  operation.directive.kind,
                  target: operation.directive.target,
                ),
                style: TokenfrontType.body.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }
    final transmission = copy.transmission(operation.id);
    final medal = progress.medals.contains(operation.id)
        ? context.l10n.medalEarned
        : copy.directiveMissed;
    final bonusClaimed = rewardLedger.claimedDirectiveBonusIds.contains(
      operation.bonusClaimId,
    );
    final bonus = bonusClaimed
        ? copy.bonusClaimed
        : copy.directiveBonus(operation.oneTimeBonus);
    return Padding(
      padding: const EdgeInsets.only(bottom: TokenfrontSpacing.sm),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          TokenfrontSpacing.md,
          TokenfrontSpacing.md,
          TokenfrontSpacing.sm,
          TokenfrontSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: TokenfrontColors.archiveAsh.withValues(alpha: .35),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.operationTitle(operation.id),
                    style: TokenfrontType.instrument.copyWith(
                      color: TokenfrontColors.relayIvory,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: TokenfrontSpacing.sm),
                  Text(
                    transmission,
                    style: TokenfrontType.body.copyWith(
                      fontSize: 11,
                      color: null,
                    ),
                  ),
                  const SizedBox(height: TokenfrontSpacing.xs),
                  if (progress.signalRoutes[operation.id] case final route?)
                    Text(
                      copy.routeLabel(route),
                      key: Key('canonical-route-${operation.id.name}'),
                      style: TokenfrontType.instrument.copyWith(
                        color: TokenfrontColors.threadCyan,
                        fontSize: 10,
                      ),
                    ),
                  if (progress.signalRoutes[operation.id] != null)
                    const SizedBox(height: TokenfrontSpacing.xs),
                  Text(
                    '$medal  //  $bonus',
                    style: TokenfrontType.instrument.copyWith(
                      fontSize: 9,
                      color: TokenfrontColors.volt,
                    ),
                  ),
                ],
              ),
            ),
            if (concluded)
              TextButton(
                onPressed: onReplay == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        onReplay!(operation.id);
                      },
                child: Text(copy.retryDirective),
              ),
          ],
        ),
      ),
    );
  }
}

String _lockedTeaser(StoryOperation operation, StoryLocalizations copy) {
  final title = copy.operationTitle(operation.id);
  final marker = title.lastIndexOf('//');
  final teaser = marker == -1 ? title : title.substring(marker + 2).trim();
  return '$teaser?';
}

final class _RoutingPattern extends StatelessWidget {
  const _RoutingPattern({required this.progress, required this.copy});

  final StoryProgress progress;
  final StoryLocalizations copy;

  @override
  Widget build(BuildContext context) {
    final pattern = switch (progress.signalDoctrine) {
      SignalDoctrine.preserve => 'CONTINUITY',
      SignalDoctrine.force => 'PRESSURE',
      SignalDoctrine.balanced => 'ADAPTIVE',
      SignalDoctrine.undecided => '',
    };
    if (pattern.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(
        top: TokenfrontSpacing.xs,
        bottom: TokenfrontSpacing.sm,
      ),
      child: Text(
        copy.routingPattern(copy.patternLabel(pattern)),
        key: const Key('routing-pattern'),
        style: TokenfrontType.instrument.copyWith(
          color: TokenfrontColors.threadCyan,
          fontSize: 10,
        ),
      ),
    );
  }
}
