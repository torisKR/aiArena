import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../l10n/l10n.dart';
import '../story/story_catalog.dart';
import '../story/story_localizations.dart';
import '../story/story_models.dart';
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
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
        content: const Text(
          'Campaign core, progress, transmissions, medals, and ending reset. '
          'Wallet, settings, and cosmetics remain. Paid operation bonuses '
          'cannot be earned again.',
        ),
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
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
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
            const SizedBox(height: 5),
            Text(
              'FIVE OPERATIONS // CANONICAL RECORD',
              style: TokenfrontType.instrument.copyWith(
                color: TokenfrontColors.quietText,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 14),
            for (final operation in StoryCatalog.operations)
              _ArchiveRow(
                operation: operation,
                progress: storyProgress,
                rewardLedger: rewardLedger,
                onReplay: onReplay,
              ),
            if (storyProgress.ending case final ending?) ...[
              const SizedBox(height: 16),
              TacticalPanel(
                borderColor: TokenfrontColors.volt.withValues(alpha: .7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(copy.endingHeading, style: TokenfrontType.instrument),
                    const SizedBox(height: 9),
                    Text(
                      copy.endingEpilogue(ending),
                      style: TokenfrontType.body,
                    ),
                    const SizedBox(height: 12),
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
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRestart == null
                  ? null
                  : () => _confirmRestart(context),
              icon: const Icon(Icons.restart_alt, size: 18),
              label: Text(copy.restart),
              style: OutlinedButton.styleFrom(
                foregroundColor: TokenfrontColors.danger,
                minimumSize: const Size.fromHeight(48),
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
    final transmission = concluded
        ? copy.transmission(operation.id)
        : 'TRANSMISSION LOCKED';
    final medal = concluded && progress.medals.contains(operation.id)
        ? 'MEDAL EARNED'
        : 'MEDAL —';
    final bonusClaimed = rewardLedger.claimedDirectiveBonusIds.contains(
      operation.bonusClaimId,
    );
    final bonus = bonusClaimed
        ? copy.bonusClaimed
        : concluded
        ? 'BONUS AVAILABLE'
        : 'BONUS LOCKED';
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: TacticalPanel(
        padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
        borderColor: current
            ? TokenfrontColors.relayIvory
            : TokenfrontColors.relayIvory.withValues(alpha: .22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locked
                        ? 'OP-${operation.id.index + 1}'.padLeft(5, '0')
                        : copy.operationTitle(operation.id),
                    style: TokenfrontType.instrument.copyWith(
                      color: locked
                          ? TokenfrontColors.quietText
                          : TokenfrontColors.relayIvory,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    transmission,
                    style: TokenfrontType.body.copyWith(
                      fontSize: 11,
                      color: locked ? TokenfrontColors.quietText : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$medal  //  $bonus',
                    style: TokenfrontType.instrument.copyWith(
                      fontSize: 9,
                      color: concluded
                          ? TokenfrontColors.volt
                          : TokenfrontColors.quietText,
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
