import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/tokens.dart';

enum FactionGlyphKind { diamond, brackets, bolt, prism }

class FactionGlyph extends StatelessWidget {
  const FactionGlyph({
    super.key,
    required this.kind,
    required this.color,
    this.size = 40,
    this.selected = false,
  });

  final FactionGlyphKind kind;
  final Color color;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _FactionGlyphPainter(
        kind: kind,
        color: color,
        selected: selected,
      ),
    ),
  );
}

class _FactionGlyphPainter extends CustomPainter {
  const _FactionGlyphPainter({
    required this.kind,
    required this.color,
    required this.selected,
  });

  final FactionGlyphKind kind;
  final Color color;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, size.width * .09)
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter
      ..isAntiAlias = false;
    final r = size.shortestSide * .29;

    switch (kind) {
      case FactionGlyphKind.diamond:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - r)
            ..lineTo(center.dx + r, center.dy)
            ..lineTo(center.dx, center.dy + r)
            ..lineTo(center.dx - r, center.dy)
            ..close(),
          paint,
        );
        break;
      case FactionGlyphKind.brackets:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx - r * .3, center.dy - r)
            ..lineTo(center.dx - r, center.dy - r)
            ..lineTo(center.dx - r, center.dy + r)
            ..lineTo(center.dx - r * .3, center.dy + r)
            ..moveTo(center.dx + r * .3, center.dy - r)
            ..lineTo(center.dx + r, center.dy - r)
            ..lineTo(center.dx + r, center.dy + r)
            ..lineTo(center.dx + r * .3, center.dy + r),
          paint,
        );
        break;
      case FactionGlyphKind.bolt:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx + r * .2, center.dy - r)
            ..lineTo(center.dx - r * .65, center.dy + r * .1)
            ..lineTo(center.dx, center.dy + r * .05)
            ..lineTo(center.dx - r * .18, center.dy + r)
            ..lineTo(center.dx + r * .72, center.dy - r * .22)
            ..lineTo(center.dx + r * .04, center.dy - r * .16)
            ..close(),
          paint,
        );
        break;
      case FactionGlyphKind.prism:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - r)
            ..lineTo(center.dx, center.dy + r)
            ..moveTo(center.dx - r, center.dy)
            ..lineTo(center.dx + r, center.dy)
            ..moveTo(center.dx - r * .72, center.dy - r * .72)
            ..lineTo(center.dx + r * .72, center.dy + r * .72)
            ..moveTo(center.dx + r * .72, center.dy - r * .72)
            ..lineTo(center.dx - r * .72, center.dy + r * .72),
          paint,
        );
        break;
    }

    if (selected) {
      final ring = Paint()
        ..color = TokenfrontColors.relayIvory
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..isAntiAlias = false;
      canvas.drawRect(Offset.zero & size, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _FactionGlyphPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.color != color ||
      oldDelegate.selected != selected;
}

class TacticalPanel extends StatelessWidget {
  const TacticalPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = TokenfrontColors.panel,
    this.borderColor = const Color(0x4DF2E9D1),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: ShapeDecoration(
      color: color,
      shape: BeveledRectangleBorder(
        side: BorderSide(color: borderColor),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
    ),
    child: child,
  );
}

class TacticalButton extends StatelessWidget {
  const TacticalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = TokenfrontColors.relayIvory,
    this.expanded = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color color;
  final bool expanded;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      label: semanticLabel,
      button: true,
      child: FilledButton(
        onPressed: onPressed,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(124, 50)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? color.withValues(alpha: .18)
                : color,
          ),
          foregroundColor: const WidgetStatePropertyAll(
            TokenfrontColors.deepField,
          ),
          overlayColor: WidgetStatePropertyAll(
            TokenfrontColors.deepField.withValues(alpha: .12),
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.focused)
                  ? TokenfrontColors.relayIvory
                  : Colors.transparent,
              width: states.contains(WidgetState.focused) ? 3 : 1,
            ),
          ),
          shape: const WidgetStatePropertyAll(
            BeveledRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(TokenfrontType.instrument),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 9)],
            Text(label),
          ],
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// A compact instrument-like control for battle view preferences.
class TacticalToggle extends StatelessWidget {
  const TacticalToggle({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final bool? selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    button: true,
    enabled: onPressed != null,
    selected: selected,
    child: ExcludeSemantics(
      child: SizedBox(
        width: 52,
        height: 40,
        child: OutlinedButton(
          onPressed: onPressed,
          style: ButtonStyle(
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            foregroundColor: WidgetStatePropertyAll(
              selected == true
                  ? TokenfrontColors.deepField
                  : TokenfrontColors.relayIvory,
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => selected == true
                  ? TokenfrontColors.relayIvory
                  : states.contains(WidgetState.hovered)
                  ? TokenfrontColors.panelStrong
                  : TokenfrontColors.deepField.withValues(alpha: .72),
            ),
            side: WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.focused)
                    ? TokenfrontColors.relayIvory
                    : selected == true
                    ? TokenfrontColors.relayIvory
                    : TokenfrontColors.relayIvory.withValues(alpha: .28),
                width: states.contains(WidgetState.focused) ? 3 : 1,
              ),
            ),
            shape: const WidgetStatePropertyAll(
              BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(7)),
              ),
            ),
            textStyle: WidgetStatePropertyAll(
              TokenfrontType.instrument.copyWith(fontSize: 8.5),
            ),
          ),
          child: Text(label),
        ),
      ),
    ),
  );
}

class TacticalBackdrop extends StatelessWidget {
  const TacticalBackdrop({
    super.key,
    required this.child,
    this.showKeyArt = true,
  });

  final Widget child;
  final bool showKeyArt;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const ColoredBox(color: TokenfrontColors.deepField),
      if (showKeyArt)
        Image.asset(
          'assets/blender/tokenfront_keyart.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.low,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              TokenfrontColors.deepField.withValues(alpha: .50),
              TokenfrontColors.deepField.withValues(alpha: .20),
              TokenfrontColors.deepField.withValues(alpha: .84),
            ],
            stops: const [0, .48, 1],
          ),
        ),
      ),
      IgnorePointer(child: CustomPaint(painter: _DitherPainter())),
      child,
    ],
  );
}

class _DitherPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TokenfrontColors.relayIvory.withValues(alpha: .035)
      ..isAntiAlias = false;
    for (var y = 0.0; y < size.height; y += 8) {
      final offset = ((y ~/ 8).isEven ? 0.0 : 4.0);
      for (var x = offset; x < size.width; x += 8) {
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
