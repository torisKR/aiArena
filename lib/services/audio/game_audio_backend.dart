import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

abstract interface class GameAudioBackend {
  Future<GameAudioPool> createPool(GameAudioCueConfig config);
}

abstract interface class GameAudioPool {
  Future<GameAudioPlayback> start({required double volume});
  Future<void> dispose();
}

abstract interface class GameAudioPlayback {
  Future<void> get completed;
  Future<void> stop();
}

final class FlameGameAudioBackend implements GameAudioBackend {
  const FlameGameAudioBackend();

  @override
  Future<GameAudioPool> createPool(GameAudioCueConfig config) async {
    final pool = await FlameAudio.createPool(
      config.asset,
      minPlayers: config.minVoices,
      maxPlayers: config.maxVoices,
    );
    return _FlameGameAudioPool(pool, config.duration);
  }
}

final class _FlameGameAudioPool implements GameAudioPool {
  const _FlameGameAudioPool(this._pool, this._duration);

  final AudioPool _pool;
  final Duration _duration;

  @override
  Future<GameAudioPlayback> start({required double volume}) async {
    final stop = await _pool.start(volume: volume);
    return _FlameGameAudioPlayback(stop, _duration);
  }

  @override
  Future<void> dispose() => _pool.dispose();
}

final class _FlameGameAudioPlayback implements GameAudioPlayback {
  _FlameGameAudioPlayback(this._stop, Duration duration) {
    _timer = Timer(duration, _complete);
  }

  final StopFunction _stop;
  final Completer<void> _completed = Completer<void>();
  late final Timer _timer;
  Future<void>? _stopping;

  @override
  Future<void> get completed => _completed.future;

  void _complete() {
    if (!_completed.isCompleted) _completed.complete();
  }

  @override
  Future<void> stop() => _stopping ??= _stopSafely();

  Future<void> _stopSafely() async {
    _timer.cancel();
    try {
      await _stop();
    } on Object {
      // Playback is optional presentation and must never affect gameplay.
    } finally {
      _complete();
    }
  }
}

enum GameAudioCue { dash, combatImpact, commandRelay, recoveryComplete }

final class GameAudioCueConfig {
  const GameAudioCueConfig({
    required this.cue,
    required this.asset,
    required this.volume,
    required this.duration,
    this.minVoices = 1,
    this.maxVoices = 1,
  });

  final GameAudioCue cue;
  final String asset;
  final double volume;
  final Duration duration;
  final int minVoices;
  final int maxVoices;
}
