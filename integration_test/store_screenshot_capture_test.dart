import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/src/game/game_render_box.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/design/tokens.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/game/tokenfront_game.dart';
import 'package:tokenfront/l10n/l10n.dart';
import 'package:tokenfront/main.dart';
import 'package:tokenfront/settings/game_preferences.dart';
import 'package:tokenfront/story/story_catalog.dart';
import 'package:tokenfront/story/story_models.dart';
import 'package:tokenfront/ui/battle_screen.dart';
import 'package:tokenfront/ui/result_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('captures five truthful Play Store phone screens', (
    tester,
  ) async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    addTearDown(
      () => SystemChrome.setPreferredOrientations(DeviceOrientation.values),
    );
    await tester.pump(const Duration(seconds: 1));
    final campaignRuntime = TokenfrontRuntime(
      preferences: GamePreferences(audioEnabled: false, hapticsEnabled: false),
    );
    addTearDown(campaignRuntime.dispose);

    await tester.pumpWidget(TokenfrontApp(runtime: campaignRuntime));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('COMMAND DECK'), findsOneWidget);
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await binding.takeScreenshot('phone-01-command-deck-1920x1080');

    final deploy = find.byKey(const Key('chronicle-deploy'));
    await tester.ensureVisible(deploy);
    await tester.tap(deploy);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(BattleScreen), findsOneWidget);
    expect(find.byKey(const Key('directive-rail')), findsOneWidget);
    await binding.takeScreenshot('phone-02-live-directive-1920x1080');

    final battle = tester.widget<BattleScreen>(find.byType(BattleScreen));
    final controlled = battle.game.simulation.controlledUnit!;
    controlled
      ..alive = false
      ..state = AiState.dead;
    battle.game.update(.12);
    for (var tick = 0; tick < 15; tick++) {
      battle.game.update(.05);
    }
    expect(battle.game.handoffStage, HandoffStage.successorScan);
    expect(battle.game.hud.value.handoffStage, HandoffStage.successorScan);
    await tester.pump();
    expect(battle.game.hud.value.handoffProgress, isNotNull);
    // Stop only Flame's test-render loop so the genuine handoff HUD can paint
    // without the BattleScreen's user-facing paused overlay.
    final gameRenderBox = tester.allElements
        .map((element) => element.renderObject)
        .whereType<GameRenderBox>()
        .single;
    gameRenderBox.gameLoop!.stop();
    gameRenderBox.markNeedsPaint();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(battle.game.paused, isFalse);
    await binding.takeScreenshot('phone-03-command-handoff-1920x1080');

    final transition = campaignRuntime.concludeChronicle(
      operationId: StoryOperationId.wake,
      report: _successfulReport(),
      replay: false,
    );
    await tester.pumpWidget(
      _screenApp(
        ResultScreen(
          result: MatchResult(
            reason: MatchEndReason.timeLimit,
            winner: Faction.amethyst,
            standings: _successfulReport().standingsAtConclusion,
          ),
          matchId: 'chronicle-wake-seed-2026080501-attempt-1',
          playerFaction: Faction.amethyst,
          relays: 2,
          elapsed: 180,
          baseReward: 40,
          warTokenBalance: campaignRuntime.wallet.balance,
          bannerVisible: false,
          rewardedAdsAvailable: false,
          onDoubleReward: () => campaignRuntime.claimRewardedBonus(
            matchId: 'chronicle-wake-seed-2026080501-attempt-1',
            baseAmount: 40,
            completedMatches: 1,
          ),
          onOpenSettings: () {},
          onOpenLocker: () {},
          onRematch: () {},
          onLobby: () {},
          onContinue: () {},
          operation: StoryCatalog.byId(StoryOperationId.wake),
          campaignTransition: transition,
          storyProgress: campaignRuntime.storyProgress,
          rewardLedger: campaignRuntime.rewardLedger,
        ),
      ),
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('chronicle-debrief')), findsOneWidget);
    expect(find.byKey(const Key('chronicle-action-layer')), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('result-scroll')),
      const Offset(0, -110),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await binding.takeScreenshot('phone-04-chronicle-debrief-1920x1080');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final archiveRuntime = TokenfrontRuntime(
      preferences: GamePreferences(audioEnabled: false, hapticsEnabled: false),
    );
    addTearDown(archiveRuntime.dispose);
    _completeChronicle(archiveRuntime);
    await tester.pumpWidget(TokenfrontApp(runtime: archiveRuntime));
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    await tester.pump(const Duration(seconds: 1));
    final archive = find.byKey(const Key('archive-action'));
    await tester.ensureVisible(archive);
    await tester.tap(archive);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('ARCHIVE'), findsWidgets);
    final archiveScroll = tester.state<ScrollableState>(
      find.byType(Scrollable).last,
    );
    archiveScroll.position.jumpTo(28);
    await tester.pump(const Duration(milliseconds: 250));
    await binding.takeScreenshot('phone-05-archive-1920x1080');
  });
}

void _completeChronicle(TokenfrontRuntime runtime) {
  runtime.lockChronicleCore(Faction.amethyst);
  for (final operation in StoryOperationId.values) {
    runtime.concludeChronicle(
      operationId: operation,
      report: _successfulReport(),
      replay: false,
    );
  }
  runtime.chooseChronicleEnding(EndingChoice.openRelay);
}

BattleReport _successfulReport() => BattleReport(
  endReason: ChronicleEndReason.timeLimit,
  standingsAtConclusion: [
    FactionStanding(
      faction: Faction.amethyst,
      survivors: 84,
      levelSum: 240,
      kills: 36,
    ),
    FactionStanding(
      faction: Faction.cobalt,
      survivors: 53,
      levelSum: 150,
      kills: 22,
    ),
    FactionStanding(
      faction: Faction.volt,
      survivors: 31,
      levelSum: 90,
      kills: 16,
    ),
    FactionStanding(
      faction: Faction.prism,
      survivors: 12,
      levelSum: 48,
      kills: 9,
    ),
  ],
  globalWinner: Faction.amethyst,
  commandRelays: 2,
  commandKills: 3,
  longestCommandLinkSeconds: 45,
  playerRank: 1,
  playerSurvivors: 84,
);

Widget _screenApp(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: buildTokenfrontTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);
