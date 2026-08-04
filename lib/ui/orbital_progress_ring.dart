import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../l10n/l10n.dart';
import '../story/story_localizations.dart';
import '../story/story_models.dart';

/// A deliberately quiet progress indicator for the five-operation Chronicle.
///
/// The ring is one broken orbit (not five independent progress indicators),
/// and all of its state is supplied as immutable values by the command deck.
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

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: _semanticsLabel(context),
    child: ExcludeSemantics(
      child: SizedBox(
        height: 92,
        width: double.infinity,
        child: CustomPaint(
          painter: _OrbitalProgressPainter(
            progress: progress,
            lowSpec: lowSpec,
            reduceMotion: reduceMotion,
          ),
        ),
      ),
    ),
  );
}

final class _OrbitalProgressPainter extends CustomPainter {
  const _OrbitalProgressPainter({
    required this.progress,
    required this.lowSpec,
    required this.reduceMotion,
  });

  final StoryProgress progress;
  final bool lowSpec;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width * .34, size.height * .38);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = TokenfrontColors.relayIvory.withValues(alpha: .24)
      ..isAntiAlias = false;
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = TokenfrontColors.relayIvory.withValues(alpha: .88)
      ..isAntiAlias = false;

    // Five arcs with an intentional, identical gap at each node make one
    // broken ring while keeping the node count unambiguous.
    const gap = .22;
    for (var index = 0; index < StoryOperationId.values.length; index++) {
      final start = -math.pi / 2 + index * 2 * math.pi / 5 + gap;
      final sweep = 2 * math.pi / 5 - gap * 2;
      final id = StoryOperationId.values[index];
      final concluded = progress.concludedOperations.contains(id);
      final current = progress.currentOperation == id;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        concluded || current ? active : ring,
      );
    }

    for (var index = 0; index < StoryOperationId.values.length; index++) {
      final id = StoryOperationId.values[index];
      final angle = -math.pi / 2 + index * 2 * math.pi / 5;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final concluded = progress.concludedOperations.contains(id);
      final current = progress.currentOperation == id;
      final color = concluded
          ? TokenfrontColors.volt
          : current
          ? TokenfrontColors.relayIvory
          : TokenfrontColors.quietText.withValues(alpha: .6);
      final node = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = false;
      canvas.drawCircle(point, current ? 7 : 5, node);
      if (current && !lowSpec && !reduceMotion) {
        final halo = Paint()
          ..color = color.withValues(alpha: .24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(point, 11, halo);
      }
      final label = 'OP-${index + 1}'.padLeft(5, '0');
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TokenfrontType.instrument.copyWith(color: color, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, point - Offset(painter.width / 2, -15));
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitalProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.lowSpec != lowSpec ||
      oldDelegate.reduceMotion != reduceMotion;
}
