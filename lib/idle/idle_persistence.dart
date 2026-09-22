import 'dart:convert';

import 'idle_domain.dart';

abstract interface class IdleStateStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

final class IdleRepository {
  IdleRepository(this.store, [DateTime Function()? clock]) : _clock = clock ?? DateTime.now;

  static const saveKey = 'tokenfront.idle_mode.v1';
  static const _schemaVersion = 1;

  final IdleStateStore store;
  final DateTime Function() _clock;
  IdleState _state = IdleState(lastSettledAt: _epoch);
  Future<void> _writeTail = Future<void>.value();
  Future<void> _operationTail = Future<void>.value();
  bool _initialized = false;

  static final _epoch = DateTime.utc(1970);

  IdleState get state => _state;

  Future<void> initialize() async {
    if (_initialized) return;
    final raw = await store.read(saveKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic> &&
            decoded['version'] == _schemaVersion &&
            decoded['state'] is Map<String, dynamic>) {
          _state = IdleState.fromJson(decoded['state'] as Map<String, dynamic>);
        }
      } on Object {
        // A malformed isolated idle save starts fresh; story/WT are untouched.
      }
    }
    if (_state.lastSettledAt == _epoch) {
      _state = IdleState.initial(_clock().toUtc());
      try {
        await _persist();
      } on Object {
        // Allow a later initialize() call to retry after a transient store
        // failure instead of retaining an unpersisted in-memory timestamp.
        _state = IdleState(lastSettledAt: _epoch);
        rethrow;
      }
    }
    _initialized = true;
  }

  Future<IdleSettlement> claim([DateTime? now]) async {
    late IdleSettlement result;
    _operationTail = _operationTail.then((_) async {
      await initialize();
      final settlement = IdleSimulation.settle(_state, (now ?? _clock()).toUtc());
      if (settlement.elapsed == Duration.zero) {
        result = IdleSettlement(state: _state, elapsed: Duration.zero, creditsEarned: 0);
        return;
      }
      _state = settlement.state;
      await _persist();
      result = settlement;
    });
    await _operationTail;
    return result;
  }

  Future<bool> upgrade() async {
    var upgradedResult = false;
    _operationTail = _operationTail.then((_) async {
      await initialize();
      final upgraded = IdleSimulation.tryBuyUpgrade(_state);
      if (upgraded == null) return;
      _state = upgraded;
      await _persist();
      upgradedResult = true;
    });
    await _operationTail;
    return upgradedResult;
  }

  Future<void> _persist() {
    final payload = jsonEncode(<String, Object>{
      'version': _schemaVersion,
      'state': _state.toJson(),
    });
    _writeTail = _writeTail.then(
      (_) => store.write(saveKey, payload),
      onError: (_) => store.write(saveKey, payload),
    );
    return _writeTail;
  }
}
