import 'package:flutter/material.dart';
import '../design/tokens.dart';
import '../game/faction_visuals.dart';
import '../game/simulation.dart';
import '../l10n/l10n.dart';
import '../story/story_localizations.dart';
import '../story/story_models.dart';
import 'living_relay_thread.dart';
import 'operation_briefing_parts.dart';
import 'primitives.dart';

/// Explicit pre-deployment decision for a Chronicle operation.
class OperationBriefingScreen extends StatelessWidget {
  const OperationBriefingScreen({
    super.key,
    required this.operation,
    required this.faction,
    required this.selectedRoute,
    required this.onSelectRoute,
    required this.onDeploy,
    required this.onBack,
  });

  final StoryOperation operation;
  final Faction faction;
  final RelayRoute? selectedRoute;
  final ValueChanged<RelayRoute> onSelectRoute;
  final VoidCallback onDeploy;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final compact = viewport.width < TokenfrontBreakpoints.compact;
    final copy = StoryLocalizations(context.l10n);
    final visual = faction.visual;
    final operationNumber = copy.operationNumber(operation.id);
    final directive = copy.directiveLabel(
      operation.directive.kind,
      target: operation.directive.target,
    );

    return Scaffold(
      body: TacticalBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              key: const Key('briefing-scroll'),
              padding: EdgeInsets.symmetric(
                horizontal: compact
                    ? TokenfrontSpacing.lg
                    : TokenfrontSpacing.xxl,
                vertical: compact
                    ? TokenfrontSpacing.lg
                    : TokenfrontSpacing.xxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            key: const Key('briefing-back'),
                            onPressed: onBack,
                            tooltip: context.l10n.commandDeck,
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const SizedBox(width: TokenfrontSpacing.sm),
                          Text(
                            context.l10n.briefing,
                            style: TokenfrontType.instrument.copyWith(
                              color: TokenfrontColors.quietText,
                              fontSize: compact ? 13 : 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TokenfrontSpacing.lg),
                      LivingRelayThread(
                        variant: LivingRelayThreadVariant.horizontalProgress,
                        nodes: [
                          for (
                            var index = 0;
                            index < LivingRelayThread.nodeCount;
                            index++
                          )
                            LivingRelayThreadNode(
                              state: index == operationNumber - 1
                                  ? LivingRelayThreadNodeState.active
                                  : LivingRelayThreadNodeState.locked,
                              color: index == operationNumber - 1
                                  ? visual.color
                                  : null,
                            ),
                        ],
                        semanticLabel: context.l10n.currentOperation,
                        animate: false,
                        width: double.infinity,
                      ),
                      const SizedBox(height: TokenfrontSpacing.xl),
                      Text(
                        copy.operationTitle(operation.id),
                        key: const Key('briefing-operation-title'),
                        style: TokenfrontType.display.copyWith(
                          fontSize: compact ? 23 : 31,
                          color: visual.color,
                        ),
                      ),
                      const SizedBox(height: TokenfrontSpacing.lg),
                      Text(
                        copy.incident(operation.id),
                        key: const Key('briefing-incident'),
                        style: TokenfrontType.body.copyWith(
                          fontSize: compact ? 16 : 18,
                          color: TokenfrontColors.relayIvory,
                        ),
                      ),
                      const SizedBox(height: TokenfrontSpacing.xl),
                      OperationBriefingDirectiveRail(
                        directive: directive,
                        bonus: copy.directiveBonus(operation.oneTimeBonus),
                      ),
                      const SizedBox(height: TokenfrontSpacing.xl),
                      OperationBriefingCoreVoice(
                        faction: faction,
                        voice: copy.coreVoice(faction),
                      ),
                      const SizedBox(height: TokenfrontSpacing.xl),
                      Text(
                        context.l10n.signalFork,
                        style: TokenfrontType.instrument.copyWith(
                          color: TokenfrontColors.quietText,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: TokenfrontSpacing.sm),
                      Wrap(
                        spacing: TokenfrontSpacing.md,
                        runSpacing: TokenfrontSpacing.md,
                        children: [
                          OperationBriefingRouteChoice(
                            key: const Key('briefing-route-preserve'),
                            route: RelayRoute.preserve,
                            selected: selectedRoute == RelayRoute.preserve,
                            routeLabel: copy.routeLabel(RelayRoute.preserve),
                            title: copy.routeAction(
                              operation.id,
                              RelayRoute.preserve,
                            ),
                            effect: copy.routeEffect(RelayRoute.preserve),
                            onTap: () => onSelectRoute(RelayRoute.preserve),
                          ),
                          OperationBriefingRouteChoice(
                            key: const Key('briefing-route-force'),
                            route: RelayRoute.force,
                            selected: selectedRoute == RelayRoute.force,
                            routeLabel: copy.routeLabel(RelayRoute.force),
                            title: copy.routeAction(
                              operation.id,
                              RelayRoute.force,
                            ),
                            effect: copy.routeEffect(RelayRoute.force),
                            onTap: () => onSelectRoute(RelayRoute.force),
                          ),
                        ],
                      ),
                      const SizedBox(height: TokenfrontSpacing.xl),
                      OperationBriefingActions(
                        operationNumber: operationNumber,
                        selected: selectedRoute,
                        onDeploy: onDeploy,
                        onBack: onBack,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
