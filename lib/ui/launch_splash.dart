import 'dart:async';

import 'package:flutter/material.dart';

/// App launch artwork; shown once per launch, not on lifecycle resume.
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({super.key, required this.child});

  final Widget child;
  static const duration = Duration(seconds: 2);
  static const asset = 'assets/images/splah_image.webp';

  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash> {
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _timer = Timer(LaunchSplash.duration, () {
        if (mounted) setState(() => _finished = true);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return widget.child;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        key: const Key('launch-splash'),
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: Image.asset(
              LaunchSplash.asset,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
