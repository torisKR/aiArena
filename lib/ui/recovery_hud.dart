import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../game/recovery.dart';
import '../game/tokenfront_game.dart';
import '../l10n/l10n.dart';
import 'primitives.dart';

class RecoveryHud extends StatefulWidget {
  const RecoveryHud({
    super.key,
    required this.game,
    required this.snapshot,
    required this.paused,
    required this.enabled,
    required this.onPause,
  });
  final TokenfrontGame game;
  final BattleHudSnapshot snapshot;
  final bool paused;
  final bool enabled;
  final VoidCallback onPause;

  @override
  State<RecoveryHud> createState() => _RecoveryHudState();
}

class _RecoveryHudState extends State<RecoveryHud> {
  bool get instructions => widget.game.awaitingRecoveryInstruction;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    final recovery = widget.game.simulation.recovery!;
    return Column(
      children: [
        TacticalPanel(
          color: TokenfrontColors.deepField,
          padding: const EdgeInsets.all(TokenfrontSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${copy.recoveryProgress(recovery.recoveredCount)} · ${widget.snapshot.remaining.ceil()}s',
                  style: TokenfrontType.instrument,
                ),
              ),
              const SizedBox(width: TokenfrontSpacing.sm),
              TacticalButton(
                key: const Key('battle-pause'),
                label: widget.paused ? copy.resumeBattle : copy.pauseBattle,
                onPressed: widget.onPause,
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: instructions || widget.paused
                ? SingleChildScrollView(
                    child: TacticalPanel(
                      color: TokenfrontColors.deepField,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.paused
                                ? copy.battlePaused
                                : copy.recoveryTitle,
                            style: TokenfrontType.instrument,
                          ),
                          const SizedBox(height: TokenfrontSpacing.md),
                          Text(
                            copy.recoveryInstruction,
                            textAlign: TextAlign.center,
                            style: TokenfrontType.body,
                          ),
                          if (!widget.paused) ...[
                            const SizedBox(height: TokenfrontSpacing.md),
                            TacticalButton(
                              key: const Key('recovery-dismiss-instructions'),
                              expanded: true,
                              label: 'CHOOSE DESTINATION',
                              onPressed: widget.enabled
                                  ? () => setState(
                                      widget
                                          .game
                                          .acknowledgeRecoveryInstruction,
                                    )
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        TacticalPanel(
          color: TokenfrontColors.deepField,
          padding: const EdgeInsets.all(TokenfrontSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                copy.recoveryAutomatic,
                textAlign: TextAlign.center,
                style: TokenfrontType.body,
              ),
              const SizedBox(height: TokenfrontSpacing.sm),
              Row(
                children: [
                  for (var index = 0; index < 3; index++) ...[
                    if (index > 0) const SizedBox(width: TokenfrontSpacing.sm),
                    Expanded(
                      child: Semantics(
                        selected: recovery.selected == index,
                        child: TacticalButton(
                          expanded: true,
                          key: Key('recovery-destination-$index'),
                          label:
                              '${index + 1}\n${recovery.seconds[index].floor()}/10',
                          semanticLabel: copy.recoveryDestination(
                            index + 1,
                            recovery.seconds[index].floor(),
                          ),
                          color:
                              recovery.seconds[index] >=
                                  RecoveryState.requiredSeconds
                              ? TokenfrontColors.volt
                              : recovery.selected == index
                              ? TokenfrontColors.threadCyan
                              : TokenfrontColors.relayIvory,
                          onPressed:
                              widget.enabled &&
                                  recovery.seconds[index] <
                                      RecoveryState.requiredSeconds
                              ? () {
                                  widget.game.selectDestination(index);
                                  setState(() {});
                                }
                              : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
