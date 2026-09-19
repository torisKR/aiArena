import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/release_capabilities.dart';
import 'app/tokenfront_runtime.dart';
import 'design/tokens.dart';
import 'economy/cosmetic_catalog.dart';
import 'game/faction_visuals.dart';
import 'game/simulation.dart';
import 'game/recovery.dart';
import 'game/tokenfront_game.dart';
import 'story/story_models.dart';
import 'story/campaign_controller.dart';
import 'story/story_catalog.dart';
import 'l10n/l10n.dart';
import 'services/ads/ad_service.dart';
import 'services/audio/game_audio_service.dart';
import 'services/ads/admob_ad_service.dart';
import 'services/analytics/analytics_event.dart';
import 'services/battle_orientation_controller.dart';
import 'services/privacy/privacy_link_actions.dart';
import 'services/privacy/privacy_state.dart';
import 'ui/armory_sheet.dart';
import 'ui/archive_sheet.dart';
import 'ui/battle_screen.dart';
import 'ui/lobby_screen.dart';
import 'ui/operation_briefing_screen.dart';
import 'ui/result_screen.dart';
import 'ui/settings_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final adService = AdMobAdService();
  final runtime = await TokenfrontRuntime.restore(
    platform: ClientPlatform.android,
    adAdapter: adService,
  );
  runApp(
    TokenfrontApp(
      runtime: runtime,
      disposeRuntime: true,
      capabilities: androidAdMobTestCapabilities,
    ),
  );
}

class TokenfrontApp extends StatefulWidget {
  const TokenfrontApp({
    super.key,
    this.runtime,
    this.disposeRuntime = false,
    this.orientationController,
    this.storyOperationsProvider,
    this.capabilities = playReleaseCapabilities,
    this.privacyLinkActions = const PlatformPrivacyLinkActions(),
  });

  final TokenfrontRuntime? runtime;
  final bool disposeRuntime;
  final BattleOrientationController? orientationController;
  final StoryOperationsProvider? storyOperationsProvider;
  final ReleaseCapabilities capabilities;
  final PrivacyLinkActions privacyLinkActions;

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
        capabilities: widget.capabilities,
        privacyLinkActions: widget.privacyLinkActions,
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
    this.relayRoute,
    this.replay = false,
  });

  final GameMode mode;
  final Faction faction;
  final String matchId;
  final StoryOperation? operation;
  final RelayRoute? relayRoute;
  final bool replay;
}

class TokenfrontRoot extends StatefulWidget {
  const TokenfrontRoot({
    super.key,
    required this.runtime,
    required this.orientationController,
    this.storyOperationsProvider,
    required this.capabilities,
    required this.privacyLinkActions,
  });

  final TokenfrontRuntime runtime;
  final BattleOrientationController orientationController;
  final StoryOperationsProvider? storyOperationsProvider;
  final ReleaseCapabilities capabilities;
  final PrivacyLinkActions privacyLinkActions;

  @override
  State<TokenfrontRoot> createState() => _TokenfrontRootState();
}

