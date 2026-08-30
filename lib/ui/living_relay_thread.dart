import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// The four contexts in which the Living Relay Thread is used.
enum LivingRelayThreadVariant {
  horizontalProgress,
  horizontalCharge,
  compactFragment,
  verticalArchive,
}

/// Semantic state for a node or route segment.
enum LivingRelayThreadNodeState {
  pending,
  locked,
  active,
  current,
  confirmed,
  faction,
  fault,
}

/// A node in the five-stop relay route.
class LivingRelayThreadNode {
  const LivingRelayThreadNode({
    this.identifier,
    this.label,
    this.state = LivingRelayThreadNodeState.locked,
    this.color,
    this.factionColor,
  });

  final String? identifier;
  final String? label;
  final LivingRelayThreadNodeState state;

  /// Explicit color is useful for faction identifiers supplied by a caller.
  final Color? color;
  final Color? factionColor;

  Color get paintColor {
    if (color case final explicit?) return explicit;
    if (state == LivingRelayThreadNodeState.faction && factionColor != null) {
      return factionColor!;
    }
    return switch (state) {
      LivingRelayThreadNodeState.active ||
      LivingRelayThreadNodeState.current => TokenfrontColors.threadCyan,
      LivingRelayThreadNodeState.confirmed => TokenfrontColors.relayIvory,
      LivingRelayThreadNodeState.fault => TokenfrontColors.faultCoral,
      LivingRelayThreadNodeState.pending ||
      LivingRelayThreadNodeState.locked ||
      LivingRelayThreadNodeState.faction => TokenfrontColors.archiveAsh,
    };
  }
}

/// A route segment between two adjacent relay nodes.
class LivingRelayThreadSegment {
  const LivingRelayThreadSegment({
    this.state = LivingRelayThreadNodeState.locked,
    this.color,
  });

  final LivingRelayThreadNodeState state;
  final Color? color;

  Color get paintColor =>
      color ??
      switch (state) {
        LivingRelayThreadNodeState.active ||
        LivingRelayThreadNodeState.current => TokenfrontColors.threadCyan,
        LivingRelayThreadNodeState.confirmed => TokenfrontColors.relayIvory,
        LivingRelayThreadNodeState.fault => TokenfrontColors.faultCoral,
        LivingRelayThreadNodeState.pending ||
        LivingRelayThreadNodeState.locked ||
        LivingRelayThreadNodeState.faction => TokenfrontColors.archiveAsh,
      };
}

/// A reusable, localized, paint-backed relay route.
class LivingRelayThread extends StatefulWidget {
  const LivingRelayThread({
    super.key,
    this.variant = LivingRelayThreadVariant.horizontalProgress,
    this.progress = 0,
    this.charge = 0,
    this.nodes = const <LivingRelayThreadNode>[],
    this.segments = const <LivingRelayThreadSegment>[],
    this.fragment,
    this.semanticLabel,
    this.semanticHint,
    this.reducedMotion = false,
    this.lowSpec = false,
    this.animate = true,
    this.duration = TokenfrontMotion.directiveCue,
    this.width,
    this.height,
  });

  static const int nodeCount = 5;
  static const int routeSegmentCount = nodeCount - 1;

  static const defaultNodes = <LivingRelayThreadNode>[
    LivingRelayThreadNode(state: LivingRelayThreadNodeState.active),
    LivingRelayThreadNode(),
    LivingRelayThreadNode(),
    LivingRelayThreadNode(),
    LivingRelayThreadNode(),
  ];

  final LivingRelayThreadVariant variant;
  final double progress;
  final double charge;
  final List<LivingRelayThreadNode> nodes;
  final List<LivingRelayThreadSegment> segments;
  final String? fragment;

  /// Supply this from the active locale; the widget never invents copy.
  final String? semanticLabel;
  final String? semanticHint;
  final bool reducedMotion;
  final bool lowSpec;
  final bool animate;
  final Duration duration;
  final double? width;
  final double? height;

  bool get animationsEnabled => animate && !reducedMotion && !lowSpec;

