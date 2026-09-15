import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/services/audio/game_audio_service.dart';

void main() {
  test('named cues use the existing assets with one bounded voice each', () async {
    final backend = _FakeBackend();
    final service = GameAudioService(backend: backend);

    await service.initialize();

    expect(backend.configs, hasLength(GameAudioCue.values.length));
    expect(backend.configFor(GameAudioCue.dash).asset, 'dash.wav');
    expect(backend.configFor(GameAudioCue.combatImpact).asset, 'impact.wav');
    expect(backend.configFor(GameAudioCue.commandRelay).asset, 'relay.wav');
    expect(backend.configFor(GameAudioCue.recoveryComplete).asset, 'relay.wav');
    expect(backend.configs.every((config) => config.maxVoices == 1), isTrue);
  });

  test('mute while loading suppresses the late play request', () async {
    final backend = _FakeBackend(delayCreation: true);
    final service = GameAudioService(backend: backend);

    final initialization = service.initialize();
    final play = service.play(GameAudioCue.dash);
    await service.setMuted(true);
    await Future.wait([initialization, backend.completeCreations()]);
    await play;

    expect(backend.poolFor(GameAudioCue.dash).startCount, 0);
  });

  test('all independent suspension reasons must clear before playback resumes', () async {
    final backend = _FakeBackend();
    final service = GameAudioService(backend: backend);
    await service.initialize();

    await service.suspend(AudioSuspensionReason.lifecycle);
    await service.suspend(AudioSuspensionReason.fullScreenAd);
    service.resume(AudioSuspensionReason.lifecycle);
    await service.play(GameAudioCue.commandRelay);
    expect(backend.poolFor(GameAudioCue.commandRelay).startCount, 0);

    service.resume(AudioSuspensionReason.fullScreenAd);
    await service.play(GameAudioCue.commandRelay);
    expect(backend.poolFor(GameAudioCue.commandRelay).startCount, 1);

    await service.setMuted(true);
    await service.suspend(AudioSuspensionReason.manualPause);
    service.resume(AudioSuspensionReason.manualPause);
    await service.play(GameAudioCue.commandRelay);
    expect(backend.poolFor(GameAudioCue.commandRelay).startCount, 1);
  });

  test('combat cue is throttled for 150 milliseconds', () async {
    var now = Duration.zero;
    final backend = _FakeBackend();
    final service = GameAudioService(backend: backend, now: () => now);
    await service.initialize();

    await service.play(GameAudioCue.combatImpact);
    now = const Duration(milliseconds: 149);
    await service.play(GameAudioCue.combatImpact);
    backend.poolFor(GameAudioCue.combatImpact).completeActive();
    now = const Duration(milliseconds: 150);
    await service.play(GameAudioCue.combatImpact);

    expect(backend.poolFor(GameAudioCue.combatImpact).startCount, 2);
  });

  test('concurrent requests for one cue never exceed its voice bound', () async {
    final backend = _FakeBackend();
    final service = GameAudioService(backend: backend);
    await service.initialize();
    final pool = backend.poolFor(GameAudioCue.dash)..delayNextStart = true;

    final first = service.play(GameAudioCue.dash);
    final second = service.play(GameAudioCue.dash);
    await Future<void>.delayed(Duration.zero);
    expect(pool.startCount, 1);

    pool.completeDelayedStart();
    await Future.wait([first, second]);

    expect(pool.startCount, 2);
    expect(pool.maximumActive, 1);
  });

  test('one missing asset disables only its cue', () async {
    final backend = _FakeBackend(failingCue: GameAudioCue.combatImpact);
    final service = GameAudioService(backend: backend);

    await service.initialize();
    await service.play(GameAudioCue.combatImpact);
    await service.play(GameAudioCue.dash);
    await service.play(GameAudioCue.commandRelay);

    expect(service.isCueAvailable(GameAudioCue.combatImpact), isFalse);
    expect(backend.poolFor(GameAudioCue.dash).startCount, 1);
    expect(backend.poolFor(GameAudioCue.commandRelay).startCount, 1);
  });

  test('start errors stay contained and later playback can recover', () async {
    final backend = _FakeBackend();
    final service = GameAudioService(backend: backend);
    await service.initialize();
    final pool = backend.poolFor(GameAudioCue.dash)..failNextStart = true;

    await expectLater(service.play(GameAudioCue.dash), completes);
    await service.play(GameAudioCue.dash);

    expect(pool.startCount, 2);
  });

  test('suspension stops active cues and late async starts', () async {
    final backend = _FakeBackend();
    final service = GameAudioService(backend: backend);
    await service.initialize();
    final pool = backend.poolFor(GameAudioCue.recoveryComplete)
      ..delayNextStart = true;

    final play = service.play(GameAudioCue.recoveryComplete);
    await Future<void>.delayed(Duration.zero);
    final suspension = service.suspend(AudioSuspensionReason.lifecycle);
    final latePlayback = pool.completeDelayedStart();
    await play;
    await suspension;

    expect(latePlayback.stopCount, 1);
    expect(service.activeVoiceCount, 0);
  });

  test('suspend and resume discard requests queued before interruption', () async {
    final backend = _FakeBackend();
    final service = GameAudioService(backend: backend);
    await service.initialize();
    final pool = backend.poolFor(GameAudioCue.dash)..delayNextStart = true;

    final first = service.play(GameAudioCue.dash);
    final pending = service.play(GameAudioCue.dash);
    await Future<void>.delayed(Duration.zero);
    final suspension = service.suspend(AudioSuspensionReason.manualPause);
    service.resume(AudioSuspensionReason.manualPause);
    pool.completeDelayedStart();
    await Future.wait([first, pending, suspension]);

    expect(pool.startCount, 1);
    expect(pool.active.single.stopCount, 1);
  });

  test('muting stops an active cue and unmute never replays it', () async {
    final backend = _FakeBackend();
    final service = GameAudioService(backend: backend);
    await service.initialize();

    await service.play(GameAudioCue.dash);
    final playback = backend.poolFor(GameAudioCue.dash).active.single;
    await service.setMuted(true);
    await service.setMuted(false);

    expect(playback.stopCount, 1);
    expect(backend.poolFor(GameAudioCue.dash).startCount, 1);
  });

  test('dispose is idempotent and cleans pools that finish loading late', () async {
    final backend = _FakeBackend(delayCreation: true);
    final service = GameAudioService(backend: backend);
    final initialization = service.initialize();

    final firstDispose = service.dispose();
    final secondDispose = service.dispose();
    await backend.completeNextCreation();
    await Future.wait([initialization, firstDispose, secondDispose]);

    expect(backend.pools.values.every((pool) => pool.disposeCount == 1), isTrue);
    await expectLater(service.play(GameAudioCue.dash), completes);
    expect(backend.poolFor(GameAudioCue.dash).startCount, 0);
  });
}

