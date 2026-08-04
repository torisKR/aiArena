import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/app/release_capabilities.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/l10n/l10n.dart';
import 'package:tokenfront/main.dart';
import 'package:tokenfront/services/ads/ad_service.dart';
import 'package:tokenfront/services/privacy/privacy_link_actions.dart';
import 'package:tokenfront/ui/privacy_policy_sheet.dart';
import 'package:tokenfront/ui/result_screen.dart';

final class FakePrivacyLinkActions implements PrivacyLinkActions {
  final List<Uri> opened = <Uri>[];
  final List<String> copied = <String>[];

  @override
  Future<bool> openExternal(Uri uri) async {
    opened.add(uri);
    return true;
  }

  @override
  Future<void> copy(String text) async => copied.add(text);
}

void main() {
  const localeCases = <({String code, String title, String unavailable})>[
    (
      code: 'en',
      title: 'PRIVACY POLICY',
      unavailable: 'NOT AVAILABLE IN THIS RELEASE',
    ),
    (code: 'ko', title: '개인정보처리방침', unavailable: '이 출시 버전에서는 사용할 수 없음'),
    (code: 'ja', title: 'プライバシーポリシー', unavailable: 'このリリースでは利用できません'),
    (code: 'zh', title: '隐私政策', unavailable: '此版本不可用'),
  ];

  for (final localeCase in localeCases) {
    testWidgets('${localeCase.code} settings opens readable current policy', (
      tester,
    ) async {
      final runtime = TokenfrontRuntime()
        ..preferences.setLanguageCode(localeCase.code);
      final actions = FakePrivacyLinkActions();
      addTearDown(runtime.dispose);
      await tester.pumpWidget(
        TokenfrontApp(
          runtime: runtime,
          capabilities: playReleaseCapabilities,
          privacyLinkActions: actions,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      expect(find.text(localeCase.unavailable), findsOneWidget);
      expect(find.byKey(const Key('analytics-sharing-toggle')), findsNothing);
      expect(find.byKey(const Key('ad-requests-toggle')), findsNothing);

      await tester.ensureVisible(
        find.byKey(const Key('privacy-policy-button')),
      );
      await tester.tap(find.byKey(const Key('privacy-policy-button')));
      await tester.pumpAndSettle();
      expect(find.text(localeCase.title), findsWidgets);
      expect(
        find.text(playReleaseCapabilities.privacyPolicyUrl),
        findsOneWidget,
      );
      expect(find.byKey(const Key('privacy-policy-content')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('copy-privacy-url')));
      await tester.tap(find.byKey(const Key('copy-privacy-url')));
      await tester.tap(find.byKey(const Key('open-privacy-url')));
      await tester.pumpAndSettle();
      expect(actions.copied, <String>[
        playReleaseCapabilities.privacyPolicyUrl,
      ]);
      expect(actions.opened, <Uri>[playReleaseCapabilities.privacyPolicyUri]);
    });
  }

  testWidgets('NoOp Play build preserves stored choices without controls', (
    tester,
  ) async {
    final runtime = TokenfrontRuntime()
      ..setAnalyticsSharingAllowed(true)
      ..setAdRequestsAllowed(true);
    addTearDown(runtime.dispose);
    await tester.pumpWidget(
      TokenfrontApp(
        runtime: runtime,
        capabilities: playReleaseCapabilities,
        privacyLinkActions: FakePrivacyLinkActions(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(runtime.analyticsSharingAllowed, isTrue);
    expect(runtime.adRequestsAllowed, isTrue);
    expect(find.byKey(const Key('analytics-sharing-toggle')), findsNothing);
    expect(find.byKey(const Key('ad-requests-toggle')), findsNothing);
    expect(
      find.byKey(const Key('release-services-unavailable')),
      findsOneWidget,
    );
  });

  testWidgets('NoOp Play result hides the rewarded-ad action', (tester) async {
    var doubleRewardCalls = 0;
    const standings = <FactionStanding>[
      FactionStanding(
        faction: Faction.amethyst,
        survivors: 12,
        levelSum: 72,
        kills: 88,
      ),
      FactionStanding(
        faction: Faction.cobalt,
        survivors: 0,
        levelSum: 0,
        kills: 81,
      ),
      FactionStanding(
        faction: Faction.volt,
        survivors: 0,
        levelSum: 0,
        kills: 77,
      ),
      FactionStanding(
        faction: Faction.prism,
        survivors: 0,
        levelSum: 0,
        kills: 66,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ResultScreen(
          result: const MatchResult(
            reason: MatchEndReason.elimination,
            winner: Faction.amethyst,
            standings: standings,
          ),
          matchId: 'release-noop',
          playerFaction: Faction.amethyst,
          relays: 2,
          elapsed: 90,
          baseReward: 40,
          warTokenBalance: 40,
          bannerVisible: false,
          rewardedAdsAvailable: false,
          onDoubleReward: () async {
            doubleRewardCalls += 1;
            return const RewardedClaim(
              adResult: AdResult(AdStatus.unavailable),
              credited: 0,
              alreadyClaimed: false,
            );
          },
          onOpenSettings: () {},
          onOpenLocker: () {},
          onRematch: () {},
          onLobby: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('double-reward-button')), findsNothing);
    expect(find.text('NOT AVAILABLE IN THIS RELEASE'), findsOneWidget);
    expect(doubleRewardCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('policy sheet remains scrollable on a 320px-tall surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showPrivacyPolicySheet(
              context: context,
              capabilities: playReleaseCapabilities,
              linkActions: FakePrivacyLinkActions(),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('privacy-policy-content')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
