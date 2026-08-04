import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/app/tokenfront_state_store.dart';
import 'package:tokenfront/economy/cosmetic_catalog.dart';
import 'package:tokenfront/economy/war_token_wallet.dart';
import 'package:tokenfront/services/ads/ad_service.dart';
import 'package:tokenfront/services/analytics/analytics_event.dart';
import 'package:tokenfront/services/analytics/analytics_service.dart';
import 'package:tokenfront/services/privacy/privacy_state.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/story/story_models.dart';

List<String> _adActions(TokenfrontRuntime runtime, AnalyticsAdFormat format) =>
    runtime.analytics.pendingEvents
        .where(
          (envelope) =>
              envelope.event.name == 'ad_event' &&
              envelope.event.parameters['format'] == format.name,
        )
        .map((envelope) => envelope.event.parameters['action']! as String)
        .toList(growable: false);

final class _MemoryStateStore implements TokenfrontStateStore {
  _MemoryStateStore();

  _MemoryStateStore.withValue(this.value);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;

  Future<void> waitForValue(bool Function(String value) predicate) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      final current = value;
      if (current != null && predicate(current)) return;
      await Future<void>.delayed(Duration.zero);
    }
    throw TestFailure('Expected persisted state was not written.');
  }
}

final class _FailFirstReadStateStore implements TokenfrontStateStore {
  _FailFirstReadStateStore(this.value);

  String? value;
  int readCalls = 0;
  int writeCalls = 0;

  @override
  Future<String?> read() async {
    readCalls += 1;
    if (readCalls == 1) throw StateError('temporary read failure');
    return value;
  }

  @override
  Future<void> write(String value) async {
    writeCalls += 1;
    this.value = value;
  }
}

final class _FailFirstWriteStateStore implements TokenfrontStateStore {
  String? value;
  int writeCalls = 0;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    writeCalls += 1;
    if (writeCalls == 1) throw StateError('temporary write failure');
    this.value = value;
  }

  Future<void> waitForWrite() async {
    for (var attempt = 0; attempt < 100; attempt++) {
      if (value != null) return;
      await Future<void>.delayed(Duration.zero);
    }
    throw TestFailure('Expected a retried write to succeed.');
  }
}

final class _AlwaysFailReadStateStore implements TokenfrontStateStore {
  int readCalls = 0;
  int writeCalls = 0;

  @override
  Future<String?> read() async {
    readCalls += 1;
    throw StateError('persistent read failure');
  }

  @override
  Future<void> write(String value) async {
    writeCalls += 1;
  }
}