class _TokenfrontRootState extends State<TokenfrontRoot>
    with WidgetsBindingObserver {
  _Screen screen = _Screen.lobby;
  Faction selectedFaction = Faction.amethyst;
  Faction chronicleFaction = Faction.amethyst;
  Faction skirmishFaction = Faction.amethyst;
  late final List<StoryOperation> storyOperations;
  bool chronicleAvailable = true;
  StoryOperation? briefingOperation;
  RelayRoute? briefingRoute;
  _ActiveBattle? activeBattle;
  TokenfrontGame? game;
  MatchResult? result;
  int relays = 0;
  double elapsed = 0;
  int matchIndex = 0;
  int completedMatches = 0;
  int attemptNumber = 0;
  int baseReward = 0;
  int manualRelays = 0;
  RelayRoute? reportRoute;
  CampaignTransition? campaignTransition;
  String currentMatchId = '';
  bool bannerVisible = false;
  bool _startingMatch = false;
  bool _leavingResult = false;
  RecoveryOutcome? recoveryOutcome;
  int recoveredSignals = 0;
  bool _requireLandscapeForBattle = false;
  int _battleRequest = 0;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  final GlobalKey<BattleScreenState> _battleScreenKey =
      GlobalKey<BattleScreenState>();

  TokenfrontRuntime get runtime => widget.runtime;

  @override
  void initState() {
    super.initState();
    unawaited(runtime.audio.initialize());
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
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
    _syncAudioLifecycle(_lifecycleState);
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

  StoryOperation? _resolveCurrentOperation() {
    try {
      return _currentOperation();
    } on StateError {
      chronicleAvailable = false;
      briefingOperation = null;
      return null;
    } on FormatException {
      chronicleAvailable = false;
      briefingOperation = null;
      return null;
    }
  }

  @override
  void dispose() {
    _battleRequest += 1;
    WidgetsBinding.instance.removeObserver(this);
    runtime.removeListener(_runtimeChanged);
    unawaited(runtime.flushLocalState());
    runtime.record(AnalyticsEvent.sessionSummary(matchCount: completedMatches));
    runtime.flushAnalytics();
    unawaited(widget.orientationController.restore());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _syncAudioLifecycle(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(runtime.flushLocalState());
      runtime.flushAnalytics();
    }
    if (mounted) {
      setState(() => _lifecycleState = state);
      _battleScreenKey.currentState?.handleLifecycleState(state);
    }
  }

  void _runtimeChanged() {
    if (mounted) setState(() {});
  }

  void _syncAudioLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      runtime.audio.resume(AudioSuspensionReason.lifecycle);
    } else {
      unawaited(runtime.audio.suspend(AudioSuspensionReason.lifecycle));
    }
  }

  Future<void> _requestBanner() async {
    if (!widget.capabilities.adInventoryAvailable) {
      if (mounted && bannerVisible) setState(() => bannerVisible = false);
      return;
    }
    if (!runtime.adRequestsAllowed) {
      runtime.ads.clearBanner();
      if (mounted && bannerVisible) setState(() => bannerVisible = false);
      return;
    }
    if (screen != _Screen.lobby && screen != _Screen.result) return;
    final surface = screen == _Screen.result
        ? AdSurface.result
        : AdSurface.lobby;
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
      onAdRequestsChanged: (allowed) {
        runtime.setAdRequestsAllowed(allowed);
        if (!allowed) setState(() => bannerVisible = false);
        if (allowed) unawaited(_requestBanner());
      },
      capabilities: widget.capabilities,
      privacyLinkActions: widget.privacyLinkActions,
      onShowPrivacyOptions: widget.capabilities.adInventoryAvailable
          ? () async {
              final allowed = await runtime.showPrivacyOptions();
              if (mounted && !allowed) setState(() => bannerVisible = false);
              return allowed;
            }
          : null,
    );
  }

  void _openLocker() {
    showSignalLocker(
      context: context,
      wallet: runtime.wallet,
      onWalletChanged: runtime.notifyEconomyChanged,
    );
  }

  void _openArchive() {
    showSignalArchive(
      context: context,
      storyProgress: runtime.storyProgress,
      rewardLedger: runtime.rewardLedger,
      onRestart: () {
        runtime.restartChronicle();
        setState(() {
          briefingOperation = _resolveCurrentOperation();
          briefingRoute = null;
          screen = _Screen.lobby;
          selectedFaction = Faction.amethyst;
          chronicleFaction = Faction.amethyst;
          skirmishFaction = Faction.amethyst;
        });
      },
      onReplay: (operationId) => _startChronicleReplay(operationId),
    );
  }

  Future<void> _lockBattleOrientation(int request) async {
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
      if (!mounted || request != _battleRequest) return;
    } on Object catch (error) {
      debugPrint('Landscape orientation request was denied: $error');
    }
  }

  Future<void> _restoreBattleOrientation({TokenfrontGame? activeGame}) async {
    if (!mounted || (activeGame != null && game != activeGame)) return;
    try {
      await widget.orientationController.restore();
      if (!mounted || (activeGame != null && game != activeGame)) return;
    } on Object catch (error) {
      debugPrint('Orientation restore request was denied: $error');
    }
  }

  Future<void> startMatch(Faction faction) async {
    await _startBattle(
      mode: GameMode.skirmish,
      faction: faction,
      operation: null,
      relayRoute: null,
    );
  }

  Future<void> _startChronicleReplay(StoryOperationId operationId) async {
    StoryOperation operation;
    try {
      operation = storyOperations.firstWhere(
        (candidate) => candidate.id == operationId,
      );
    } on StateError {
      return;
    }
    await _startBattle(
      mode: GameMode.chronicle,
      faction: runtime.storyProgress.campaignFaction ?? selectedFaction,
      operation: operation,
      replay: true,
      relayRoute:
          runtime.storyProgress.signalRoutes[operationId] ??
          RelayRoute.preserve,
    );
  }

  Future<void> _openChronicleBriefing() async {
    final operation = _resolveCurrentOperation();
    if (!chronicleAvailable || operation == null) return;
    briefingOperation = operation;
    await _startChronicle(chronicleFaction);
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

  Future<void> _deployChronicle() {
    return _startChronicle(chronicleFaction);
  }

  Future<void> _deploySkirmish() => startMatch(skirmishFaction);

  Future<void> _startBattle({
    required GameMode mode,
    required Faction faction,
    required StoryOperation? operation,
    RelayRoute? relayRoute,
    bool replay = false,
  }) async {
    if (_startingMatch) return;
    _startingMatch = true;
    final request = ++_battleRequest;
    await _lockBattleOrientation(request);
    if (!mounted || request != _battleRequest) {
      if (mounted) await _restoreBattleOrientation();
      _startingMatch = false;
      return;
    }
    final l10n = context.l10n;
    if (mode == GameMode.chronicle &&
        operation?.id == StoryOperationId.wake &&
        runtime.storyProgress.campaignFaction == null &&
        !replay) {
      runtime.lockChronicleCore(faction);
    }
    final battleFaction = mode == GameMode.chronicle
        ? runtime.storyProgress.campaignFaction ?? faction
        : faction;
    selectedFaction = battleFaction;
    result = null;
    recoveryOutcome = null;
    recoveredSignals = 0;
    relays = 0;
    elapsed = 0;
    baseReward = 0;
    manualRelays = 0;
    reportRoute = null;
    campaignTransition = null;
    bannerVisible = false;
    runtime.ads.clearBanner();
    attemptNumber += 1;
    final displayCycle = replay ? 1 : runtime.storyProgress.displayCycle;
    final seed = operation == null
        ? 20260715 + (++matchIndex)
        : replay
        ? operation.seed
        : operation.seed + (displayCycle - 1) * 1000;
    currentMatchId = [
      mode.name,
      if (operation != null) operation.id.name,
      'seed-$seed',
      'attempt-$attemptNumber',
    ].join('-');
    activeBattle = _ActiveBattle(
      mode: mode,
      faction: battleFaction,
      matchId: currentMatchId,
      operation: operation,
      relayRoute: mode == GameMode.chronicle ? relayRoute : null,
      replay: replay,
    );
    runtime.record(
      AnalyticsEvent.factionSelected(faction: battleFaction.visual.name),
    );
    runtime.record(
      AnalyticsEvent.matchStarted(
        matchId: currentMatchId,
        isFirstMatch: completedMatches == 0,
      ),
    );
    late final TokenfrontGame nextGame;
    nextGame = TokenfrontGame(
      playerFaction: battleFaction,
      mode: mode,
      operation: operation,
      recoveryMode: mode == GameMode.chronicle,
      relayRoute: mode == GameMode.chronicle ? relayRoute : null,
      seed: seed,
      config: operation == null
          ? const BattleConfig()
          : replay
          ? RecoveryState.config
          : RecoveryState.configForCycle(displayCycle),
      reduceMotion: runtime.preferences.reducedMotionFor(
        systemPrefersReducedMotion: MediaQuery.disableAnimationsOf(context),
      ),
      lowSpecMode: runtime.preferences.lowSpecMode,
      mouseCameraEnabled: runtime.preferences.mouseCameraEnabled,
      cosmeticLoadout: CosmeticLoadout.fromWallet(runtime.wallet),
      hapticsEnabled: runtime.preferences.hapticsEnabled,
      audioEnabled: runtime.preferences.audioEnabled,
      audio: runtime.audio,
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
          reason: report.recoveryOutcome != null
              ? MatchEndReason.recovery
              : report.endReason == ChronicleEndReason.timeLimit
              ? MatchEndReason.timeLimit
              : MatchEndReason.elimination,
          winner: report.globalWinner,
          standings: report.standingsAtConclusion,
        );
        unawaited(_finishMatch(nextGame, matchResult, report));
      },
    );
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
    final campaignReport = report.recoveryOutcome == RecoveryOutcome.recovered
        ? report.withRecoveryElapsed(matchElapsed)
        : report;
    final playedCycle =
        (activeBattle?.replay ?? false) || runtime.storyProgress.ending == null
        ? 1
        : runtime.storyProgress.displayCycle;
    final reward = campaignReport.recoveryOutcome != null
        ? RecoveryRules.matchReward(
            cycle: playedCycle,
            succeeded:
                campaignReport.recoveryOutcome == RecoveryOutcome.recovered,
            recoveredCount: campaignReport.recoveredSignals,
          )
        : 40 + campaignReport.casualtyRelays * 8 + (playerStanding.kills ~/ 5);
    completedMatches += 1;
    runtime.claimBaseReward(matchId: currentMatchId, amount: reward);
    final active = activeBattle;
    final wasFirstOperation =
        active?.mode == GameMode.chronicle &&
        active?.operation?.id == StoryOperationId.wake &&
        !runtime.storyProgress.concludedOperations.contains(
          StoryOperationId.wake,
        );
    CampaignTransition? transition;
    if (active?.mode == GameMode.chronicle && active?.operation != null) {
      transition = runtime.concludeChronicle(
        operationId: active!.operation!.id,
        report: campaignReport,
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
    await _restoreBattleOrientation(activeGame: endedGame);
    if (!mounted || game != endedGame) return;
    setState(() {
      game = null;
      result = matchResult;
      recoveryOutcome = campaignReport.recoveryOutcome;
      recoveredSignals = campaignReport.recoveredSignals;
      relays = campaignReport.commandRelays;
      manualRelays = campaignReport.manualRelays;
      reportRoute = campaignReport.relayRoute;
      elapsed = matchElapsed;
      baseReward = reward;
      campaignTransition = transition;
      screen = _Screen.result;
    });
    briefingOperation = _resolveCurrentOperation();
    if (widget.capabilities.adInventoryAvailable &&
        !(activeBattle?.replay ?? false)) {
      unawaited(runtime.prepareResultAds(completedMatches: completedMatches));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestBanner());
  }

  Future<void> _leaveResult({required bool rematch}) async {
    if (_leavingResult || screen != _Screen.result) return;
    _leavingResult = true;
    try {
      if (!(activeBattle?.replay ?? false)) {
        await runtime.closeResult(completedMatches: completedMatches);
      }
      if (!mounted) return;
      if (rematch) {
        final active = activeBattle;
        final priorAttemptSucceeded =
            recoveryOutcome == RecoveryOutcome.recovered ||
            (campaignTransition?.directiveSucceeded ?? false);
        await _startBattle(
          mode: active?.mode ?? GameMode.skirmish,
          faction: active?.faction ?? selectedFaction,
          operation: active?.operation,
          relayRoute: active?.relayRoute,
          replay: active?.mode == GameMode.chronicle
              ? active?.replay == true || priorAttemptSucceeded
              : active?.replay ?? false,
        );
        return;
      }
      await _restoreBattleOrientation(activeGame: game);
      if (!mounted) return;
      setState(() {
        game = null;
        activeBattle = null;
        screen = _Screen.lobby;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestBanner());
    } finally {
      _leavingResult = false;
    }
  }

  Future<void> _continueFromResult() async {
    final active = activeBattle;
    if (active?.mode != GameMode.chronicle || active?.operation == null) {
      await _leaveResult(rematch: false);
      return;
    }
    if (active?.replay == true) {
      await _leaveResult(rematch: false);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openArchive();
      });
      return;
    }
    final echoProgress = runtime.storyProgress;
    if (echoProgress.echoActive &&
        echoProgress.echoConcludedOperations.length ==
            StoryOperationId.values.length) {
      await _leaveResult(rematch: false);
      return;
    }
    if (!mounted) return;
    final nextOperation = _resolveCurrentOperation();
    setState(() {
      game = null;
      briefingRoute = null;
      screen = _Screen.lobby;
    });
    if (nextOperation != null) await _openChronicleBriefing();
  }

  bool get _canChooseEnding {
    final operationId = activeBattle?.operation?.id;
    if (operationId != StoryOperationId.lastInstruction) return false;
    final progress = runtime.storyProgress;
    if (progress.ending == null) return true;
    return progress.echoEnding == null &&
        progress.echoConcludedOperations.contains(
          StoryOperationId.lastInstruction,
        );
  }

  void _chooseEnding(EndingChoice choice) {
    try {
      runtime.chooseChronicleEnding(choice);
    } on StateError {
      return;
    }
    if (mounted) setState(() {});
  }

  Widget _buildScreen(BuildContext context) => switch (screen) {
    _Screen.lobby => LobbyScreen(
      selectedMode: chronicleAvailable ? GameMode.chronicle : GameMode.skirmish,
      storyProgress: runtime.storyProgress,
      rewardLedger: runtime.rewardLedger,
      selectedChronicleFaction: chronicleFaction,
      selectedSkirmishFaction: skirmishFaction,
      onSelectChronicleCore: (faction) {
        setState(() => chronicleFaction = faction);
      },
      onSelectSkirmishFaction: (faction) =>
          setState(() => skirmishFaction = faction),
      onDeployChronicle: _openChronicleBriefing,
      onDeploySkirmish: _deploySkirmish,
      onOpenArchive: _openArchive,
      chronicleAvailable: chronicleAvailable,
      warTokenBalance: runtime.wallet.balance,
      onOpenSettings: _openSettings,
      onOpenLocker: _openLocker,
      bannerVisible: bannerVisible,
      bannerAd: runtime.ads.banner,
      onChooseEnding: _chooseEnding,
      lowSpec: runtime.preferences.lowSpecMode,
      reduceMotion: runtime.preferences.reducedMotionFor(
        systemPrefersReducedMotion: MediaQuery.disableAnimationsOf(context),
      ),
    ),
    _Screen.briefing =>
      briefingOperation == null
          ? LobbyScreen(
              selectedMode: GameMode.chronicle,
              storyProgress: runtime.storyProgress,
              rewardLedger: runtime.rewardLedger,
              selectedChronicleFaction: chronicleFaction,
              selectedSkirmishFaction: skirmishFaction,
              onSelectChronicleCore: (faction) =>
                  setState(() => chronicleFaction = faction),
              onSelectSkirmishFaction: (faction) =>
                  setState(() => skirmishFaction = faction),
              onDeployChronicle: _openChronicleBriefing,
              onDeploySkirmish: _deploySkirmish,
              onOpenArchive: _openArchive,
              chronicleAvailable: chronicleAvailable,
              warTokenBalance: runtime.wallet.balance,
              onOpenSettings: _openSettings,
              onOpenLocker: _openLocker,
              bannerVisible: bannerVisible,
              bannerAd: runtime.ads.banner,
              onChooseEnding: _chooseEnding,
              lowSpec: runtime.preferences.lowSpecMode,
              reduceMotion: runtime.preferences.reducedMotionFor(
                systemPrefersReducedMotion: MediaQuery.disableAnimationsOf(
                  context,
                ),
              ),
            )
          : OperationBriefingScreen(
              operation: briefingOperation!,
              faction:
                  runtime.storyProgress.campaignFaction ?? chronicleFaction,
              selectedRoute: briefingRoute,
              onSelectRoute: (route) => setState(() => briefingRoute = route),
              onDeploy: _deployChronicle,
              onBack: () => setState(() => screen = _Screen.lobby),
            ),
    _Screen.battle => Stack(
      children: [
        BattleScreen(
          key: _battleScreenKey,
          game: game!,
          preferences: runtime.preferences,
          observeLifecycle: false,
          lifecycleState: _lifecycleState,
          requireLandscape: _requireLandscapeForBattle,
        ),
        if (activeBattle?.replay == true &&
            runtime.storyProgress.ending != null)
          Positioned(
            top: 18,
            left: 18,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xCC091113)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Text(
                  context.l10n.archiveSimulation,
                  style: TokenfrontType.instrument.copyWith(fontSize: 10),
                ),
              ),
            ),
          ),
      ],
    ),
    _Screen.result => ResultScreen(
      result: result!,
      recoveryOutcome: recoveryOutcome,
      recoveredSignals: recoveredSignals,
      matchId: currentMatchId,
      playerFaction: selectedFaction,
      relays: relays,
      manualRelays: manualRelays,
      relayRoute: reportRoute,
      elapsed: elapsed,
      baseReward: baseReward,
      warTokenBalance: runtime.wallet.balance,
      bannerVisible: bannerVisible,
      bannerAd: runtime.ads.banner,
      rewardedAdsAvailable:
          widget.capabilities.adInventoryAvailable &&
          !(activeBattle?.replay ?? false),
      onDoubleReward: () => runtime.claimRewardedBonus(
        matchId: currentMatchId,
        baseAmount: baseReward,
        completedMatches: completedMatches,
        replay: activeBattle?.replay ?? false,
      ),
      onOpenSettings: _openSettings,
      onOpenLocker: _openLocker,
      onRematch: () => _leaveResult(rematch: true),
      onLobby: () => _leaveResult(rematch: false),
      onContinue:
          recoveryOutcome == RecoveryOutcome.recovered &&
              activeBattle?.mode == GameMode.chronicle &&
              !(activeBattle?.operation?.id ==
                      StoryOperationId.lastInstruction &&
                  runtime.storyProgress.ending == null)
          ? _continueFromResult
          : null,
      operation: activeBattle?.operation,
      campaignTransition: campaignTransition,
      storyProgress: runtime.storyProgress,
      rewardLedger: runtime.rewardLedger,
      replay: activeBattle?.replay ?? false,
      onChooseEnding: _canChooseEnding ? _chooseEnding : null,
      onCommandDeck: () => _leaveResult(rematch: false),
    ),
  };

  @override
  Widget build(BuildContext context) {
    // Platform ad views cannot be mounted on outgoing and incoming screens.
    return AnimatedSwitcher(
      duration:
          runtime.preferences.reducedMotionFor(
            systemPrefersReducedMotion: MediaQuery.disableAnimationsOf(context),
          )
          ? Duration.zero
          : TokenfrontMotion.screenTransition,
      layoutBuilder: (current, previous) => current ?? const SizedBox.shrink(),
      child: KeyedSubtree(
        key: ValueKey<_Screen>(screen),
        child: _buildScreen(context),
      ),
    );
  }
}
