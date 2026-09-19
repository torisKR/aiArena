import 'dart:math' as math;

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

  EdgeInsets _overlayPad(MediaQueryData media, {required bool floor}) {
    double edge(double padding, double viewPadding) {
      final inset = math.max(padding, viewPadding);
      return floor ? math.max(inset, 8) : inset;
    }

    return EdgeInsets.only(
      left: edge(media.padding.left, media.viewPadding.left),
      right: edge(media.padding.right, media.viewPadding.right),
      top: edge(media.padding.top, media.viewPadding.top),
      bottom: edge(media.padding.bottom, media.viewPadding.bottom),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    final recovery = widget.game.simulation.recovery!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final landscapeRails =
            constraints.maxWidth >= constraints.maxHeight &&
            constraints.maxWidth >= TokenfrontBreakpoints.compact;
        final pad = _overlayPad(MediaQuery.of(context), floor: landscapeRails);
        if (landscapeRails) {
          return _landscapeRails(
            copy: copy,
            recovery: recovery,
            pad: pad,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          );
        }
        return _compactFallback(copy: copy, recovery: recovery, pad: pad);
      },
    );
  }

  Widget _landscapeRails({
    required AppLocalizations copy,
    required RecoveryState recovery,
    required EdgeInsets pad,
    required double width,
    required double height,
  }) {
    final shortHeight = height < TokenfrontBreakpoints.stackedActions;
    final railWidth = (width * 0.11).clamp(168.0, 280.0);
    final railInner = railWidth - TokenfrontSpacing.sm * 2;
    final destGap = shortHeight ? 4.0 : TokenfrontSpacing.sm;
    final destWidth = math.max(TokenfrontSizes.buttonWidth, railInner);
    final destHeight = shortHeight ? 56.0 : math.max(72.0, height * 0.08);
    final overlay = instructions || widget.paused;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          key: const Key('recovery-left-rail'),
          left: pad.left,
          top: pad.top,
          bottom: pad.bottom,
          width: railWidth,
          child: TacticalPanel(
            color: TokenfrontColors.deepField,
            padding: const EdgeInsets.all(TokenfrontSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${copy.recoveryProgress(recovery.recoveredCount)} · ${widget.snapshot.remaining.ceil()}s',
                  style: TokenfrontType.instrument,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: TokenfrontSpacing.sm),
                Text(
                  copy.recoveryAutomatic,
                  style: TokenfrontType.body.copyWith(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                _destinationControl(
                  recovery: recovery,
                  copy: copy,
                  index: 0,
                  width: destWidth,
                  minHeight: destHeight,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          key: const Key('recovery-right-rail'),
          right: pad.right,
          top: pad.top,
          bottom: pad.bottom,
          width: railWidth,
          child: TacticalPanel(
            color: TokenfrontColors.deepField,
            padding: const EdgeInsets.all(TokenfrontSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: TacticalButton(
                    key: const Key('battle-pause'),
                    label: widget.paused ? copy.resumeBattle : copy.pauseBattle,
                    onPressed: widget.onPause,
                  ),
                ),
                const Spacer(),
                _destinationControl(
                  recovery: recovery,
                  copy: copy,
                  index: 1,
                  width: destWidth,
                  minHeight: destHeight,
                ),
                SizedBox(height: destGap),
                _destinationControl(
                  recovery: recovery,
                  copy: copy,
                  index: 2,
                  width: destWidth,
                  minHeight: destHeight,
                ),
              ],
            ),
          ),
        ),
        if (overlay)
          Positioned(
            left: pad.left + railWidth,
            right: pad.right + railWidth,
            top: pad.top,
            bottom: pad.bottom,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: math.max(
                    0,
                    width - pad.left - pad.right - railWidth * 2 - 24,
                  ),
                ),
                child: _instructionPanel(copy),
              ),
            ),
          ),
      ],
    );
  }

  Widget _compactFallback({
    required AppLocalizations copy,
    required RecoveryState recovery,
    required EdgeInsets pad,
  }) {
    return Padding(
      padding: pad,
      child: Column(
        children: [
          TacticalPanel(
            color: TokenfrontColors.deepField,
            padding: const EdgeInsets.all(TokenfrontSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${copy.recoveryProgress(recovery.recoveredCount)} · ${widget.snapshot.remaining.ceil()}s',
                    style: TokenfrontType.instrument,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  ? _instructionPanel(copy)
                  : const SizedBox.shrink(),
            ),
          ),
          TacticalPanel(
            color: TokenfrontColors.deepField,
            padding: const EdgeInsets.all(TokenfrontSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  copy.recoveryAutomatic,
                  textAlign: TextAlign.center,
                  style: TokenfrontType.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: TokenfrontSpacing.xs),
                Row(
                  children: [
                    for (var index = 0; index < 3; index++) ...[
                      if (index > 0)
                        const SizedBox(width: TokenfrontSpacing.xs),
                      Expanded(
                        child: _destinationControl(
                          recovery: recovery,
                          copy: copy,
                          index: index,
                          minHeight: TokenfrontSizes.buttonHeight,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionPanel(AppLocalizations copy) => SingleChildScrollView(
    child: TacticalPanel(
      color: TokenfrontColors.deepField,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.paused ? copy.battlePaused : copy.recoveryTitle,
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
              label: copy.recoveryChooseDestination,
              onPressed: widget.enabled
                  ? () => setState(widget.game.acknowledgeRecoveryInstruction)
                  : null,
            ),
          ],
        ],
      ),
    ),
  );

  Widget _destinationControl({
    required RecoveryState recovery,
    required AppLocalizations copy,
    required int index,
    double? width,
    required double minHeight,
  }) {
    return ConstrainedBox(
      key: Key('recovery-destination-$index'),
      constraints: BoxConstraints(
        minWidth: width ?? 0,
        maxWidth: width ?? double.infinity,
        minHeight: minHeight,
      ),
      child: Semantics(
        selected: recovery.selected == index,
        child: TacticalButton(
          expanded: true,
          label:
              '${index + 1}\n${recovery.seconds[index].floor()}/${RecoveryState.requiredSeconds.floor()}',
          semanticLabel: copy.recoveryDestination(
            index + 1,
            recovery.seconds[index].floor(),
          ),
          color: recovery.seconds[index] >= RecoveryState.requiredSeconds
              ? TokenfrontColors.volt
              : recovery.selected == index
              ? TokenfrontColors.threadCyan
              : TokenfrontColors.relayIvory,
          onPressed:
              widget.enabled &&
                  recovery.seconds[index] < RecoveryState.requiredSeconds
              ? () {
                  widget.game.selectDestination(index);
                  setState(() {});
                }
              : null,
        ),
      ),
    );
  }
}
