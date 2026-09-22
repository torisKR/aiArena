import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/idle/idle_domain.dart';
import 'package:tokenfront/idle/idle_persistence.dart';

void main() {
  test('settlement is deterministic, capped, and advances stages', () {
    final initial = IdleState.initial(DateTime.utc(2026, 1, 1));
    final settled = IdleSimulation.settle(
      initial,
      DateTime.utc(2026, 1, 1, 0, 0, 20),
    );

    expect(settled.elapsed, const Duration(seconds: 20));
    expect(settled.credits, 50);
    expect(settled.state.stage, 2);
    expect(settled.state.coreLevel, 1);
    expect(settled.state.progress, 0);

    final capped = IdleSimulation.settle(
      initial,
      DateTime.utc(2026, 1, 2),
    );
    expect(capped.elapsed, IdleSimulation.offlineCap);
    expect(capped.state.lastSettledAt, initial.lastSettledAt.add(IdleSimulation.offlineCap));
  });

  test('upgrade has documented cost and changes future combat rate', () {
    final state = IdleState.initial(DateTime.utc(2026, 1, 1)).copyWith(credits: 100);
    expect(IdleSimulation.upgradeCost(state.coreLevel), 50);
    final upgraded = IdleSimulation.buyUpgrade(state);
    expect(upgraded.coreLevel, 2);
    expect(upgraded.credits, 50);
    expect(IdleSimulation.progressPerSecond(upgraded), 2);
  });

  test('clock rollback does not create negative offline progress', () {
    final initial = IdleState.initial(DateTime.utc(2026, 1, 1));
    final settled = IdleSimulation.settle(
      initial,
      DateTime.utc(2025, 12, 31),
    );
    expect(settled.elapsed, Duration.zero);
    expect(settled.state, initial);
  });

  test('repository claim is idempotent for repeated calls', () async {
    final store = MemoryIdleStateStore();
    final repository = IdleRepository(store, () => DateTime.utc(2026, 1, 1));
    await repository.initialize();

    final now = DateTime.utc(2026, 1, 1, 0, 0, 20);
    final first = await repository.claim(now);
    final second = await repository.claim(now);

    expect(first.creditsEarned, 50);
    expect(second.creditsEarned, 0);
    expect(second.state, first.state);
    expect(store.writeCount, 2); // initialization + one settled snapshot
  });

  test('repository persists idle state under its own versioned key', () async {
    final store = MemoryIdleStateStore();
    final repository = IdleRepository(store, () => DateTime.utc(2026, 1, 1));
    await repository.initialize();
    await repository.claim(DateTime.utc(2026, 1, 1, 0, 0, 5));

    final restored = IdleRepository(store, () => DateTime.utc(2026, 1, 1));
    await restored.initialize();
    expect(restored.state.lastSettledAt, DateTime.utc(2026, 1, 1, 0, 0, 5));
    expect(restored.state.stage, 1);
    expect(store.key, IdleRepository.saveKey);
  });

  test('a transient storage failure does not poison later idle operations', () async {
    final store = FlakyIdleStateStore()..failNextWrite = true;
    final repository = IdleRepository(store, () => DateTime.utc(2026, 1, 1));
    await expectLater(repository.initialize(), throwsA(isA<StateError>()));

    await repository.initialize();
    final settlement = await repository.claim(DateTime.utc(2026, 1, 1, 0, 0, 5));

    expect(settlement.creditsEarned, 12);
    expect(repository.state.credits, 12);
  });
}

final class FlakyIdleStateStore implements IdleStateStore {
  bool failNextWrite = false;
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('storage unavailable');
    }
    this.value = value;
  }
}

final class MemoryIdleStateStore implements IdleStateStore {
  String? value;
  String? key;
  int writeCount = 0;

  @override
  Future<String?> read(String key) async {
    this.key = key;
    return value;
  }

  @override
  Future<void> write(String key, String value) async {
    this.key = key;
    this.value = value;
    writeCount++;
  }
}
