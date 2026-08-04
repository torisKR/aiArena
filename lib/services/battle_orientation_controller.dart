import 'package:flutter/services.dart';

import 'privacy/privacy_state.dart';

typedef PreferredOrientationSetter =
    Future<void> Function(List<DeviceOrientation> orientations);

final class BattleOrientationController {
  BattleOrientationController({
    required this.platform,
    PreferredOrientationSetter? setter,
  }) : _setter = setter ?? SystemChrome.setPreferredOrientations;

  static const phoneBreakpoint = 600.0;

  final ClientPlatform platform;
  final PreferredOrientationSetter _setter;
  bool _locked = false;

  bool get isLocked => _locked;

  bool get _supportsOrientationRequest =>
      platform == ClientPlatform.android ||
      platform == ClientPlatform.ios ||
      platform == ClientPlatform.web;

  bool requiresLandscape({required double logicalShortestSide}) =>
      _supportsOrientationRequest && logicalShortestSide < phoneBreakpoint;

  Future<void> enterBattle({required double logicalShortestSide}) async {
    if (!requiresLandscape(logicalShortestSide: logicalShortestSide) ||
        _locked) {
      return;
    }
    await _setter(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _locked = true;
  }

  Future<void> restore() async {
    if (!_locked) return;
    await _setter(const []);
    _locked = false;
  }
}
