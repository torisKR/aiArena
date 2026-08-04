import 'package:flutter/foundation.dart';

/// Locally persisted presentation, input, and language preferences.
///
/// Privacy consent and economy state live in their own domain services. Keeping
/// visual preferences separate ensures a failed ad or analytics adapter can
/// never block input, simulation, or rendering.
class GamePreferences extends ChangeNotifier {
  factory GamePreferences({
    bool lowSpecMode = false,
    bool forceReducedMotion = false,
    bool mouseCameraEnabled = true,
    bool hapticsEnabled = true,
    bool audioEnabled = true,
    String languageCode = 'system',
  }) => GamePreferences._(
    lowSpecMode,
    forceReducedMotion,
    mouseCameraEnabled,
    hapticsEnabled,
    audioEnabled,
    _supportedLanguageCodes.contains(languageCode) ? languageCode : 'system',
  );

  GamePreferences._(
    this._lowSpecMode,
    this._forceReducedMotion,
    this._mouseCameraEnabled,
    this._hapticsEnabled,
    this._audioEnabled,
    this._languageCode,
  );

  static const _supportedLanguageCodes = <String>{
    'system',
    'en',
    'ko',
    'ja',
    'zh',
  };

  bool _lowSpecMode;
  bool _forceReducedMotion;
  bool _mouseCameraEnabled;
  bool _hapticsEnabled;
  bool _audioEnabled;
  String _languageCode;

  bool get lowSpecMode => _lowSpecMode;
  bool get forceReducedMotion => _forceReducedMotion;
  bool get mouseCameraEnabled => _mouseCameraEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get audioEnabled => _audioEnabled;
  String get languageCode => _languageCode;

  bool reducedMotionFor({required bool systemPrefersReducedMotion}) =>
      _forceReducedMotion || systemPrefersReducedMotion;

  void setLowSpecMode(bool value) {
    if (_lowSpecMode == value) return;
    _lowSpecMode = value;
    notifyListeners();
  }

  void setForceReducedMotion(bool value) {
    if (_forceReducedMotion == value) return;
    _forceReducedMotion = value;
    notifyListeners();
  }

  void setMouseCameraEnabled(bool value) {
    if (_mouseCameraEnabled == value) return;
    _mouseCameraEnabled = value;
    notifyListeners();
  }

  void setHapticsEnabled(bool value) {
    if (_hapticsEnabled == value) return;
    _hapticsEnabled = value;
    notifyListeners();
  }

  void setAudioEnabled(bool value) {
    if (_audioEnabled == value) return;
    _audioEnabled = value;
    notifyListeners();
  }

  void setLanguageCode(String value) {
    if (!_supportedLanguageCodes.contains(value)) {
      throw ArgumentError.value(value, 'value', 'unsupported language code');
    }
    if (_languageCode == value) return;
    _languageCode = value;
    notifyListeners();
  }
}
