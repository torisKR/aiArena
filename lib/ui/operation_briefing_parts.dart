import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/tokens.dart';
import '../game/faction_visuals.dart';
import '../game/simulation.dart';
import '../l10n/l10n.dart';
import 'primitives.dart';

class OperationBriefingDirectiveRail extends StatelessWidget {
  const OperationBriefingDirectiveRail({
    super.key,
    required this.directive,
    required this.bonus,
  });

  final String directive;
  final String bonus;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: TokenfrontSpacing.md,
      vertical: TokenfrontSpacing.md,
    ),
    decoration: const BoxDecoration(
      border: Border(
        top: BorderSide(color: TokenfrontColors.quietText),
        bottom: BorderSide(color: TokenfrontColors.quietText),
      ),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: TokenfrontSpacing.sm,
      children: [
        Text(
          '${context.l10n.directive}  $directive',
          style: TokenfrontType.instrument.copyWith(fontSize: 12),
        ),
        Text(
          bonus,
          style: TokenfrontType.instrument.copyWith(
            color: TokenfrontColors.threadCyan,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class OperationBriefingCoreVoice extends StatelessWidget {
  const OperationBriefingCoreVoice({
    super.key,
    required this.faction,
    required this.voice,
  });

  final Faction faction;
  final String voice;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        faction.visual.mark,
        style: TokenfrontType.display.copyWith(
          color: faction.visual.color,
          fontSize: 24,
        ),
      ),
      const SizedBox(width: TokenfrontSpacing.md),
      Expanded(
        child: Text(
          '"$voice"',
          key: const Key('briefing-core-voice'),
          style: TokenfrontType.body.copyWith(fontSize: 16),
        ),
      ),
    ],
  );
}

class OperationBriefingRouteChoice extends StatelessWidget {
  const OperationBriefingRouteChoice({
    super.key,
    required this.route,
    required this.routeLabel,
    required this.selected,
    required this.title,
    required this.effect,
    required this.onTap,
  });

  final RelayRoute route;
  final String routeLabel;
  final bool selected;
  final String title;
  final String effect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = '$title. $effect';
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: FocusableActionDetector(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<Intent>(
            onInvoke: (_) {
              onTap();
              return null;
            },
          ),
        },
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 260, minHeight: 128),
            child: Container(
              padding: const EdgeInsets.all(TokenfrontSpacing.lg),
              decoration: ShapeDecoration(
                color: selected
                    ? TokenfrontColors.threadCyan.withValues(alpha: .14)
                    : TokenfrontColors.panel,
                shape: BeveledRectangleBorder(
                  side: BorderSide(
                    color: selected
                        ? TokenfrontColors.threadCyan
                        : TokenfrontColors.quietText,
                    width: selected ? 2 : 1,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(TokenfrontRadii.control),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: selected
                            ? TokenfrontColors.threadCyan
                            : TokenfrontColors.quietText,
                      ),
                      const SizedBox(width: TokenfrontSpacing.sm),
                      Text(
                        routeLabel,
                        style: TokenfrontType.instrument.copyWith(
                          color: selected
                              ? TokenfrontColors.threadCyan
                              : TokenfrontColors.relayIvory,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TokenfrontSpacing.sm),
                  Text(
                    title,
                    style: TokenfrontType.instrument.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: TokenfrontSpacing.sm),
                  Text(
                    effect,
                    style: TokenfrontType.body.copyWith(
                      color: TokenfrontColors.quietText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OperationBriefingActions extends StatelessWidget {
  const OperationBriefingActions({
    super.key,
    required this.operationNumber,
    required this.selected,
    required this.onDeploy,
    required this.onBack,
  });

  final int operationNumber;
  final RelayRoute? selected;
  final VoidCallback onDeploy;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < TokenfrontBreakpoints.stackedActions;
      final width = stacked
          ? constraints.maxWidth
          : (constraints.maxWidth - TokenfrontSpacing.md) / 2;
      return Wrap(
        spacing: TokenfrontSpacing.md,
        runSpacing: TokenfrontSpacing.sm,
        children: [
          SizedBox(
            width: width,
            child: TacticalButton(
              key: const Key('briefing-deploy'),
              label: context.l10n.deployOperation(
                operationNumber.toString().padLeft(2, '0'),
              ),
              color: TokenfrontColors.threadCyan,
              expanded: true,
              onPressed: selected == null ? null : onDeploy,
            ),
          ),
          SizedBox(
            width: width,
            child: OutlinedButton(
              key: const Key('briefing-back-action'),
              onPressed: onBack,
              child: Text(context.l10n.commandDeck),
            ),
          ),
        ],
      );
    },
  );
}
