import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/economy/war_token_wallet.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/services/ads/ad_service.dart';
import 'package:tokenfront/services/analytics/analytics_event.dart';
import 'package:tokenfront/services/analytics/analytics_service.dart';
import 'package:tokenfront/services/privacy/privacy_state.dart';
import 'package:tokenfront/story/story_models.dart';

void main() {
  const trackingId = 'tracking-id-must-be-gated';

  PrivacyState privacy({
    ClientPlatform platform = ClientPlatform.android,
    ConsentStatus consent = ConsentStatus.granted,
    TrackingAuthorization tracking = TrackingAuthorization.notApplicable,
  }) => PrivacyState(
    platform: platform,
    consent: consent,
    trackingAuthorization: tracking,
  );

  AdRequestContext adRequest({
    AdSurface surface = AdSurface.result,
    int completedMatches = 2,
    bool isOnline = true,
    PrivacyState? privacyState,
  }) => AdRequestContext(
    surface: surface,
    completedMatches: completedMatches,
    isOnline: isOnline,
    privacy: privacyState ?? privacy(),
    trackingIdentifier: trackingId,
  );

  group('privacy gate', () {
    test('never exposes a tracking identifier before consent and iOS ATT', () {
      final beforeConsent = privacy(
        platform: ClientPlatform.ios,
        consent: ConsentStatus.unknown,
        tracking: TrackingAuthorization.notDetermined,
      );
      final consentOnly = privacy(
        platform: ClientPlatform.ios,
        tracking: TrackingAuthorization.denied,
      );
      final fullyAuthorized = privacy(
        platform: ClientPlatform.ios,
        tracking: TrackingAuthorization.authorized,
      );

      expect(beforeConsent.filterTrackingIdentifier(trackingId), isNull);
      expect(consentOnly.filterTrackingIdentifier(trackingId), isNull);
      expect(fullyAuthorized.filterTrackingIdentifier(trackingId), trackingId);
    });

    test('consent denial always suppresses tracking on every platform', () {
      for (final platform in ClientPlatform.values) {
        final state = privacy(
          platform: platform,
          consent: ConsentStatus.denied,
          tracking: TrackingAuthorization.authorized,
        );
        expect(state.filterTrackingIdentifier(trackingId), isNull);
      }
    });
  });

  test('Chronicle directive credit stays separate from base claim', () {
    final runtime = TokenfrontRuntime(platform: ClientPlatform.web);
    addTearDown(runtime.dispose);
    runtime.lockChronicleCore(Faction.amethyst);
    final report = BattleReport(
      endReason: ChronicleEndReason.playerEliminated,
      standingsAtConclusion: const [
        FactionStanding(
          faction: Faction.amethyst,
          survivors: 0,
          levelSum: 0,
          kills: 0,
        ),
        FactionStanding(
          faction: Faction.cobalt,
          survivors: 2,
          levelSum: 4,
          kills: 1,
        ),
        FactionStanding(
          faction: Faction.volt,
          survivors: 0,
          levelSum: 0,
          kills: 0,
        ),
        FactionStanding(
          faction: Faction.prism,
          survivors: 0,
          levelSum: 0,
          kills: 0,
        ),
      ],
      globalWinner: null,
      commandRelays: 0,
      commandKills: 0,
      longestCommandLinkSeconds: 45,
      playerRank: 4,
      playerSurvivors: 0,
    );

    expect(
      runtime.claimBaseReward(
        matchId: 'chronicle-wake-seed-2026080501-attempt-1',
        amount: 40,
      ),
      40,
    );
    final transition = runtime.concludeChronicle(
      operationId: StoryOperationId.wake,
      report: report,
      replay: false,
    );
    expect(transition.directiveBonusCredit, 15);
    expect(runtime.wallet.balance, 55);
  });

  group('launch-safe advertising policy', () {
    test('banner inventory is limited to lobby and result surfaces', () async {
      final fake = FakeAdService(platform: ClientPlatform.android);
      final service = PolicyAdService(delegate: fake);

      expect(
        (await service.loadBanner(adRequest(surface: AdSurface.lobby))).status,
        AdStatus.shown,
      );
      expect(
        (await service.loadBanner(adRequest(surface: AdSurface.result))).status,
        AdStatus.shown,
      );
      expect(
        (await service.loadBanner(adRequest(surface: AdSurface.battle))).status,
        AdStatus.skippedPolicy,
      );
      expect(
        (await service.loadBanner(
          adRequest(surface: AdSurface.handoff),
        )).status,
        AdStatus.skippedPolicy,
      );

      expect(
        fake.calls.where((call) => call.format == AdFormat.banner),
        hasLength(2),
      );
    });

    test('battle and handoff suppress every interrupting ad', () async {
      final fake = FakeAdService(platform: ClientPlatform.android);
      final service = PolicyAdService(delegate: fake);

      final battleInterstitial = await service.showInterstitial(
        adRequest(surface: AdSurface.battle),
      );
      final handoffRewarded = await service.showRewarded(
        adRequest(surface: AdSurface.handoff),
      );

      expect(battleInterstitial.status, AdStatus.skippedPolicy);
      expect(handoffRewarded.status, AdStatus.skippedPolicy);
      expect(fake.calls, isEmpty);
    });

    test(
      'interstitial runs only after result close and at most every 2 matches',
      () async {
        final fake = FakeAdService(platform: ClientPlatform.web);
        final service = PolicyAdService(delegate: fake);

        expect(
          (await service.showInterstitial(
            adRequest(surface: AdSurface.resultClosed, completedMatches: 1),
          )).status,
          AdStatus.skippedFrequency,
        );
        expect(
          (await service.showInterstitial(
            adRequest(surface: AdSurface.result, completedMatches: 2),
          )).status,
          AdStatus.skippedPolicy,
        );
        expect(
          (await service.showInterstitial(
            adRequest(surface: AdSurface.resultClosed, completedMatches: 2),
          )).status,
          AdStatus.shown,
        );
        expect(
          (await service.showInterstitial(
            adRequest(surface: AdSurface.resultClosed, completedMatches: 2),
          )).status,
          AdStatus.skippedFrequency,
        );
        expect(
          (await service.showInterstitial(
            adRequest(surface: AdSurface.resultClosed, completedMatches: 3),
          )).status,
          AdStatus.skippedFrequency,
        );
        expect(
          (await service.showInterstitial(
            adRequest(surface: AdSurface.resultClosed, completedMatches: 4),
          )).status,
          AdStatus.shown,
        );

        expect(
          fake.calls.where((call) => call.format == AdFormat.interstitial),
          hasLength(2),
        );
      },
    );

    test(
      'rewarded inventory is result-only and reports earned reward',
      () async {
        final fake = FakeAdService(platform: ClientPlatform.ios);
        final service = PolicyAdService(delegate: fake);

        final result = await service.showRewarded(
          adRequest(surface: AdSurface.result),
        );
        final closedResult = await service.showRewarded(
          adRequest(surface: AdSurface.resultClosed),
        );

        expect(result.status, AdStatus.rewardEarned);
        expect(result.rewardEarned, isTrue);
        expect(closedResult.status, AdStatus.skippedPolicy);
      },
    );

    test(
      'offline and consent-denied ads skip without touching adapter',
      () async {
        final fake = FakeAdService(platform: ClientPlatform.android);
        final service = PolicyAdService(delegate: fake);

        final offline = await service.showRewarded(adRequest(isOnline: false));
        final denied = await service.loadBanner(
          adRequest(
            surface: AdSurface.lobby,
            privacyState: privacy(consent: ConsentStatus.denied),
          ),
        );

        expect(offline.status, AdStatus.skippedOffline);
        expect(denied.status, AdStatus.skippedConsent);
        expect(fake.calls, isEmpty);
      },
    );

    test(
      'adapter failures are values and never escape into match flow',
      () async {
        final fake = FakeAdService(
          platform: ClientPlatform.android,
          throwingFormats: const {AdFormat.rewarded},
        );
        final service = PolicyAdService(delegate: fake);

        final result = await service.showRewarded(adRequest());

        expect(result.status, AdStatus.failed);
        expect(result.rewardEarned, isFalse);
      },
    );

    test(
      'ATT denial still permits non-tracking ads with a null identifier',
      () async {
        final fake = FakeAdService(platform: ClientPlatform.ios);
        final service = PolicyAdService(delegate: fake);

        await service.loadBanner(
          adRequest(
            surface: AdSurface.lobby,
            privacyState: privacy(
              platform: ClientPlatform.ios,
              tracking: TrackingAuthorization.denied,
            ),
          ),
        );
        await service.loadBanner(
          adRequest(
            surface: AdSurface.result,
            privacyState: privacy(
              platform: ClientPlatform.ios,
              tracking: TrackingAuthorization.authorized,
            ),
          ),
        );

        expect(fake.calls[0].request.trackingIdentifier, isNull);
        expect(fake.calls[0].request.isPersonalized, isFalse);
        expect(fake.calls[1].request.trackingIdentifier, trackingId);
        expect(fake.calls[1].request.isPersonalized, isTrue);
      },
    );

    test(
      'NoOp adapter is always available as a non-throwing fallback',
      () async {
        final service = NoOpAdService(platform: ClientPlatform.other);

        expect(
          (await service.showInterstitial(adRequest())).status,
          AdStatus.unavailable,
        );
        expect(
          (await service.showRewarded(adRequest())).status,
          AdStatus.unavailable,
        );
        expect(
          (await service.loadBanner(adRequest())).status,
          AdStatus.unavailable,
        );
      },
    );
  });

  group('War Token economy', () {
    test('completed rewarded result doubles the base War Token grant', () {
      final wallet = WarTokenWallet(initialBalance: 10);

      final normal = wallet.creditMatchReward(
        baseAmount: 20,
        rewardedAdCompleted: false,
      );
      final doubled = wallet.creditMatchReward(
        baseAmount: 20,
        rewardedAdCompleted: true,
      );

      expect(normal, 20);
      expect(doubled, 40);
      expect(wallet.balance, 70);
    });

    test('failed or skipped rewarded ad preserves the base reward', () {
      final wallet = WarTokenWallet();

      final credited = wallet.creditMatchReward(
        baseAmount: 25,
        rewardedAdCompleted: false,
      );

      expect(credited, 25);
      expect(wallet.balance, 25);
    });

    test('wallet spending surface can unlock cosmetics only', () {
      final wallet = WarTokenWallet(initialBalance: 50);
      const trail = CosmeticItem(
        id: 'cobalt_signal_trail',
        category: CosmeticCategory.movementTrail,
        cost: 30,
      );
      const expensiveEffect = CosmeticItem(
        id: 'prism_shatter',
        category: CosmeticCategory.deathEffect,
        cost: 100,
      );

      expect(wallet.unlock(trail), CosmeticUnlockResult.unlocked);
      expect(wallet.balance, 20);
      expect(wallet.isUnlocked(trail.id), isTrue);
      expect(wallet.unlock(trail), CosmeticUnlockResult.alreadyUnlocked);
      expect(wallet.balance, 20);
      expect(
        wallet.unlock(expensiveEffect),
        CosmeticUnlockResult.insufficientFunds,
      );
      expect(wallet.balance, 20);
    });
  });

  group('analytics schema and local buffer', () {
    final now = DateTime.utc(2026, 7, 15, 12);

    test('typed event factories cover every required launch metric', () {
      final events = <AnalyticsEvent>[
        AnalyticsEvent.tutorialStarted(occurredAt: now),
        AnalyticsEvent.tutorialCompleted(occurredAt: now),
        AnalyticsEvent.factionSelected(faction: 'cobalt', occurredAt: now),
        AnalyticsEvent.matchStarted(
          matchId: 'match-1',
          isFirstMatch: true,
          occurredAt: now,
        ),
        AnalyticsEvent.matchCompleted(
          matchId: 'match-1',
          durationSeconds: 91.5,
          isFirstMatch: true,
          selectedFaction: 'cobalt',
          winningFaction: 'prism',
          killCount: 7,
          handoffCount: 2,
          occurredAt: now,
        ),
        AnalyticsEvent.sessionSummary(matchCount: 2, occurredAt: now),
        AnalyticsEvent.retentionCheckpoint(day: 1, occurredAt: now),
        AnalyticsEvent.unitLifecycle(
          level: 7,
          survivalSeconds: 34.2,
          killContribution: 3,
          occurredAt: now,
        ),
        AnalyticsEvent.handoffStarted(occurredAt: now),
        AnalyticsEvent.handoffOutcome(
          outcome: HandoffAnalyticsOutcome.skipped,
          occurredAt: now,
        ),
        AnalyticsEvent.adEvent(
          format: AnalyticsAdFormat.interstitial,
          action: AnalyticsAdAction.impression,
          occurredAt: now,
        ),
        AnalyticsEvent.performanceSample(
          platform: 'android',
          deviceTier: 'mid',
          averageFps: 58.0,
          onePercentLowFps: 35.0,
          occurredAt: now,
        ),
      ];

      expect(
        events.map((event) => event.name).toSet(),
        containsAll(<String>{
          'tutorial_started',
          'tutorial_completed',
          'faction_selected',
          'match_started',
          'match_completed',
          'session_summary',
          'retention_checkpoint',
          'unit_lifecycle',
          'handoff_started',
          'handoff_outcome',
          'ad_event',
          'performance_sample',
        }),
      );
      expect(events[4].parameters['duration_seconds'], 91.5);
      expect(events[4].parameters['is_first_match'], isTrue);
      expect(events.last.parameters['one_percent_low_fps'], 35.0);
    });

    test('retention schema accepts only D1 and D7 checkpoints', () {
      expect(
        () => AnalyticsEvent.retentionCheckpoint(day: 2),
        throwsArgumentError,
      );
      expect(AnalyticsEvent.retentionCheckpoint(day: 7).parameters['day'], 7);
    });

    test(
      'offline flush keeps local events and does not call adapter',
      () async {
        final adapter = FakeAnalyticsAdapter();
        final service = AnalyticsService(adapter: adapter);
        service.record(
          AnalyticsEvent.tutorialCompleted(occurredAt: now),
          privacy: privacy(),
          trackingIdentifier: trackingId,
        );

        final result = await service.flush(isOnline: false, privacy: privacy());

        expect(result.status, AnalyticsFlushStatus.skippedOffline);
        expect(service.pendingCount, 1);
        expect(adapter.batches, isEmpty);
      },
    );

    test(
      'consent denial keeps local events and never blocks the caller',
      () async {
        final adapter = FakeAnalyticsAdapter();
        final service = AnalyticsService(adapter: adapter);
        final denied = privacy(consent: ConsentStatus.denied);
        service.record(
          AnalyticsEvent.sessionSummary(matchCount: 1, occurredAt: now),
          privacy: denied,
          trackingIdentifier: trackingId,
        );

        final result = await service.flush(isOnline: true, privacy: denied);

        expect(result.status, AnalyticsFlushStatus.skippedConsent);
        expect(service.pendingCount, 1);
        expect(adapter.batches, isEmpty);
        expect(service.pendingEvents.single.trackingIdentifier, isNull);
      },
    );

    test('adapter failure retains the batch instead of throwing', () async {
      final adapter = FakeAnalyticsAdapter(shouldFail: true);
      final service = AnalyticsService(adapter: adapter);
      service.record(
        AnalyticsEvent.matchStarted(matchId: 'match-2', occurredAt: now),
        privacy: privacy(),
      );

      final result = await service.flush(isOnline: true, privacy: privacy());

      expect(result.status, AnalyticsFlushStatus.failed);
      expect(service.pendingCount, 1);
    });

    test(
      'successful flush clears only sent events and applies ATT gate',
      () async {
        final adapter = FakeAnalyticsAdapter();
        final service = AnalyticsService(adapter: adapter);
        final attDenied = privacy(
          platform: ClientPlatform.ios,
          tracking: TrackingAuthorization.denied,
        );
        service.record(
          AnalyticsEvent.performanceSample(
            platform: 'ios',
            deviceTier: 'high',
            averageFps: 60,
            onePercentLowFps: 46,
            occurredAt: now,
          ),
          privacy: attDenied,
          trackingIdentifier: trackingId,
        );

        final result = await service.flush(isOnline: true, privacy: attDenied);

        expect(result.status, AnalyticsFlushStatus.sent);
        expect(result.sentCount, 1);
        expect(service.pendingCount, 0);
        expect(adapter.batches.single.single.trackingIdentifier, isNull);
      },
    );

    test('buffer is bounded and drops the oldest event first', () {
      final service = AnalyticsService(
        adapter: NoOpAnalyticsAdapter(),
        maxBufferSize: 2,
      );
      service.record(
        AnalyticsEvent.tutorialStarted(occurredAt: now),
        privacy: privacy(),
      );
      service.record(
        AnalyticsEvent.tutorialCompleted(occurredAt: now),
        privacy: privacy(),
      );
      service.record(
        AnalyticsEvent.sessionSummary(matchCount: 1, occurredAt: now),
        privacy: privacy(),
      );

      expect(service.pendingCount, 2);
      expect(service.pendingEvents.map((envelope) => envelope.event.name), [
        'tutorial_completed',
        'session_summary',
      ]);
    });
  });
}
