import 'dart:async';

import 'game_audio_backend.dart';

export 'game_audio_backend.dart'
    show
        GameAudioBackend,
        GameAudioCue,
        GameAudioCueConfig,
        GameAudioPlayback,
        GameAudioPool;

enum AudioSuspensionReason { lifecycle, fullScreenAd, manualPause }

typedef AudioClock = Duration Function();

/// Bounded, failure-isolated playback for Tokenfront's short local cues.
///
/// Call [initialize] once before gameplay. Calls to [play] are safe before
/// initialization finishes, but are discarded if mute, suspension, or disposal
/// closes the gate while asynchronous work is pending.
final class GameAudioService {
  factory GameAudioService({
    GameAudioBackend backend = const FlameGameAudioBackend(),
    AudioClock? now,
    bool muted = false,
  }) => GameAudioService._(backend, now ?? _stopwatchClock, muted);

  GameAudioService._(this._backend, this._now, this._muted);

  static final Stopwatch _stopwatch = Stopwatch()..start();
  static Duration _stopwatchClock() => _stopwatch.elapsed;

  static const Duration combatThrottle = Duration(milliseconds: 150);

  static const List<GameAudioCueConfig> cueConfigs = [
    GameAudioCueConfig(
      cue: GameAudioCue.dash,
      asset: 'dash.wav',
      volume: .70,
      duration: Duration(milliseconds: 140),
    ),
    GameAudioCueConfig(
      cue: GameAudioCue.combatImpact,
      asset: 'impact.wav',
      volume: .42,
      duration: Duration(milliseconds: 90),
    ),
    GameAudioCueConfig(
      cue: GameAudioCue.commandRelay,
      asset: 'relay.wav',
      volume: .72,
      duration: Duration(milliseconds: 280),
    ),
    GameAudioCueConfig(
      cue: GameAudioCue.recoveryComplete,
      asset: 'relay.wav',
      volume: .72,
      duration: Duration(milliseconds: 280),
    ),
  ];

  final GameAudioBackend _backend;
  final AudioClock _now;
  final Map<GameAudioCue, GameAudioPool> _pools = {};
  final Map<GameAudioCue, GameAudioPlayback> _active = {};
  final Map<GameAudioCue, Future<void>> _cueOperations = {};
  final Set<GameAudioCue> _unavailable = {};
  final Set<AudioSuspensionReason> _suspensions = {};

  Future<void>? _initialization;
  Future<void>? _disposal;
  Duration? _lastCombatStart;
  bool _muted;
  bool _disposed = false;
  int _gateRevision = 0;

  bool get muted => _muted;
  bool get suspended => _suspensions.isNotEmpty;
  bool get disposed => _disposed;
  int get activeVoiceCount => _active.length;
  Set<AudioSuspensionReason> get suspensionReasons =>
      Set.unmodifiable(_suspensions);

  bool isCueAvailable(GameAudioCue cue) =>
      !_unavailable.contains(cue) && (_pools.containsKey(cue) || !_disposed);

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    for (final config in cueConfigs) {
      if (_disposed) return;
      try {
        final pool = await _backend.createPool(config);
        if (_disposed) {
          await _disposePoolSafely(pool);
        } else {
          _pools[config.cue] = pool;
        }
      } on Object {
        _unavailable.add(config.cue);
      }
    }
  }

  Future<void> play(GameAudioCue cue) {
    if (!_gateOpen) return Future.value();
    final requestedRevision = _gateRevision;
    final previous = _cueOperations[cue] ?? Future.value();
    late final Future<void> operation;
    operation = previous.then((_) => _play(cue, requestedRevision)).whenComplete(() {
      if (identical(_cueOperations[cue], operation)) {
        _cueOperations.remove(cue);
      }
    });
    _cueOperations[cue] = operation;
    return operation;
  }

  Future<void> _play(GameAudioCue cue, int requestedRevision) async {
    if (!_gateOpen || requestedRevision != _gateRevision) return;
    await initialize();
    if (!_gateOpen ||
        requestedRevision != _gateRevision ||
        _unavailable.contains(cue)) {
      return;
    }

    final now = _now();
    if (cue == GameAudioCue.combatImpact) {
      final previous = _lastCombatStart;
      if (previous != null && now - previous < combatThrottle) return;
    }
    final pool = _pools[cue];
    if (pool == null) return;

    if (cue == GameAudioCue.combatImpact) _lastCombatStart = now;
    await _stopCue(cue);
    if (!_gateOpen || requestedRevision != _gateRevision) return;
    try {
      final playback = await pool.start(volume: _configFor(cue).volume);
      if (!_gateOpen || requestedRevision != _gateRevision) {
        await _stopPlaybackSafely(playback);
        return;
      }
      _active[cue] = playback;
      unawaited(
        playback.completed.then((_) {
          if (identical(_active[cue], playback)) _active.remove(cue);
        }),
      );
    } on Object {
      // A cue failure is isolated; the caller's gameplay flow always continues.
    }
  }

  Future<void> setMuted(bool muted) async {
    if (_disposed || _muted == muted) return;
    _muted = muted;
    _gateRevision += 1;
    if (muted) await _stopAll();
  }

  Future<void> suspend(AudioSuspensionReason reason) async {
    if (_disposed || !_suspensions.add(reason)) return;
    _gateRevision += 1;
    await _stopAll();
  }

  /// Removes only [reason]. This opens the gate only when no reason or mute
  /// remains, and never replays cues discarded while the gate was closed.
  void resume(AudioSuspensionReason reason) {
    if (_disposed || !_suspensions.remove(reason)) return;
    _gateRevision += 1;
  }

  Future<void> dispose() => _disposal ??= _dispose();

  Future<void> _dispose() async {
    if (_disposed) return;
    _disposed = true;
    _gateRevision += 1;
    await _stopAll();
    await _initialization;
    await Future.wait(_cueOperations.values.toList(growable: false));
    final pools = _pools.values.toList(growable: false);
    _pools.clear();
    await Future.wait(pools.map(_disposePoolSafely));
  }

  bool get _gateOpen => !_disposed && !_muted && _suspensions.isEmpty;

  Future<void> _stopCue(GameAudioCue cue) async {
    final playback = _active.remove(cue);
    if (playback != null) await _stopPlaybackSafely(playback);
  }

  Future<void> _stopAll() async {
    final playbacks = _active.values.toList(growable: false);
    _active.clear();
    await Future.wait(playbacks.map(_stopPlaybackSafely));
  }

  Future<void> _stopPlaybackSafely(GameAudioPlayback playback) async {
    try {
      await playback.stop();
    } on Object {
      // Stop failures cannot be allowed to block lifecycle or ad transitions.
    }
  }

  Future<void> _disposePoolSafely(GameAudioPool pool) async {
    try {
      await pool.dispose();
    } on Object {
      // Disposal remains best-effort because audio is nonessential.
    }
  }

  GameAudioCueConfig _configFor(GameAudioCue cue) =>
      cueConfigs.singleWhere((config) => config.cue == cue);
}