final class _FakeBackend implements GameAudioBackend {
  _FakeBackend({this.delayCreation = false, this.failingCue});

  final bool delayCreation;
  final GameAudioCue? failingCue;
  final List<GameAudioCueConfig> configs = [];
  final Map<GameAudioCue, _FakePool> pools = {};
  final Map<GameAudioCue, Completer<GameAudioPool>> _creations = {};

  @override
  Future<GameAudioPool> createPool(GameAudioCueConfig config) {
    configs.add(config);
    if (config.cue == failingCue) return Future.error(StateError('missing'));
    final pool = _FakePool();
    pools[config.cue] = pool;
    if (!delayCreation) return Future.value(pool);
    final completer = Completer<GameAudioPool>();
    _creations[config.cue] = completer;
    return completer.future;
  }

  GameAudioCueConfig configFor(GameAudioCue cue) =>
      configs.singleWhere((config) => config.cue == cue);

  _FakePool poolFor(GameAudioCue cue) => pools[cue]!;

  Future<void> completeCreations() async {
    for (final cue in GameAudioCue.values) {
      while (!_creations.containsKey(cue)) {
        await Future<void>.delayed(Duration.zero);
      }
      final creation = _creations[cue]!;
      if (!creation.isCompleted) creation.complete(pools[cue]);
    }
  }

  Future<void> completeNextCreation() async {
    while (_creations.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    final entry = _creations.entries.first;
    if (!entry.value.isCompleted) entry.value.complete(pools[entry.key]);
  }
}

final class _FakePool implements GameAudioPool {
  int startCount = 0;
  int disposeCount = 0;
  int maximumActive = 0;
  bool failNextStart = false;
  bool delayNextStart = false;
  final List<_FakePlayback> active = [];
  Completer<GameAudioPlayback>? _delayedStart;

  @override
  Future<GameAudioPlayback> start({required double volume}) {
    startCount += 1;
    if (failNextStart) {
      failNextStart = false;
      return Future.error(StateError('start failed'));
    }
    if (delayNextStart) {
      delayNextStart = false;
      _delayedStart = Completer<GameAudioPlayback>();
      return _delayedStart!.future;
    }
    final playback = _FakePlayback();
    active.add(playback);
    final activeCount = active.where((item) => item.stopCount == 0).length;
    maximumActive = activeCount > maximumActive ? activeCount : maximumActive;
    return Future.value(playback);
  }

  _FakePlayback completeDelayedStart() {
    final playback = _FakePlayback();
    active.add(playback);
    final activeCount = active.where((item) => item.stopCount == 0).length;
    maximumActive = activeCount > maximumActive ? activeCount : maximumActive;
    _delayedStart!.complete(playback);
    return playback;
  }

  void completeActive() {
    for (final playback in List<_FakePlayback>.of(active)) {
      playback.complete();
    }
    active.clear();
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }
}

final class _FakePlayback implements GameAudioPlayback {
  final Completer<void> _completion = Completer<void>();
  int stopCount = 0;

  @override
  Future<void> get completed => _completion.future;

  void complete() {
    if (!_completion.isCompleted) _completion.complete();
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
    complete();
  }
}
