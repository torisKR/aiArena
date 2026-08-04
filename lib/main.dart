import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/tokenfront_runtime.dart';
import 'design/tokens.dart';
import 'economy/cosmetic_catalog.dart';
import 'game/faction_visuals.dart';
import 'game/simulation.dart';
import 'game/tokenfront_game.dart';
import 'story/story_models.dart';
import 'story/story_catalog.dart';
import 'l10n/l10n.dart';
import 'services/ads/ad_service.dart';
import 'services/analytics/analytics_event.dart';
import 'services/battle_orientation_controller.dart';
import 'ui/armory_sheet.dart';
import 'ui/battle_screen.dart';
import 'ui/lobby_screen.dart';
import 'ui/result_screen.dart';
import 'ui/settings_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final runtime = await TokenfrontRuntime.restore();
  runApp(TokenfrontApp(runtime: runtime, disposeRuntime: true));
}

class TokenfrontApp extends StatefulWidget {
  const TokenfrontApp({
    super.key,
    this.runtime,
    this.disposeRuntime = false,
    this.orientationController,
    this.storyOperationsProvider,
  });

  final TokenfrontRuntime? runtime;
  final bool disposeRuntime;
  final BattleOrientationController? orientationController;
  final StoryOperationsProvider? storyOperationsProvider;

  @override
  State<TokenfrontApp> createState() => _TokenfrontAppState();
}

class _TokenfrontAppState extends State<TokenfrontApp> {
  late final TokenfrontRuntime runtime = widget.runtime ?? TokenfrontRuntime();
  late final bool ownsRuntime = widget.runtime == null || widget.disposeRuntime;
  late final BattleOrientationController orientationController =
      widget.orientationController ??
      BattleOrientationController(platform: runtime.platform);

  @override
  void dispose() {
    if (ownsRuntime) runtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: runtime,
    builder: (context, _) => MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTokenfrontTheme(),
      locale: TokenfrontLocales.fromLanguageCode(
        runtime.preferences.languageCode,
      ),
      localeListResolutionCallback: TokenfrontLocales.resolve,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TokenfrontRoot(
        runtime: runtime,
        orientationController: orientationController,
        storyOperationsProvider: widget.storyOperationsProvider,
      ),
    ),
  );
}

typedef StoryOperationsProvider = Iterable<StoryOperation> Function();

enum _Screen { lobby, briefing, battle, result }

final class _ActiveBattle {
  const _ActiveBattle({
    required this.mode,
    required this.faction,
    required this.matchId,
    this.operation,
    this.replay = false,
  });

  final GameMode mode;
  final Faction faction;
  final String matchId;
  final StoryOperation? operation;
  final bool replay;
}

class TokenfrontRoot extends StatefulWidget {
  const TokenfrontRoot({
    super.key,
    required this.runtime,
    required this.orientationController,
    this.storyOperationsProvider,
  });

  final TokenfrontRuntime runtime;
  final BattleOrientationController orientationController;
  final StoryOperationsProvider? storyOperationsProvider;

  @override
  State<TokenfrontRoot> createState() => _TokenfrontRootState();
}