  @override
  State<LivingRelayThread> createState() => _LivingRelayThreadState();
}

class _LivingRelayThreadState extends State<LivingRelayThread>
    with TickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant LivingRelayThread oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration && _controller != null) {
      _controller!.duration = widget.duration;
    }
    if (oldWidget.animationsEnabled != widget.animationsEnabled) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.animationsEnabled) {
      _controller ??= AnimationController(
        vsync: this,
        duration: widget.duration,
      )..forward(from: 0);
    } else {
      _controller?.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = _controller;
    final child = animation == null
        ? _buildPaint(1)
        : AnimatedBuilder(
            animation: animation,
            builder: (context, child) => _buildPaint(animation.value),
          );
    final sized = SizedBox(
      width: widget.width,
      height: widget.height ?? _defaultHeight,
      child: child,
    );
    final label = widget.semanticLabel;
    if (label == null || label.isEmpty) return sized;
    return Semantics(
      container: true,
      label: label,
      hint: widget.semanticHint,
      child: ExcludeSemantics(child: sized),
    );
  }

  double get _defaultHeight => switch (widget.variant) {
    LivingRelayThreadVariant.compactFragment => 24,
    LivingRelayThreadVariant.verticalArchive => 176,
    LivingRelayThreadVariant.horizontalProgress ||
    LivingRelayThreadVariant.horizontalCharge => 40,
  };

  Widget _buildPaint(double animationValue) {
    return CustomPaint(
      painter: LivingRelayThreadPainter(
        variant: widget.variant,
        progress: widget.progress,
        charge: widget.charge,
        nodes: widget.nodes,
        segments: widget.segments,
        fragment: widget.fragment,
        animationValue: animationValue,
      ),
      size: Size.infinite,
    );
  }
}

/// The painter is public so visual tests can assert the 2 px contract.
class LivingRelayThreadPainter extends CustomPainter {
  const LivingRelayThreadPainter({
    required this.variant,
    this.progress = 0,
    this.charge = 0,
    this.nodes = const <LivingRelayThreadNode>[],
    this.segments = const <LivingRelayThreadSegment>[],
    this.fragment,
    this.animationValue = 1,
  });

  final LivingRelayThreadVariant variant;
  final double progress;
  final double charge;
  final List<LivingRelayThreadNode> nodes;
  final List<LivingRelayThreadSegment> segments;
  final String? fragment;
  final double animationValue;