void main() {
  test(
    'schema 1 migrates wallet preferences privacy and empty story',
    () async {
      final store = _MemoryStateStore()..value = schema1Fixture;
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      addTearDown(runtime.dispose);
      expect(runtime.wallet.balance, 275);
      expect(
        runtime.wallet.unlockedIds,
        containsAll(<String>[
          'color_relay_ivory',
          'trail_relay_tape',
          'death_fracture',
        ]),
      );
      expect(
        runtime.wallet.equippedId(CosmeticCategory.factionColor),
        'color_relay_ivory',
      );
      expect(
        runtime.wallet.equippedId(CosmeticCategory.movementTrail),
        'trail_relay_tape',
      );
      expect(
        runtime.wallet.equippedId(CosmeticCategory.deathEffect),
        'death_fracture',
      );
      expect(runtime.preferences.lowSpecMode, isTrue);
      expect(runtime.preferences.forceReducedMotion, isTrue);
      expect(runtime.preferences.mouseCameraEnabled, isFalse);
      expect(runtime.preferences.hapticsEnabled, isFalse);
      expect(runtime.preferences.audioEnabled, isFalse);
      expect(runtime.preferences.languageCode, 'ko');
      expect(runtime.analyticsSharingAllowed, isTrue);
      expect(runtime.adRequestsAllowed, isTrue);
      expect(runtime.storyProgress, StoryProgress.initial());
      expect(runtime.rewardLedger.claimedDirectiveBonusIds, isEmpty);
    },
  );

  test('conclusion atomically stores medal claim and WT once', () async {
    final store = _MemoryStateStore();
    final runtime = await TokenfrontRuntime.restore(
      platform: ClientPlatform.web,
      stateStore: store,
    );
    addTearDown(runtime.dispose);
    runtime.lockChronicleCore(Faction.amethyst);
    final before = runtime.wallet.balance;
    final first = runtime.concludeChronicle(
      operationId: StoryOperationId.wake,
      report: _report(link: 45),
      replay: false,
    );
    final duplicate = runtime.concludeChronicle(
      operationId: StoryOperationId.wake,
      report: _report(link: 45),
      replay: true,
    );
    await runtime.flushLocalState();
    expect(first.directiveBonusCredit, 15);
    expect(duplicate.directiveBonusCredit, 0);
    expect(runtime.wallet.balance, before + 15);
    expect(runtime.storyProgress.medals, contains(StoryOperationId.wake));
    expect(
      runtime.rewardLedger.claimedDirectiveBonusIds,
      contains('chronicle-directive-wake'),
    );
  });

  test(
    'successful replay mastery credits and persists a missing directive bonus',
    () async {
      final store = _MemoryStateStore();
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      addTearDown(runtime.dispose);
      runtime.lockChronicleCore(Faction.amethyst);
      final before = runtime.wallet.balance;
      final first = runtime.concludeChronicle(
        operationId: StoryOperationId.wake,
        report: _report(link: 44.999),
        replay: false,
      );
      final replay = runtime.concludeChronicle(
        operationId: StoryOperationId.wake,
        report: _report(link: 45),
        replay: true,
      );
      await runtime.flushLocalState();
      expect(first.directiveBonusCredit, 0);
      expect(replay.directiveBonusCredit, 15);
      expect(runtime.wallet.balance, before + 15);
      expect(runtime.storyProgress.currentOperation, StoryOperationId.echo);
      expect(runtime.storyProgress.medals, contains(StoryOperationId.wake));
      expect(
        runtime.rewardLedger.claimedDirectiveBonusIds,
        contains('chronicle-directive-wake'),
      );
      final restored = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      addTearDown(restored.dispose);
      expect(restored.wallet.balance, before + 15);
      expect(restored.storyProgress.medals, contains(StoryOperationId.wake));
      expect(
        restored.rewardLedger.claimedDirectiveBonusIds,
        contains('chronicle-directive-wake'),
      );
    },
  );

  test(
    'malformed story preserves a separately valid lifetime ledger',
    () async {
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: _MemoryStateStore.withValue(
          schema2WithMalformedStoryAndWakeClaim,
        ),
      );
      addTearDown(runtime.dispose);
      _expectNonDefaultPersistedSections(runtime);
      expect(runtime.storyProgress.currentOperation, StoryOperationId.wake);
      expect(
        runtime.rewardLedger.claimedDirectiveBonusIds,
        contains('chronicle-directive-wake'),
      );
    },
  );

  test(
    'malformed ledger preserves separately valid Chronicle progress',
    () async {
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: _MemoryStateStore.withValue(
          schema2WithWakeConcludedAndMalformedLedger,
        ),
      );
      addTearDown(runtime.dispose);
      _expectNonDefaultPersistedSections(runtime);
      expect(
        runtime.storyProgress.concludedOperations,
        contains(StoryOperationId.wake),
      );
      expect(runtime.storyProgress.currentOperation, StoryOperationId.echo);
      expect(runtime.rewardLedger.claimedDirectiveBonusIds, isEmpty);
    },
  );

  test(
    'unknown top-level schema keeps the existing corruption fallback',
    () async {
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: _MemoryStateStore.withValue(schema99Fixture),
      );
      addTearDown(runtime.dispose);
      expect(runtime.wallet.balance, 0);
      expect(runtime.wallet.isUnlocked('color_relay_ivory'), isFalse);
      expect(runtime.preferences.languageCode, 'system');
      expect(runtime.preferences.lowSpecMode, isFalse);
      expect(runtime.preferences.forceReducedMotion, isFalse);
      expect(runtime.preferences.mouseCameraEnabled, isTrue);
      expect(runtime.preferences.hapticsEnabled, isTrue);
      expect(runtime.preferences.audioEnabled, isTrue);
      expect(runtime.analyticsSharingAllowed, isFalse);
      expect(runtime.adRequestsAllowed, isFalse);
      expect(runtime.storyProgress, StoryProgress.initial());
      expect(runtime.rewardLedger, ProfileRewardLedger.empty());
    },
  );

  test('schema 2 round trip restores campaign and reward ledger', () async {
    final store = _MemoryStateStore();
    final runtime = await TokenfrontRuntime.restore(
      platform: ClientPlatform.web,
      stateStore: store,
    );
    final reports = <StoryOperationId, BattleReport>{
      StoryOperationId.wake: _report(link: 45),
      StoryOperationId.echo: _report(relays: 2),
      StoryOperationId.split: _report(commandKills: 3),
      StoryOperationId.crown: _report(rank: 2),
      StoryOperationId.lastInstruction: _report(winner: Faction.amethyst),
    };
    runtime.lockChronicleCore(Faction.amethyst);
    for (final operation in StoryOperationId.values) {
      runtime.concludeChronicle(
        operationId: operation,
        report: reports[operation]!,
        replay: false,
      );
    }
    runtime.chooseChronicleEnding(EndingChoice.openRelay);
    await runtime.flushLocalState();
    final restored = await TokenfrontRuntime.restore(
      platform: ClientPlatform.web,
      stateStore: store,
    );
    addTearDown(restored.dispose);
    expect(restored.storyProgress.campaignFaction, Faction.amethyst);
    expect(
      restored.storyProgress.concludedOperations,
      orderedEquals(StoryOperationId.values),
    );
    expect(
      restored.storyProgress.medals,
      orderedEquals(StoryOperationId.values),
    );
    expect(
      restored.storyProgress.recoveredTransmissions,
      orderedEquals(StoryOperationId.values),
    );
    expect(restored.storyProgress.ending, EndingChoice.openRelay);
    expect(
      restored.rewardLedger.claimedDirectiveBonusIds,
      containsAll(<String>[
        'chronicle-directive-wake',
        'chronicle-directive-echo',
        'chronicle-directive-split',
        'chronicle-directive-crown',
        'chronicle-directive-lastInstruction',
      ]),
    );
  });

  test('flush and recreate restores the first incomplete operation', () async {
    final store = _MemoryStateStore();
    final runtime = await TokenfrontRuntime.restore(
      platform: ClientPlatform.web,
      stateStore: store,
    );
    runtime.lockChronicleCore(Faction.amethyst);
    runtime.concludeChronicle(
      operationId: StoryOperationId.wake,
      report: _report(link: 45),
      replay: false,
    );
    await runtime.flushLocalState();
    runtime.dispose();

    final restored = await TokenfrontRuntime.restore(
      platform: ClientPlatform.web,
      stateStore: store,
    );
    addTearDown(restored.dispose);
    expect(restored.storyProgress.currentOperation, StoryOperationId.echo);
    expect(
      restored.storyProgress.concludedOperations,
      contains(StoryOperationId.wake),
    );
  });

  test(
    'restart preserves lifetime medal claim without a second credit',
    () async {
      final store = _MemoryStateStore();
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      runtime.preferences
        ..setLanguageCode('ko')
        ..setMouseCameraEnabled(false);
      runtime.wallet.creditMatchReward(
        baseAmount: 100,
        rewardedAdCompleted: false,
      );
      final cosmetic = CosmeticCatalog.byId('color_relay_ivory').item;
      expect(runtime.wallet.unlock(cosmetic), CosmeticUnlockResult.unlocked);
      expect(runtime.wallet.equip(cosmetic), CosmeticEquipResult.equipped);
      runtime.lockChronicleCore(Faction.amethyst);
      runtime.concludeChronicle(
        operationId: StoryOperationId.wake,
        report: _report(link: 45),
        replay: false,
      );
      runtime.restartChronicle();
      runtime.lockChronicleCore(Faction.amethyst);
      final second = runtime.concludeChronicle(
        operationId: StoryOperationId.wake,
        report: _report(link: 45),
        replay: false,
      );
      await runtime.flushLocalState();
      runtime.dispose();

      final restored = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      addTearDown(restored.dispose);
      expect(second.directiveBonusCredit, 0);
      expect(restored.wallet.balance, 25);
      expect(restored.storyProgress.medals, contains(StoryOperationId.wake));
      expect(
        restored.rewardLedger.claimedDirectiveBonusIds,
        contains('chronicle-directive-wake'),
      );
      expect(restored.preferences.languageCode, 'ko');
      expect(restored.preferences.mouseCameraEnabled, isFalse);
      expect(restored.wallet.isUnlocked('color_relay_ivory'), isTrue);
      expect(
        restored.wallet.equippedId(CosmeticCategory.factionColor),
        'color_relay_ivory',
      );
    },
  );

  test('default runtime is offline-safe and consent starts off', () async {
    final runtime = TokenfrontRuntime(
      platform: ClientPlatform.web,
      isOnline: false,
    );

    expect(runtime.analyticsSharingAllowed, isFalse);
    expect(runtime.adRequestsAllowed, isFalse);
    expect(runtime.adPrivacy.hasConsent, isFalse);
    runtime.record(AnalyticsEvent.factionSelected(faction: 'Amethyst'));
    expect(runtime.analytics.pendingCount, 1);
    expect(
      (await runtime.flushAnalytics()).status,
      AnalyticsFlushStatus.skippedOffline,
    );
  });

  test('iOS tracking starts undetermined and no identifier can pass', () {
    final runtime = TokenfrontRuntime(platform: ClientPlatform.ios)
      ..setAdRequestsAllowed(true);

    expect(runtime.trackingAuthorization, TrackingAuthorization.notDetermined);
    expect(runtime.adPrivacy.canUseTrackingIdentifier, isFalse);
    expect(runtime.adPrivacy.filterTrackingIdentifier('device-id'), isNull);
  });

  test(
    'eligible interstitial records impression, dismissal, and result exit',
    () async {
      final runtime =
          TokenfrontRuntime(
              platform: ClientPlatform.web,
              adAdapter: FakeAdService(platform: ClientPlatform.web),
            )
            ..setAnalyticsSharingAllowed(true)
            ..setAdRequestsAllowed(true);
      addTearDown(runtime.dispose);

      final result = await runtime.closeResult(completedMatches: 2);

      expect(result.status, AdStatus.shown);
      expect(_adActions(runtime, AnalyticsAdFormat.interstitial), <String>[
        AnalyticsAdAction.eligible.name,
        AnalyticsAdAction.impression.name,
        AnalyticsAdAction.dismissed.name,
        AnalyticsAdAction.resultExitAfterImpression.name,
      ]);
    },
  );

  test('frequency-blocked interstitial is not reported as eligible', () async {
    final runtime =
        TokenfrontRuntime(
            platform: ClientPlatform.web,
            adAdapter: FakeAdService(platform: ClientPlatform.web),
          )
          ..setAnalyticsSharingAllowed(true)
          ..setAdRequestsAllowed(true);
    addTearDown(runtime.dispose);

    final result = await runtime.closeResult(completedMatches: 1);

    expect(result.status, AdStatus.skippedFrequency);
    expect(_adActions(runtime, AnalyticsAdFormat.interstitial), isEmpty);
  });

  test(
    'eligible interstitial failure records eligibility and failure',
    () async {
      final runtime =
          TokenfrontRuntime(
              platform: ClientPlatform.android,
              adAdapter: FakeAdService(
                platform: ClientPlatform.android,
                throwingFormats: const <AdFormat>{AdFormat.interstitial},
              ),
            )
            ..setAnalyticsSharingAllowed(true)
            ..setAdRequestsAllowed(true);
      addTearDown(runtime.dispose);

      final result = await runtime.closeResult(completedMatches: 2);

      expect(result.status, AdStatus.failed);
      expect(_adActions(runtime, AnalyticsAdFormat.interstitial), <String>[
        AnalyticsAdAction.eligible.name,
        AnalyticsAdAction.failed.name,
      ]);
    },
  );

  test('analytics denial keeps ad lifecycle events local and unsent', () async {
    final analyticsAdapter = FakeAnalyticsAdapter();
    final runtime = TokenfrontRuntime(
      platform: ClientPlatform.ios,
      adAdapter: FakeAdService(platform: ClientPlatform.ios),
      analyticsAdapter: analyticsAdapter,
    )..setAdRequestsAllowed(true);
    addTearDown(runtime.dispose);

    await runtime.closeResult(completedMatches: 2);
    final flush = await runtime.flushAnalytics();

    expect(flush.status, AnalyticsFlushStatus.skippedConsent);
    expect(analyticsAdapter.batches, isEmpty);
    expect(
      runtime.analytics.pendingEvents,
      everyElement(
        isA<AnalyticsEnvelope>().having(
          (envelope) => envelope.trackingIdentifier,
          'trackingIdentifier',
          isNull,
        ),
      ),
    );
    expect(_adActions(runtime, AnalyticsAdFormat.interstitial), <String>[
      AnalyticsAdAction.eligible.name,
      AnalyticsAdAction.impression.name,
      AnalyticsAdAction.dismissed.name,
      AnalyticsAdAction.resultExitAfterImpression.name,
    ]);
  });

  test('base and rewarded rewards are idempotent per match', () async {
    final adapter = FakeAdService(platform: ClientPlatform.web);
    final runtime = TokenfrontRuntime(
      platform: ClientPlatform.web,
      adAdapter: adapter,
    )..setAdRequestsAllowed(true);

    expect(runtime.claimBaseReward(matchId: 'm1', amount: 40), 40);
    expect(runtime.claimBaseReward(matchId: 'm1', amount: 40), 0);
    final first = await runtime.claimRewardedBonus(
      matchId: 'm1',
      baseAmount: 40,
      completedMatches: 1,
    );
    final second = await runtime.claimRewardedBonus(
      matchId: 'm1',
      baseAmount: 40,
      completedMatches: 1,
    );

    expect(first.earned, isTrue);
    expect(second.alreadyClaimed, isTrue);
    expect(runtime.wallet.balance, 80);
    expect(_adActions(runtime, AnalyticsAdFormat.rewarded), <String>[
      AnalyticsAdAction.rewardOptIn.name,
      AnalyticsAdAction.rewardEarned.name,
    ]);
  });

  test(
    'runtime restores wallet preferences and privacy choices after recreation',
    () async {
      final store = _MemoryStateStore();
      final first = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      first.preferences
        ..setLowSpecMode(true)
        ..setForceReducedMotion(true)
        ..setMouseCameraEnabled(false)
        ..setHapticsEnabled(false)
        ..setAudioEnabled(false);
      first
        ..setAnalyticsSharingAllowed(true)
        ..setAdRequestsAllowed(true)
        ..claimBaseReward(matchId: 'persisted-match', amount: 220);
      final trail = CosmeticCatalog.byId('trail_relay_tape').item;
      expect(first.wallet.unlock(trail), CosmeticUnlockResult.unlocked);
      expect(first.wallet.equip(trail), CosmeticEquipResult.equipped);
      first.notifyEconomyChanged();
      await store.waitForValue(
        (value) =>
            value.contains('"balance":110') &&
            value.contains('"trail_relay_tape"') &&
            value.contains('"audioEnabled":false') &&
            value.contains('"analyticsSharingAllowed":true'),
      );
      first.dispose();

      final restored = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      addTearDown(restored.dispose);

      expect(restored.wallet.balance, 110);
      expect(restored.wallet.isUnlocked('trail_relay_tape'), isTrue);
      expect(
        restored.wallet.equippedId(CosmeticCategory.movementTrail),
        'trail_relay_tape',
      );
      expect(restored.preferences.lowSpecMode, isTrue);
      expect(restored.preferences.forceReducedMotion, isTrue);
      expect(restored.preferences.mouseCameraEnabled, isFalse);
      expect(restored.preferences.hapticsEnabled, isFalse);
      expect(restored.preferences.audioEnabled, isFalse);
      expect(restored.analyticsSharingAllowed, isTrue);
      expect(restored.adRequestsAllowed, isTrue);
    },
  );

  test(
    'preference changes schedule persistence without lifecycle flush',
    () async {
      final store = _MemoryStateStore();
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      runtime.preferences.setAudioEnabled(false);

      await store.waitForValue(
        (value) => value.contains('"audioEnabled":false'),
      );
      runtime.dispose();

      final restored = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      addTearDown(restored.dispose);
      expect(restored.preferences.audioEnabled, isFalse);
    },
  );

  test(
    'base reward schedules wallet persistence without lifecycle flush',
    () async {
      final store = _MemoryStateStore();
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );

      runtime.claimBaseReward(matchId: 'wallet-auto-save', amount: 82);
      await store.waitForValue((value) => value.contains('"balance":82'));
      runtime.dispose();

      final restored = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      addTearDown(restored.dispose);
      expect(restored.wallet.balance, 82);
    },
  );

  test(
    'privacy choices schedule persistence without lifecycle flush',
    () async {
      final store = _MemoryStateStore();
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      runtime
        ..setAnalyticsSharingAllowed(true)
        ..setAdRequestsAllowed(true);

      await store.waitForValue(
        (value) =>
            value.contains('"analyticsSharingAllowed":true') &&
            value.contains('"adRequestsAllowed":true'),
      );
      runtime.dispose();

      final restored = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      addTearDown(restored.dispose);
      expect(restored.analyticsSharingAllowed, isTrue);
      expect(restored.adRequestsAllowed, isTrue);
    },
  );

  test('a transient read failure is retried before using defaults', () async {
    final store = _FailFirstReadStateStore(
      '{"version":1,"wallet":{"balance":82},'
      '"preferences":{"lowSpecMode":true},'
      '"privacy":{"analyticsSharingAllowed":true}}',
    );

    final runtime = await TokenfrontRuntime.restore(
      platform: ClientPlatform.web,
      stateStore: store,
    );
    addTearDown(runtime.dispose);

    expect(store.readCalls, 2);
    expect(runtime.wallet.balance, 82);
    expect(runtime.preferences.lowSpecMode, isTrue);
    expect(runtime.analyticsSharingAllowed, isTrue);
  });

  test(
    'a transient write failure is retried without another mutation',
    () async {
      final store = _FailFirstWriteStateStore();
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      addTearDown(runtime.dispose);

      runtime.preferences.setAudioEnabled(false);
      await store.waitForWrite();

      expect(store.writeCalls, 2);
      expect(store.value, contains('"audioEnabled":false'));
    },
  );

  test(
    'persistent read failure cannot overwrite unknown saved state',
    () async {
      final store = _AlwaysFailReadStateStore();
      final runtime = await TokenfrontRuntime.restore(
        platform: ClientPlatform.web,
        stateStore: store,
      );
      addTearDown(runtime.dispose);

      runtime.preferences.setAudioEnabled(false);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(store.readCalls, 2);
      expect(store.writeCalls, 0);
    },
  );

  test(
    'a failed rewarded adapter never changes the guaranteed reward',
    () async {
      final runtime = TokenfrontRuntime(
        platform: ClientPlatform.android,
        adAdapter: FakeAdService(
          platform: ClientPlatform.android,
          throwingFormats: const {AdFormat.rewarded},
        ),
      )..setAdRequestsAllowed(true);
      runtime.claimBaseReward(matchId: 'm2', amount: 55);

      final result = await runtime.claimRewardedBonus(
        matchId: 'm2',
        baseAmount: 55,
        completedMatches: 2,
      );

      expect(result.adResult.status, AdStatus.failed);
      expect(runtime.wallet.balance, 55);
      expect(_adActions(runtime, AnalyticsAdFormat.rewarded), <String>[
        AnalyticsAdAction.rewardOptIn.name,
        AnalyticsAdAction.failed.name,
      ]);
    },
  );
}