class _TokenfrontRootState extends State<TokenfrontRoot>
    with WidgetsBindingObserver {
  _Screen screen = _Screen.lobby;
  Faction selectedFaction = Faction.amethyst;
  late final List<StoryOperation> storyOperations;
  bool chronicleAvailable = true;
  StoryOperation? briefingOperation;
  _ActiveBattle? activeBattle;
  TokenfrontGame? game;
  MatchResult? result;
  int relays = 0;
  double elapsed = 0;
  int matchIndex = 0;
  int completedMatches = 0;
  int attemptNumber = 0;
  int baseReward = 0;
  String currentMatchId = '';
  bool bannerVisible = false;
  bool _startingMatch = false;
  bool _requireLandscapeForBattle = false;

  TokenfrontRuntime get runtime => widget.runtime;

  @override
  void initState() {
    super.initState();
    try {
      storyOperations = List<StoryOperation>.unmodifiable(
        (widget.storyOperationsProvider ?? () => StoryCatalog.operations)(),
      );
      briefingOperation = _currentOperation();
    } on StateError {
      storyOperations = const [];
      chronicleAvailable = false;
    } on FormatException {
      storyOperations = const [];
      chronicleAvailable = false;
    }
    WidgetsBinding.instance.addObserver(this);
    runtime.addListener(_runtimeChanged);
    runtime.record(AnalyticsEvent.tutorialStarted());
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestBanner());
  }

  StoryOperation? _currentOperation() {
    final id = runtime.storyProgress.currentOperation;
    if (id == null) return null;
    try {
      return storyOperations.firstWhere((operation) => operation.id == id);
    } on StateError {
      throw StateError('story operation ${id.name} is unavailable');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    runtime.removeListener(_runtimeChanged);
    unawaited(runtime.flushLocalState());
    runtime.record(AnalyticsEvent.sessionSummary(matchCount: completedMatches));
    runtime.flushAnalytics();
    game?.dispose();
    unawaited(widget.orientationController.restore());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(runtime.flushLocalState());
      runtime.flushAnalytics();
    }
  }

  void _runtimeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _requestBanner() async {
    final surface = screen == _Screen.result
        ? AdSurface.result
        : AdSurface.lobby;
    if (screen == _Screen.battle) return;
    final adResult = await runtime.requestBanner(
      surface: surface,
      completedMatches: completedMatches,
    );
    if (mounted && screen != _Screen.battle) {
      setState(() => bannerVisible = adResult.didShow);
    }
  }

  void _openSettings() {
    showSignalSettings(
      context: context,
      preferences: runtime.preferences,
      analyticsSharingAllowed: runtime.analyticsSharingAllowed,
      adRequestsAllowed: runtime.adRequestsAllowed,
      onAnalyticsChanged: runtime.setAnalyticsSharingAllowed,
      onAdRequestsChanged: runtime.setAdRequestsAllowed,
    );
  }

  void _openLocker() {
    showSignalLocker(
      context: context,
      wallet: runtime.wallet,
      onWalletChanged: runtime.notifyEconomyChanged,
    );
  }

  Future<void> _lockBattleOrientation() async {
    final display = View.of(context).display;
    final logicalShortestSide =
        display.size.shortestSide / display.devicePixelRatio;
    _requireLandscapeForBattle = widget.orientationController.requiresLandscape(
      logicalShortestSide: logicalShortestSide,
    );
    try {
      await widget.orientationController.enterBattle(
        logicalShortestSide: logicalShortestSide,
      );
    } on Object catch (error) {
      debugPrint('Landscape orientation request was denied: $error');
    }
  }

  Future<void> _restoreBattleOrientation() async {
    try {
      await widget.orientationController.restore();
    } on Object catch (error) {
      debugPrint('Orientation restore request was denied: $error');
    }
  }

  Future<void> startMatch(Faction faction) async {
    await _startBattle(
      mode: GameMode.skirmish,
      faction: faction,
      operation: null,
    );
  }

  void _openChronicle() {
    if (!chronicleAvailable || briefingOperation == null) return;
    setState(() => screen = _Screen.briefing);
  }

  Future<void> _startChronicle(Faction faction) async {
    final operation = briefingOperation;
    if (!chronicleAvailable || operation == null) return;
    await _startBattle(
      mode: GameMode.chronicle,
      faction: faction,
      operation: operation,
    );
  }

  Future<void> _startBattle({
    required GameMode mode,
    required Faction faction,
    required StoryOperation? operation,
    bool replay = false,
  }) async {
    if (_startingMatch) return;
    _startingMatch = true;
    await _lockBattleOrientation();
    if (!mounted) {
      await _restoreBattleOrientation();
      _startingMatch = false;
      return;
    }
    final l10n = context.l10n;
    selectedFaction = faction;
    result = null;
    relays = 0;
    elapsed = 0;
    baseReward = 0;
    bannerVisible = false;
    attemptNumber += 1;
    final seed = operation?.seed ?? 20260715 + (++matchIndex);
    currentMatchId = [
      mode.name,
      if (operation != null) operation.id.name,
      'seed-$seed',
      'attempt-$attemptNumber',
    ].join('-');
    activeBattle = _ActiveBattle(
      mode: mode,
      faction: faction,
      matchId: currentMatchId,
      operation: operation,
      replay: replay,
    );
    if (mode == GameMode.chronicle &&
        operation?.id == StoryOperationId.wake &&
        runtime.storyProgress.campaignFaction == null &&
        !replay) {
      runtime.lockChronicleCore(faction);
    }
    selectedFaction = faction;
    runtime.record(
      AnalyticsEvent.factionSelected(faction: faction.visual.name),
    );
    runtime.record(
      AnalyticsEvent.matchStarted(
        matchId: currentMatchId,
        isFirstMatch: completedMatches == 0,
      ),
    );
    late final TokenfrontGame nextGame;
    nextGame = TokenfrontGame(
      playerFaction: faction,
      mode: mode,
      operation: operation,
      seed: seed,
      config: operation == null
          ? const BattleConfig()
          : BattleConfig(
              matchLimitSeconds: operation.duration.inSeconds.toDouble(),
            ),
      reduceMotion: runtime.preferences.reducedMotionFor(
        systemPrefersReducedMotion: MediaQuery.disableAnimationsOf(context),
      ),
      lowSpecMode: runtime.preferences.lowSpecMode,
      mouseCameraEnabled: runtime.preferences.mouseCameraEnabled,
      cosmeticLoadout: CosmeticLoadout.fromWallet(runtime.wallet),
      hapticsEnabled: runtime.preferences.hapticsEnabled,
      audioEnabled: runtime.preferences.audioEnabled,
      combatWinCode: l10n.combatWinCode,
      combatOutCode: l10n.combatOutCode,
      onHandoffStarted: () => runtime.record(AnalyticsEvent.handoffStarted()),
      onHandoffOutcome: (completed) => runtime.record(
        AnalyticsEvent.handoffOutcome(
          outcome: completed
              ? HandoffAnalyticsOutcome.completed
              : HandoffAnalyticsOutcome.skipped,
        ),
      ),
      onBattleConcluded: (report) {
        final matchResult = MatchResult(
          reason: report.endReason == ChronicleEndReason.timeLimit
              ? MatchEndReason.timeLimit
              : MatchEndReason.elimination,
          winner: report.globalWinner,
          standings: report.standingsAtConclusion,
        );
        unawaited(_finishMatch(nextGame, matchResult, report));
      },
    );
    game?.dispose();
    setState(() {
      game = nextGame;
      screen = _Screen.battle;
    });
    _startingMatch = false;
  }

  Future<void> _finishMatch(
    TokenfrontGame endedGame,
    MatchResult matchResult,
    BattleReport report,
  ) async {
    if (!mounted || game != endedGame) return;
    final playerStanding = report.standingsAtConclusion.firstWhere(
      (standing) => standing.faction == selectedFaction,
    );
    final matchElapsed = endedGame.simulation.matchElapsed;
    final reward = 40 + report.commandRelays * 8 + (playerStanding.kills ~/ 5);
    completedMatches += 1;
    runtime.claimBaseReward(matchId: currentMatchId, amount: reward);
    final active = activeBattle;
    final wasFirstOperation =
        active?.mode == GameMode.chronicle &&
        active?.operation?.id == StoryOperationId.wake &&
        !runtime.storyProgress.concludedOperations.contains(
          StoryOperationId.wake,
        );
    if (active?.mode == GameMode.chronicle && active?.operation != null) {
      runtime.concludeChronicle(
        operationId: active!.operation!.id,
        report: report,
        replay: active.replay,
      );
    }
    if (wasFirstOperation) {
      runtime.record(AnalyticsEvent.tutorialCompleted());
    }
    runtime.record(
      AnalyticsEvent.matchCompleted(
        matchId: currentMatchId,
        durationSeconds: matchElapsed,
        isFirstMatch: completedMatches == 1,
        selectedFaction: selectedFaction.visual.name,
        winningFaction: matchResult.winner?.visual.name ?? 'DRAW',
        killCount: playerStanding.kills,
        handoffCount: report.commandRelays,
      ),
    );
    runtime.record(
      AnalyticsEvent.performanceSample(
        platform: runtime.platform.name,
        deviceTier: runtime.preferences.lowSpecMode ? 'low' : 'standard',
        averageFps: endedGame.averageFps,
        onePercentLowFps: endedGame.onePercentLowFps,
      ),
    );
    await _restoreBattleOrientation();
    if (!mounted || game != endedGame) return;
    setState(() {
      result = matchResult;
      relays = report.commandRelays;
      elapsed = matchElapsed;
      baseReward = reward;
      screen = _Screen.result;
    });
    briefingOperation = _currentOperation();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestBanner());
  }

  Future<void> _leaveResult({required bool rematch}) async {
    await runtime.closeResult(completedMatches: completedMatches);
    if (!mounted) return;
    if (rematch) {
      final active = activeBattle;
      await _startBattle(
        mode: active?.mode ?? GameMode.skirmish,
        faction: selectedFaction,
        operation: active?.operation,
        replay: active?.replay ?? false,
      );
      return;
    }
    await _restoreBattleOrientation();
    if (!mounted) return;
    game?.dispose();
    setState(() {
      game = null;
      activeBattle = null;
      screen = _Screen.lobby;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestBanner());
  }

  Future<void> _continueFromResult() async {
    final active = activeBattle;
    if (active?.mode != GameMode.chronicle || active?.operation == null) {
      await _leaveResult(rematch: false);
      return;
    }
    await runtime.closeResult(completedMatches: completedMatches);
    if (!mounted) return;
    briefingOperation = _currentOperation();
    setState(() {
      game = null;
      screen = _Screen.briefing;
    });
  }

  @override
  Widget build(BuildContext context) => switch (screen) {
    _Screen.lobby => LobbyScreen(
      onDeploy: startMatch,
      warTokenBalance: runtime.wallet.balance,
      onOpenSettings: _openSettings,
      onOpenLocker: _openLocker,
      bannerVisible: bannerVisible,
      chronicleAvailable: chronicleAvailable,
      onOpenChronicle: _openChronicle,
    ),
    _Screen.briefing => LobbyScreen(
      onDeploy: startMatch,
      onChronicleDeploy: _startChronicle,
      warTokenBalance: runtime.wallet.balance,
      onOpenSettings: _openSettings,
      onOpenLocker: _openLocker,
      bannerVisible: bannerVisible,
      chronicleAvailable: chronicleAvailable,
      briefing: true,
      currentOperation: briefingOperation,
    ),
    _Screen.battle => BattleScreen(
      game: game!,
      preferences: runtime.preferences,
      requireLandscape: _requireLandscapeForBattle,
    ),
    _Screen.result => ResultScreen(
      result: result!,
      matchId: currentMatchId,
      playerFaction: selectedFaction,
      relays: relays,
      elapsed: elapsed,
      baseReward: baseReward,
      warTokenBalance: runtime.wallet.balance,
      bannerVisible: bannerVisible,
      onDoubleReward: () => runtime.claimRewardedBonus(
        matchId: currentMatchId,
        baseAmount: baseReward,
        completedMatches: completedMatches,
      ),
      onOpenSettings: _openSettings,
      onOpenLocker: _openLocker,
      onRematch: () => _leaveResult(rematch: true),
      onLobby: () => _leaveResult(rematch: false),
      onContinue: activeBattle?.mode == GameMode.chronicle
          ? _continueFromResult
          : null,
    ),
  };
}
