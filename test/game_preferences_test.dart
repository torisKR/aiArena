import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/settings/game_preferences.dart';

void main() {
  test('reduced motion respects system and explicit preferences', () {
    final preferences = GamePreferences();

    expect(
      preferences.reducedMotionFor(systemPrefersReducedMotion: false),
      isFalse,
    );
    expect(
      preferences.reducedMotionFor(systemPrefersReducedMotion: true),
      isTrue,
    );

    preferences.setForceReducedMotion(true);
    expect(
      preferences.reducedMotionFor(systemPrefersReducedMotion: false),
      isTrue,
    );
  });

  test('presentation preferences are independent and observable', () {
    final preferences = GamePreferences();
    var changes = 0;
    preferences.addListener(() => changes++);

    preferences
      ..setLowSpecMode(true)
      ..setMouseCameraEnabled(false)
      ..setHapticsEnabled(false)
      ..setAudioEnabled(false);

    expect(preferences.lowSpecMode, isTrue);
    expect(preferences.mouseCameraEnabled, isFalse);
    expect(preferences.hapticsEnabled, isFalse);
    expect(preferences.audioEnabled, isFalse);
    expect(changes, 4);
  });
}