const schema1Fixture =
    '''{"version":1,"wallet":{"balance":275,"unlockedIds":["color_relay_ivory","trail_relay_tape","death_fracture"],"equippedIds":{"factionColor":"color_relay_ivory","movementTrail":"trail_relay_tape","deathEffect":"death_fracture"}},"preferences":{"lowSpecMode":true,"forceReducedMotion":true,"mouseCameraEnabled":false,"hapticsEnabled":false,"audioEnabled":false,"languageCode":"ko"},"privacy":{"analyticsSharingAllowed":true,"adRequestsAllowed":true}}''';

const schema2WithMalformedStoryAndWakeClaim =
    '''{"version":2,"wallet":{"balance":275,"unlockedIds":["color_relay_ivory","trail_relay_tape","death_fracture"],"equippedIds":{"factionColor":"color_relay_ivory","movementTrail":"trail_relay_tape","deathEffect":"death_fracture"}},"preferences":{"lowSpecMode":true,"forceReducedMotion":true,"mouseCameraEnabled":false,"hapticsEnabled":false,"audioEnabled":false,"languageCode":"ko"},"privacy":{"analyticsSharingAllowed":true,"adRequestsAllowed":true},"story":"malformed","rewardLedger":{"claimedDirectiveBonusIds":["chronicle-directive-wake"]}}''';

