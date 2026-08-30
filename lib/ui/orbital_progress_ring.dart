import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../game/simulation.dart';
import '../l10n/l10n.dart';
import '../story/story_localizations.dart';
import '../story/story_models.dart';
import 'living_relay_thread.dart';

/// Compatibility wrapper for the original public widget name.
///
/// Chronicle now uses the shared horizontal Living Relay Thread primitive so
/// the deck, briefing, battle, and result surfaces share one visual contract.
class OrbitalProgressRing extends StatelessWidget {
  const OrbitalProgressRing({
    super.key,
    required this.progress,
    this.lowSpec = false,
    this.reduceMotion = false,
  });

  final StoryProgress progress;
  final bool lowSpec;
  final bool reduceMotion;

  String _semanticsLabel(BuildContext context) {
    final concluded = progress.concludedOperations.length;
    final current = progress.currentOperation;
    final currentText = current == null
        ? context.l10n.ending
        : StoryLocalizations(context.l10n).operationTitle(current);
    return context.l10n.orbitalProgressSemantics(
      context.l10n.commandDeck,
      concluded,
      currentText,
    );
  }

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
  Widget build(BuildContext context) => LivingRelayThread(
    key: const Key('living-relay-thread-horizontal'),
    variant: LivingRelayThreadVariant.horizontalProgress,
    nodes: _nodes(),
    segments: _segments(),
    progress: 0,
    semanticLabel: _semanticsLabel(context),
    reducedMotion: reduceMotion,
    lowSpec: lowSpec,
    animate: true,
    height: TokenfrontSpacing.xxl + TokenfrontSpacing.xl,
  );
}