  double get baseStrokeWidth => TokenfrontSizes.threadStroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final routeNodes = _resolvedNodes;
    final routeSegments = _resolvedSegments(routeNodes);
    switch (variant) {
      case LivingRelayThreadVariant.verticalArchive:
        _paintVertical(canvas, size, routeNodes, routeSegments);
      case LivingRelayThreadVariant.compactFragment:
        _paintHorizontal(canvas, size, routeNodes, routeSegments, progress);
        _paintFragment(canvas, size);
      case LivingRelayThreadVariant.horizontalProgress:
        _paintHorizontal(canvas, size, routeNodes, routeSegments, progress);
      case LivingRelayThreadVariant.horizontalCharge:
        _paintHorizontal(canvas, size, routeNodes, routeSegments, charge);
    }
  }

  List<LivingRelayThreadNode> get _resolvedNodes {
    final source = nodes.isEmpty ? LivingRelayThread.defaultNodes : nodes;
    return List<LivingRelayThreadNode>.generate(
      LivingRelayThread.nodeCount,
      (index) =>
          index < source.length ? source[index] : const LivingRelayThreadNode(),
    );
  }

  List<LivingRelayThreadSegment> _resolvedSegments(
    List<LivingRelayThreadNode> routeNodes,
  ) {
    return List<LivingRelayThreadSegment>.generate(
      LivingRelayThread.routeSegmentCount,
      (index) => index < segments.length
          ? segments[index]
          : LivingRelayThreadSegment(state: routeNodes[index].state),
    );
  }

  void _paintHorizontal(
    Canvas canvas,
    Size size,
    List<LivingRelayThreadNode> routeNodes,
    List<LivingRelayThreadSegment> routeSegments,
    double amount,
  ) {
    final inset = math.min(TokenfrontSpacing.sm, size.width / 2);
    final usableWidth = math.max(0, size.width - inset * 2);
    final y = size.height / 2;
    final points = [
      for (var i = 0; i < LivingRelayThread.nodeCount; i++)
        Offset(
          inset + usableWidth * i / LivingRelayThread.routeSegmentCount,
          y,
        ),
    ];
    _paintRoute(canvas, points, routeNodes, routeSegments, amount);
  }

  void _paintVertical(
    Canvas canvas,
    Size size,
    List<LivingRelayThreadNode> routeNodes,
    List<LivingRelayThreadSegment> routeSegments,
  ) {
    final inset = math.min(TokenfrontSpacing.sm, size.height / 2);
    final usableHeight = math.max(0, size.height - inset * 2);
    final x = size.width / 2;
    final points = [
      for (var i = 0; i < LivingRelayThread.nodeCount; i++)
        Offset(
          x,
          inset + usableHeight * i / LivingRelayThread.routeSegmentCount,
        ),
    ];
    _paintRoute(canvas, points, routeNodes, routeSegments, progress);
  }

  void _paintRoute(
    Canvas canvas,
    List<Offset> points,
    List<LivingRelayThreadNode> routeNodes,
    List<LivingRelayThreadSegment> routeSegments,
    double amount,
  ) {
    final normalizedAmount = amount.clamp(0.0, 1.0).toDouble();
    for (var index = 0; index < LivingRelayThread.routeSegmentCount; index++) {
      final segmentProgress =
          ((normalizedAmount * LivingRelayThread.routeSegmentCount) - index)
              .clamp(0.0, 1.0)
              .toDouble();
      final start = points[index];
      final end = points[index + 1];
      canvas.drawLine(start, end, _stroke(routeSegments[index].paintColor));
      if (segmentProgress > 0) {
        canvas.drawLine(
          start,
          Offset.lerp(start, end, segmentProgress)!,
          _stroke(_activeColor(routeSegments[index].state)),
        );
      }
    }
    for (var index = 0; index < points.length; index++) {
      final node = routeNodes[index];
      final pulse = node.state == LivingRelayThreadNodeState.active
          ? math.sin(animationValue * math.pi * 2) * .8
          : 0;
      canvas.drawCircle(
        points[index],
        math.max(2.5, 3.5 + pulse),
        Paint()
          ..color = node.paintColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }
  }

  void _paintFragment(Canvas canvas, Size size) {
    final text = fragment;
    if (text == null || text.isEmpty || size.width < 20) return;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TokenfrontType.instrument.copyWith(
          color: TokenfrontColors.archiveAsh,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(0, size.width - 18));
    painter.paint(canvas, Offset(18, (size.height - painter.height) / 2));
  }

  Paint _stroke(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = baseStrokeWidth
    ..strokeCap = StrokeCap.square
    ..isAntiAlias = true;

  Color _activeColor(LivingRelayThreadNodeState state) => switch (state) {
    LivingRelayThreadNodeState.confirmed => TokenfrontColors.relayIvory,
    LivingRelayThreadNodeState.fault => TokenfrontColors.faultCoral,
    LivingRelayThreadNodeState.faction => TokenfrontColors.threadCyan,
    LivingRelayThreadNodeState.pending ||
    LivingRelayThreadNodeState.locked ||
    LivingRelayThreadNodeState.active ||
    LivingRelayThreadNodeState.current => TokenfrontColors.threadCyan,
  };

  @override
  bool shouldRepaint(covariant LivingRelayThreadPainter oldDelegate) {
    return oldDelegate.variant != variant ||
        oldDelegate.progress != progress ||
        oldDelegate.charge != charge ||
        oldDelegate.nodes != nodes ||
        oldDelegate.segments != segments ||
        oldDelegate.fragment != fragment ||
        oldDelegate.animationValue != animationValue;
  }
}