const schema2WithWakeConcludedAndMalformedLedger =
    '''{"version":2,"wallet":{"balance":275,"unlockedIds":["color_relay_ivory","trail_relay_tape","death_fracture"],"equippedIds":{"factionColor":"color_relay_ivory","movementTrail":"trail_relay_tape","deathEffect":"death_fracture"}},"preferences":{"lowSpecMode":true,"forceReducedMotion":true,"mouseCameraEnabled":false,"hapticsEnabled":false,"audioEnabled":false,"languageCode":"ko"},"privacy":{"analyticsSharingAllowed":true,"adRequestsAllowed":true},"story":{"campaignFaction":"amethyst","concludedOperations":["wake"],"medals":[],"recoveredTransmissions":["wake"],"ending":null},"rewardLedger":[]}''';

const schema99Fixture =
    '''{"version":99,"wallet":{"balance":275,"unlockedIds":["color_relay_ivory"]},"preferences":{"languageCode":"ko","lowSpecMode":true},"privacy":{"analyticsSharingAllowed":true,"adRequestsAllowed":true},"story":{"campaignFaction":"amethyst"},"rewardLedger":{"claimedDirectiveBonusIds":["chronicle-directive-wake"]}}''';

void _expectNonDefaultPersistedSections(TokenfrontRuntime runtime) {
  expect(runtime.wallet.balance, 275);
  expect(
    runtime.wallet.unlockedIds,
    containsAll(<String>[
      'color_relay_ivory',
      'trail_relay_tape',
      'death_fracture',
    ]),
  );
  expect(
    runtime.wallet.equippedId(CosmeticCategory.factionColor),
    'color_relay_ivory',
  );
  expect(
    runtime.wallet.equippedId(CosmeticCategory.movementTrail),
    'trail_relay_tape',
  );
  expect(
    runtime.wallet.equippedId(CosmeticCategory.deathEffect),
    'death_fracture',
  );
  expect(runtime.preferences.lowSpecMode, isTrue);
  expect(runtime.preferences.forceReducedMotion, isTrue);
  expect(runtime.preferences.mouseCameraEnabled, isFalse);
  expect(runtime.preferences.hapticsEnabled, isFalse);
  expect(runtime.preferences.audioEnabled, isFalse);
  expect(runtime.preferences.languageCode, 'ko');
  expect(runtime.analyticsSharingAllowed, isTrue);
  expect(runtime.adRequestsAllowed, isTrue);
}

BattleReport _report({
  ChronicleEndReason reason = ChronicleEndReason.timeLimit,
  Faction? winner,
  int relays = 0,
  int commandKills = 0,
  double link = 0,
  int rank = 4,
}) => BattleReport(
  endReason: reason,
  standingsAtConclusion: const [
    FactionStanding(
      faction: Faction.amethyst,
      survivors: 0,
      levelSum: 0,
      kills: 0,
    ),
    FactionStanding(
      faction: Faction.cobalt,
      survivors: 0,
      levelSum: 0,
      kills: 0,
    ),
    FactionStanding(faction: Faction.volt, survivors: 0, levelSum: 0, kills: 0),
    FactionStanding(
      faction: Faction.prism,
      survivors: 0,
      levelSum: 0,
      kills: 0,
    ),
  ],
  globalWinner: winner,
  commandRelays: relays,
  commandKills: commandKills,
  longestCommandLinkSeconds: link,
  playerRank: rank,
  playerSurvivors: 0,
);
