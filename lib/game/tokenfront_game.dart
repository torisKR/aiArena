import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult, MediaQuery;

import '../design/tokens.dart';
import '../services/audio/game_audio_service.dart';
import '../economy/cosmetic_catalog.dart';
import 'faction_visuals.dart';
import 'simulation.dart';
import 'recovery.dart';
import '../story/story_models.dart';

/// Canvas-space top of a combat-flash caption. The unclamped caption sits
/// 18 px above the event; the result is never above [minCanvasY].
double combatFlashLabelCanvasTop({
  required double eventCanvasY,
  required double minCanvasY,
}) => math.max(eventCanvasY - 18, minCanvasY);

enum HandoffStage {
  impactHold,
  casualtyFocus,
  successorScan,
  relayTravel,
  signalLock,
}

/// The fixed 1.5-second command-handoff contract from the game brief.
abstract final class HandoffTimeline {
  static const double impactEnd = .25;
  static const double casualtyFocusEnd = .55;
  static const double successorScanEnd = .85;
  static const double relayTravelEnd = 1.35;
  static const double duration = 1.5;

  static HandoffStage stageAt(double elapsed) {
    if (elapsed < impactEnd) return HandoffStage.impactHold;
    if (elapsed < casualtyFocusEnd) return HandoffStage.casualtyFocus;
    if (elapsed < successorScanEnd) return HandoffStage.successorScan;
    if (elapsed < relayTravelEnd) return HandoffStage.relayTravel;
    return HandoffStage.signalLock;
  }

  /// Hit-stop, sustained half-speed, then a short return to real time.
  static double simulationScaleAt(double elapsed) {
    if (elapsed < impactEnd) return 0;
    if (elapsed < relayTravelEnd) return .5;
    final settle = ((elapsed - relayTravelEnd) / (duration - relayTravelEnd))
        .clamp(0.0, 1.0);
    return .5 + settle * .5;
  }
}

class BattleHudSnapshot {
  const BattleHudSnapshot({
    required this.elapsed,
    required this.remaining,
    required this.aliveByFaction,
    required this.currentLevel,
    required this.currentKills,
    required this.relayCount,
    required this.directiveProgress,
    required this.handoffProgress,
    required this.handoffStage,
    required this.playerEliminated,
    required this.fps,
    required this.lowSpecMode,
    required this.mouseCameraEnabled,
    required this.cameraZoom,
    this.manualRelayCharge,
    this.manualRelayReady = false,
    this.manualRelayPending = false,
    this.relayRoute,
    this.manualRelayCount = 0,
  });

  factory BattleHudSnapshot.initial({
    bool lowSpecMode = false,
    bool mouseCameraEnabled = true,
    int unitsPerFaction = 1000,
    double matchLimitSeconds = 900,
    DirectiveProgress? directiveProgress,
  }) => BattleHudSnapshot(
    elapsed: 0,
    remaining: matchLimitSeconds,
    aliveByFaction: {
      for (final faction in Faction.values) faction: unitsPerFaction,
    },
    currentLevel: 1,
    currentKills: 0,
    relayCount: 0,
    directiveProgress: directiveProgress,
    handoffProgress: null,
    handoffStage: null,
    playerEliminated: false,
    fps: 60,
    lowSpecMode: lowSpecMode,
    mouseCameraEnabled: mouseCameraEnabled,
    cameraZoom: 1,
    manualRelayCharge: null,
    manualRelayReady: false,
    manualRelayPending: false,
    relayRoute: null,
    manualRelayCount: 0,
  );

  final double elapsed;
  final double remaining;
  final Map<Faction, int> aliveByFaction;
  final int currentLevel;
  final int currentKills;
  final int relayCount;
  final DirectiveProgress? directiveProgress;
  final double? handoffProgress;
  final HandoffStage? handoffStage;
  final bool playerEliminated;
  final double fps;
  final bool lowSpecMode;
  final bool mouseCameraEnabled;
  final double cameraZoom;

  /// Normalized manual-relay charge. Null means manual relay is disabled
  /// (Skirmish), rather than an empty charge.
  final double? manualRelayCharge;
  final bool manualRelayReady;
  final bool manualRelayPending;
  final RelayRoute? relayRoute;
  final int manualRelayCount;

  RelayRoute? get selectedRelayRoute => relayRoute;
}

class _CombatFlash {
  const _CombatFlash(this.event, this.createdAt);
  final CombatEvent event;
  final double createdAt;
}

class TokenfrontGame extends FlameGame with KeyboardEvents {
  TokenfrontGame({
    required this.playerFaction,
    required this.onBattleConcluded,
    this.mode = GameMode.skirmish,
    bool recoveryMode = false,
    this.operation,
    this.seed = 20260715,
    BattleConfig config = const BattleConfig(),
    this.reduceMotion = false,
    this.lowSpecMode = false,
    this.mouseCameraEnabled = true,
    this.cosmeticLoadout = const CosmeticLoadout(
      colorId: 'color_field_issue',
      trailId: 'trail_none',
      deathEffectId: 'death_ring',
    ),
    this.hapticsEnabled = true,
    this.audioEnabled = true,
    this.audio,
    this.combatWinCode = 'WIN',
    this.combatOutCode = 'OUT',
    this.relayRoute,
    this.onHandoffStarted,
    this.onHandoffOutcome,
  }) : assert(mode == GameMode.skirmish || operation != null),
       simulation = BattleSimulation(
         seed: seed,
         config: config,
         playerFaction: playerFaction,
         recovery: recoveryMode ? RecoveryState() : null,
       ),
       hud = ValueNotifier(
         BattleHudSnapshot.initial(
           lowSpecMode: lowSpecMode,
           mouseCameraEnabled: mouseCameraEnabled,
           unitsPerFaction: config.unitsPerFaction,
           matchLimitSeconds: config.matchLimitSeconds,
           directiveProgress: operation == null
               ? null
               : DirectiveProgress(
                   kind: operation.directive.kind,
                   current: 0,
                   target: operation.directive.target,
                 ),
         ),
       ),
       _commandAccent = Color(
         CosmeticCatalog.byId(cosmeticLoadout.colorId).accentValue,
       ),
       _trailAccent = Color(
         CosmeticCatalog.byId(cosmeticLoadout.trailId).accentValue,
       ),
       _deathAccent = Color(
         CosmeticCatalog.byId(cosmeticLoadout.deathEffectId).accentValue,
       ) {
    _cameraCenter =
        simulation.controlledUnit?.position ??
        Vec2(
          simulation.config.worldWidth / 2,
          simulation.config.worldHeight / 2,
        );
    _publishHud();
  }

  final Faction playerFaction;
  final GameMode mode;
  final StoryOperation? operation;
  final int seed;
  final bool reduceMotion;
  bool lowSpecMode;
  bool mouseCameraEnabled;
  final CosmeticLoadout cosmeticLoadout;
  final bool hapticsEnabled;
  final bool audioEnabled;
  final GameAudioService? audio;
  bool _recoveryAcknowledged = false;
  final List<bool> _recoveryMidwayCues = [false, false, false];
  bool get awaitingRecoveryInstruction => isRecovery && !_recoveryAcknowledged;

  void acknowledgeRecoveryInstruction() {
    if (!paused) _recoveryAcknowledged = true;
  }

  void playCue(GameAudioCue cue) {
    if (audio case final service?) unawaited(service.play(cue));
  }

  final String combatWinCode;
  final String combatOutCode;

  /// The route selected by the Chronicle briefing. Legacy callers may omit
  /// it; Chronicle safely resolves that omission to [RelayRoute.preserve].
  final RelayRoute? relayRoute;
  final VoidCallback? onHandoffStarted;
  final ValueChanged<bool>? onHandoffOutcome;
  final void Function(BattleReport report) onBattleConcluded;
  final BattleSimulation simulation;
  bool get isRecovery => simulation.recovery != null;

  void selectDestination(int index) {
    if (!paused && simulation.recovery?.select(index) == true) {
      acknowledgeRecoveryInstruction();
      if (hapticsEnabled) HapticFeedback.lightImpact();
      playCue(GameAudioCue.commandRelay);
      _publishHud();
    }
  }

  final ValueNotifier<BattleHudSnapshot> hud;
  final Color _commandAccent;
  final Color _trailAccent;
  final Color _deathAccent;

  Set<LogicalKeyboardKey> _pressedKeys = const {};
  Vec2 _touchInput = Vec2.zero;
  Vec2 _cameraCenter = Vec2.zero;
  Vec2 _handoffFrom = Vec2.zero;
  Vec2 _handoffTo = Vec2.zero;
  double _handoffElapsed = -1;
  int? _fallenUnitId;
  double _dashRemaining = 0;
  double _dashCooldownRemaining = 0;
  double _realElapsed = 0;
  double _hudAccumulator = 0;
  double _fpsSmoothed = 60;
  double _densityZoom = 1;
  double _manualZoom = 1;
  double _lastRenderZoom = 1;
  double _followResumeRemaining = 0;
  bool _mousePanning = false;
  bool _minimapPanning = false;
  Rect _visibleWorldBounds = Rect.zero;
  int _seenHandoffs = 0;
  int _relayCount = 0;
  int _manualRelayCount = 0;
  double _manualRelayCharge = 1;
  double _manualRelayRechargeSeconds = 0;
  HandoffKind? _handoffKind;
  int? _handoffTargetId;
  final List<HandoffEvent> _handoffQueue = <HandoffEvent>[];
  int _commandKills = 0;
  int? _linkUnitId;
  double _commandLinkSeconds = 0;
  double _longestCommandLinkSeconds = 0;
  bool _handoffRelayEligible = false;
  bool _conclusionPending = false;
  bool _resultReported = false;
  final List<_CombatFlash> _combatFlashes = [];
  final List<Vec2> _trailPoints = <Vec2>[];
  double _trailAccumulator = 0;
  final List<int> _fpsHistogram = List<int>.filled(121, 0);
  final List<int> _hudAliveCounts = List<int>.filled(Faction.values.length, 0);
  final List<int> _hudLevelSums = List<int>.filled(Faction.values.length, 0);
  final List<int> _hudFactionKills = List<int>.filled(Faction.values.length, 0);
  int _hudPlayerRank = 1;
  int _fpsSampleCount = 0;
  double _fpsSampleSum = 0;
  bool _hudDisposed = false;
  double _lastImpactAudioAt = -10;
  ui.Image? _unitAtlas;
  int _debugRenderedUnitCount = 0;
  int _debugCulledUnitCount = 0;
  int _debugAtlasBatchSubmissionCount = 0;
  int _debugAtlasBatchSpriteCount = 0;
  final List<Unit> _visibleRenderUnits = <Unit>[];
  Float32List _atlasTransforms = Float32List(0);
  Float32List _atlasRects = Float32List(0);
  Int32List _atlasColors = Int32List(0);

  static const _combatFlashDuration = .38;
  static const _combatFlashLimit = 96;
  static const _unitCullMargin = 96.0;
  static const _unitAtlasCell = 64.0;
  static const _manualRelayRechargeDuration = 45.0;

  RelayRoute? get selectedRelayRoute =>
      mode == GameMode.chronicle && !isRecovery
      ? relayRoute ?? RelayRoute.preserve
      : null;
  double? get manualRelayCharge =>
      mode == GameMode.chronicle ? _manualRelayCharge : null;
  bool get manualRelayPending =>
      mode == GameMode.chronicle && simulation.manualRelayPending;
  bool get manualRelayReady =>
      !isRecovery &&
      mode == GameMode.chronicle &&
      selectedRelayRoute != null &&
      _manualRelayCharge >= 1 - 1e-9 &&
      !manualRelayPending &&
      _handoffElapsed < 0 &&
      !simulation.finished &&
      simulation.controlledUnit?.alive == true &&
      !simulation.playerFactionEliminated;
  int get manualRelayCount => _manualRelayCount;

  HandoffStage? get handoffStage =>
      _handoffElapsed < 0 ? null : HandoffTimeline.stageAt(_handoffElapsed);

  double get handoffElapsed => _handoffElapsed;
  double get cameraZoom => _lastRenderZoom;
  Rect get visibleWorldBounds => _visibleWorldBounds;
  double get averageFps =>
      _fpsSampleCount == 0 ? 0 : _fpsSampleSum / _fpsSampleCount;

  double get onePercentLowFps {
    if (_fpsSampleCount == 0) return 0;
    final target = math.max(1, (_fpsSampleCount * .01).ceil());
    var seen = 0;
    for (var fps = 0; fps < _fpsHistogram.length; fps++) {
      seen += _fpsHistogram[fps];
      if (seen >= target) return fps.toDouble();
    }
    return 120;
  }

  @visibleForTesting
  int get debugFpsSampleCount => _fpsSampleCount;

  int get commandRelays => _relayCount;
  int get commandKills => _commandKills;
  double get longestCommandLinkSeconds => _longestCommandLinkSeconds;
  DirectiveProgress? get directiveProgress => _directiveProgress;

  DirectiveProgress? get _directiveProgress {
    if (isRecovery) return null;
    final currentOperation = operation;
    if (currentOperation == null) return null;
    final current = switch (currentOperation.directive.kind) {
      DirectiveKind.longestCommandLink => _longestCommandLinkSeconds,
      DirectiveKind.commandRelays => _relayCount.toDouble(),
      DirectiveKind.commandKills => _commandKills.toDouble(),
      DirectiveKind.finalRank => _hudPlayerRank.toDouble(),
      DirectiveKind.victory =>
        simulation.result?.winner == playerFaction ? 1.0 : 0.0,
    };
    return DirectiveProgress(
      kind: currentOperation.directive.kind,
      current: current,
      target: currentOperation.directive.target,
    );
  }

  @visibleForTesting
  void debugResetPerformanceMetrics() {
    _fpsHistogram.fillRange(0, _fpsHistogram.length, 0);
    _fpsSampleCount = 0;
    _fpsSampleSum = 0;
    _fpsSmoothed = 60;
  }

  @visibleForTesting
  Vec2 get debugKeyboardInput => _keyboardInput;

  @visibleForTesting
  Vec2 get debugTouchInput => _touchInput;

  @visibleForTesting
  Vec2 get debugCameraCenter => _cameraCenter;

  @visibleForTesting
  double get debugManualZoom => _manualZoom;

  @visibleForTesting
  bool get debugDashActive => _dashRemaining > 0;

  @visibleForTesting
  bool get debugUnitAtlasLoaded => _unitAtlas != null;

  @visibleForTesting
  Rect debugUnitAtlasSource(Faction faction) => _unitAtlasSource(faction);

  @visibleForTesting
  int get debugRenderedUnitCount => _debugRenderedUnitCount;

  @visibleForTesting
  int get debugCulledUnitCount => _debugCulledUnitCount;

  @visibleForTesting
  int get debugCombatFlashCount => _combatFlashes.length;

  @visibleForTesting
  int? get debugFallenUnitId => _fallenUnitId;

  @visibleForTesting
  int get debugAtlasBatchSubmissionCount => _debugAtlasBatchSubmissionCount;

  @visibleForTesting
  int get debugAtlasBatchSpriteCount => _debugAtlasBatchSpriteCount;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _unitAtlas = await images.load('tokenfront_token_atlas.png');
    } on Object {
      // Keep the procedural token path as a launch-safe asset fallback.
      _unitAtlas = null;
    }
    _cameraCenter =
        simulation.controlledUnit?.position ??
        Vec2(
          simulation.config.worldWidth / 2,
          simulation.config.worldHeight / 2,
        );
    _publishHud();
  }

  void setTouchInput(Vec2 direction) {
    if (paused) return;
    _touchInput = direction.lengthSquared > 1
        ? direction.normalized()
        : direction;
  }

  void clearInputs() {
    _touchInput = Vec2.zero;
    _pressedKeys = const {};
    _dashRemaining = 0;
    simulation.setPlayerInput(Vec2.zero);
  }

  void setLowSpecMode(bool enabled) {
    if (lowSpecMode == enabled) return;
    lowSpecMode = enabled;
    if (enabled) {
      _manualZoom = math.max(_manualZoom, .9);
      if (_combatFlashes.length > 16) {
        _combatFlashes.removeRange(0, _combatFlashes.length - 16);
      }
    }
    _publishHud();
  }

  void setMouseCameraEnabled(bool enabled) {
    if (mouseCameraEnabled == enabled) return;
    mouseCameraEnabled = enabled;
    if (!enabled) endMouseCameraPan();
    _publishHud();
  }

  void beginMouseCameraPan() {
    if (paused || !mouseCameraEnabled || _handoffElapsed >= 0) return;
    _mousePanning = true;
    _followResumeRemaining = 0;
  }

  void updateMouseCameraPan(Offset screenDelta) {
    if (paused ||
        !mouseCameraEnabled ||
        !_mousePanning ||
        _handoffElapsed >= 0) {
      return;
    }
    final zoom = math.max(.01, _lastRenderZoom);
    _cameraCenter =
        (_cameraCenter - Vec2(screenDelta.dx, screenDelta.dy) / zoom).clamp(
          minX: 0,
          maxX: simulation.config.worldWidth,
          minY: 0,
          maxY: simulation.config.worldHeight,
        );
  }

  void endMouseCameraPan() {
    if (!_mousePanning) return;
    _mousePanning = false;
    _followResumeRemaining = 2.4;
  }

  void beginMinimapCameraPan() {
    if (paused || _handoffElapsed >= 0) return;
    _minimapPanning = true;
    _followResumeRemaining = 0;
  }

  void updateMinimapCamera(Vec2 worldPosition) {
    if (paused || !_minimapPanning || _handoffElapsed >= 0) return;
    _cameraCenter = worldPosition.clamp(
      minX: 0,
      maxX: simulation.config.worldWidth,
      minY: 0,
      maxY: simulation.config.worldHeight,
    );
  }

  void endMinimapCameraPan() {
    if (!_minimapPanning) return;
    _minimapPanning = false;
    _followResumeRemaining = 2.4;
  }

  void nudgeMinimapCamera(Vec2 worldDelta) {
    if (paused || _handoffElapsed >= 0) return;
    beginMinimapCameraPan();
    updateMinimapCamera(_cameraCenter + worldDelta);
    endMinimapCameraPan();
  }

  void applyMouseWheel(double scrollDeltaY) {
    if (paused || !mouseCameraEnabled || _handoffElapsed >= 0) return;
    final factor = math.exp(-scrollDeltaY * .0015);
    final minimum = lowSpecMode ? .9 : .68;
    _manualZoom = (_manualZoom * factor).clamp(minimum, 1.45);
    _followResumeRemaining = math.max(_followResumeRemaining, 1.2);
    _publishHud();
  }

  void resetCameraView() {
    if (paused) return;
    _manualZoom = 1;
    _followResumeRemaining = 0;
    _mousePanning = false;
    _minimapPanning = false;
    final target = simulation.controlledUnit?.position;
    if (target != null) _cameraCenter = target;
    _publishHud();
  }

  void triggerDash() {
    if (isRecovery) return;
    if (!paused &&
        _handoffElapsed < 0 &&
        _dashCooldownRemaining <= 0 &&
        simulation.controlledUnit != null) {
      _dashRemaining = .24;
      _dashCooldownRemaining = .9;
      playCue(GameAudioCue.dash);
      if (hapticsEnabled) HapticFeedback.selectionClick();
    }
  }

  /// Queues a manual command relay. Charge is intentionally consumed only
  /// when the corresponding [HandoffEvent] is observed in the simulation log;
  /// a request with no eligible receiver therefore leaves it full.
  bool triggerManualRelay() {
    final route = selectedRelayRoute;
    if (paused ||
        mode != GameMode.chronicle ||
        route == null ||
        !manualRelayReady) {
      return false;
    }
    final accepted = simulation.requestManualRelay(route);
    if (accepted) _publishHud();
    return accepted;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (paused) return KeyEventResult.ignored;
    final movementResult = onMovementKeyEvent(event, keysPressed);
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      triggerDash();
    }
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyR) {
      triggerManualRelay();
    }
    return event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.keyR
        ? KeyEventResult.handled
        : movementResult;
  }

  KeyEventResult onMovementKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (paused) return KeyEventResult.ignored;
    _pressedKeys = Set.unmodifiable(keysPressed.where(_isMovementKey));
    return _isMovementKey(event.logicalKey)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  KeyEventResult onFocusedMovementKeyEvent(KeyEvent event) {
    if (paused) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      if (event is KeyDownEvent) triggerManualRelay();
      return KeyEventResult.handled;
    }
    if (!_isMovementKey(event.logicalKey)) return KeyEventResult.ignored;
    final pressedKeys = {..._pressedKeys};
    if (event is KeyUpEvent) {
      pressedKeys.remove(event.logicalKey);
    } else if (event is KeyDownEvent || event is KeyRepeatEvent) {
      pressedKeys.add(event.logicalKey);
    }
    _pressedKeys = Set.unmodifiable(pressedKeys);
    return KeyEventResult.handled;
  }

  bool _isMovementKey(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.keyW ||
      key == LogicalKeyboardKey.keyA ||
      key == LogicalKeyboardKey.keyS ||
      key == LogicalKeyboardKey.keyD ||
      key == LogicalKeyboardKey.arrowUp ||
      key == LogicalKeyboardKey.arrowDown ||
      key == LogicalKeyboardKey.arrowLeft ||
      key == LogicalKeyboardKey.arrowRight;

  Vec2 get _keyboardInput {
    var x = 0.0;
    var y = 0.0;
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      x += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      y += 1;
    }
    final value = Vec2(x, y);
    return value.lengthSquared > 1 ? value.normalized() : value;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (awaitingRecoveryInstruction) return;
    if (dt <= 0) return;
    final measuredFrameDt = dt.clamp(1 / 240, 1.0).toDouble();
    final safeDt = dt.clamp(0.0, .05).toDouble();
    _realElapsed += safeDt;
    _dashRemaining = math.max(0, _dashRemaining - safeDt);
    _dashCooldownRemaining = math.max(0, _dashCooldownRemaining - safeDt);
    final instantaneousFps = (1 / measuredFrameDt).clamp(0.0, 120.0).toDouble();
    _fpsSmoothed += (instantaneousFps - _fpsSmoothed) * .06;
    _fpsSampleCount += 1;
    _fpsSampleSum += instantaneousFps;
    _fpsHistogram[instantaneousFps.round()] += 1;

    if (_handoffElapsed >= 0) {
      _handoffElapsed = math.min(
        HandoffTimeline.duration,
        _handoffElapsed + safeDt,
      );
    }
    final handoffActive = _handoffElapsed >= 0;
    final input = handoffActive
        ? Vec2.zero
        : (_touchInput.lengthSquared > 0 ? _touchInput : _keyboardInput);
    simulation.setPlayerInput(input, dash: _dashRemaining > 0);

    final simulationDt = handoffActive
        ? safeDt * HandoffTimeline.simulationScaleAt(_handoffElapsed)
        : safeDt;
    final manualRelayPendingBeforeStep = simulation.manualRelayPending;
    final commandedBeforeStep = simulation.controlledUnitId;
    final elapsedBeforeStep = simulation.matchElapsed;
    final recoveredBeforeStep = simulation.recovery?.recoveredCount ?? 0;
    simulation.step(simulationDt);
    if (simulation.recovery case final recovery?) {
      for (final index in recovery.advanceMidwayCues()) {
        if (_recoveryMidwayCues[index]) continue;
        _recoveryMidwayCues[index] = true;
        if (hapticsEnabled) HapticFeedback.lightImpact();
        playCue(GameAudioCue.commandRelay);
      }
    }
    if ((simulation.recovery?.recoveredCount ?? 0) > recoveredBeforeStep) {
      playCue(GameAudioCue.recoveryComplete);
    }

    for (final event in simulation.frameCombatEvents) {
      if (event.winnerId == commandedBeforeStep) _commandKills += 1;
    }
    final elapsedDelta = math
        .max(0, simulation.matchElapsed - elapsedBeforeStep)
        .toDouble();
    _advanceManualRelayCharge(elapsedDelta);
    final commandedAfterStep = simulation.controlledUnitId;
    final commandedAlive =
        simulation.unitById(commandedAfterStep)?.alive ?? false;
    if (commandedAfterStep != _linkUnitId) {
      if (_commandLinkSeconds > _longestCommandLinkSeconds) {
        _longestCommandLinkSeconds = _commandLinkSeconds;
      }
      _linkUnitId = commandedAfterStep;
      _commandLinkSeconds = 0;
    }
    if (commandedAfterStep != null &&
        commandedAlive &&
        commandedAfterStep == commandedBeforeStep) {
      _commandLinkSeconds += elapsedDelta;
      if (_commandLinkSeconds > _longestCommandLinkSeconds) {
        _longestCommandLinkSeconds = _commandLinkSeconds;
      }
    }

    final combatFlashLimit = lowSpecMode ? 16 : _combatFlashLimit;
    for (final event in simulation.frameCombatEvents) {
      if (_combatFlashes.length >= combatFlashLimit) break;
      _combatFlashes.add(_CombatFlash(event, _realElapsed));
      if (_realElapsed - _lastImpactAudioAt >= .11) {
        _lastImpactAudioAt = _realElapsed;
        playCue(GameAudioCue.combatImpact);
      }
    }
    final flashDuration = lowSpecMode ? .26 : _combatFlashDuration;
    _combatFlashes.removeWhere(
      (flash) => _realElapsed - flash.createdAt > flashDuration,
    );

    var handoffObserved = false;
    while (_seenHandoffs < simulation.handoffLog.length) {
      final event = simulation.handoffLog[_seenHandoffs++];
      if (isRecovery) {
        if (!event.factionEliminated) playCue(GameAudioCue.commandRelay);
        if (!event.factionEliminated) _relayCount += 1;
        onHandoffOutcome?.call(!event.factionEliminated);
        handoffObserved = true;
        continue;
      }
      _handoffQueue.add(event);
      handoffObserved = true;
      if (event.kind == HandoffKind.manual) {
        // A request itself never spends charge. Only the observed successful
        // event starts a new 45 simulation-second recharge window.
        _manualRelayCharge = 0;
        _manualRelayRechargeSeconds = 0;
      }
    }
    if (_handoffElapsed < 0) _startNextHandoff();

    _updateTrail(safeDt);
    _updateDensityZoom(safeDt);
    _updateCamera(safeDt);

    _hudAccumulator += safeDt;
    if (_hudAccumulator >= (lowSpecMode ? .2 : .1)) {
      _hudAccumulator = 0;
      _publishHud();
    } else if (handoffObserved ||
        (manualRelayPendingBeforeStep && !simulation.manualRelayPending)) {
      // Reflect an observed handoff or a failed/no-target request immediately;
      // neither should wait for the periodic HUD cadence.
      _publishHud();
    }

    if (simulation.finished && !_resultReported && simulation.result != null) {
      if (_handoffElapsed >= 0 || _handoffQueue.isNotEmpty) {
        _conclusionPending = true;
      } else {
        _publishConclusion(
          simulation.result!.reason == MatchEndReason.timeLimit
              ? ChronicleEndReason.timeLimit
              : ChronicleEndReason.globalResolution,
        );
      }
    }
  }

  void _startNextHandoff() {
    if (_handoffElapsed >= 0) return;
    while (_handoffQueue.isNotEmpty) {
      final event = _handoffQueue.removeAt(0);
      if (event.factionEliminated) {
        onHandoffOutcome?.call(false);
        continue;
      }

      final from = simulation.unitById(event.fromUnitId);
      final to = simulation.unitById(event.toUnitId);
      _handoffFrom = from?.position ?? _cameraCenter;
      _handoffTo =
          to?.position ??
          Vec2(
            simulation.config.worldWidth / 2,
            simulation.config.worldHeight / 2,
          );
      _handoffElapsed = 0;
      _handoffKind = event.kind;
      _handoffTargetId = event.toUnitId;
      _handoffRelayEligible = true;
      // Manual relays keep their source alive and therefore do not receive
      // the casualty focus/death mark used by the automatic handoff path.
      _fallenUnitId = event.kind == HandoffKind.manual
          ? null
          : event.fromUnitId;
      _trailPoints.clear();
      _mousePanning = false;
      _minimapPanning = false;
      _followResumeRemaining = 0;
      onHandoffStarted?.call();
      playCue(GameAudioCue.commandRelay);
      if (hapticsEnabled) HapticFeedback.mediumImpact();
      return;
    }
    if (!simulation.finished &&
        simulation.result == null &&
        _handoffQueue.isEmpty) {
      _maybeConcludePlayerElimination();
    }
  }

  void _advanceManualRelayCharge(double elapsedDelta) {
    if (mode != GameMode.chronicle || elapsedDelta <= 0) return;
    if (_manualRelayCharge >= 1) return;
    _manualRelayRechargeSeconds = math.min(
      _manualRelayRechargeDuration,
      _manualRelayRechargeSeconds + elapsedDelta,
    );
    _manualRelayCharge =
        (_manualRelayRechargeSeconds / _manualRelayRechargeDuration)
            .clamp(0.0, 1.0)
            .toDouble();
  }

  void _updateDensityZoom(double dt) {
    final anchor = simulation.controlledUnit?.position ?? _battleCentroid();
    const radius = 300.0;
    final radiusSquared = radius * radius;
    var nearby = 0;
    for (final unit in simulation.units) {
      if (unit.alive &&
          unit.position.distanceSquaredTo(anchor) <= radiusSquared) {
        nearby += 1;
      }
    }
    final density = ((nearby - 10) / 70).clamp(0.0, 1.0);
    var target = 1 - density * .12;
    if (lowSpecMode) target = math.max(target, .9);
    final smoothing = 1 - math.pow(.04, dt).toDouble();
    _densityZoom += (target - _densityZoom) * smoothing;
  }

  void _updateCamera(double dt) {
    if (_handoffElapsed >= 0) {
      final elapsed = _handoffElapsed;
      if (elapsed < HandoffTimeline.successorScanEnd) {
        _cameraCenter = _handoffFrom;
      } else if (reduceMotion) {
        // Preserve the 1.5-second information sequence without sweeping the
        // viewport for people who request reduced motion.
        _cameraCenter = _handoffTo;
      } else if (elapsed < HandoffTimeline.relayTravelEnd) {
        final raw =
            (elapsed - HandoffTimeline.successorScanEnd) /
            (HandoffTimeline.relayTravelEnd - HandoffTimeline.successorScanEnd);
        _cameraCenter = _relayCurvePoint(
          Curves.easeInOutCubic.transform(raw.clamp(0.0, 1.0)),
        );
      } else {
        _cameraCenter = _handoffTo;
      }

      if (elapsed >= HandoffTimeline.duration) {
        final completedKind = _handoffKind;
        final receiverAlive =
            _handoffTargetId != null &&
            (simulation.unitById(_handoffTargetId)?.alive ?? false);
        _handoffElapsed = -1;
        _fallenUnitId = null;
        _handoffTargetId = null;
        final manualReceiverLost =
            completedKind == HandoffKind.manual && !receiverAlive;
        if (_handoffRelayEligible && !manualReceiverLost) {
          _relayCount += 1;
          if (completedKind == HandoffKind.manual) _manualRelayCount += 1;
        }
        _handoffRelayEligible = false;
        _handoffKind = null;
        onHandoffOutcome?.call(!manualReceiverLost);
        if (hapticsEnabled) HapticFeedback.lightImpact();
        _startNextHandoff();
        if (_conclusionPending &&
            _handoffElapsed < 0 &&
            _handoffQueue.isEmpty &&
            simulation.result != null) {
          _conclusionPending = false;
          _publishConclusion(
            simulation.result!.reason == MatchEndReason.timeLimit
                ? ChronicleEndReason.timeLimit
                : ChronicleEndReason.globalResolution,
          );
        }
      }
      return;
    }

    if (_mousePanning || _minimapPanning) return;
    if (_followResumeRemaining > 0) {
      _followResumeRemaining = math.max(0, _followResumeRemaining - dt);
      return;
    }
    final target = simulation.controlledUnit?.position ?? _battleCentroid();
    final follow = 1 - math.pow(.001, dt).toDouble();
    _cameraCenter += (target - _cameraCenter) * follow;
  }

  Vec2 _relayCurvePoint(double t) {
    final delta = _handoffTo - _handoffFrom;
    final controlA = _handoffFrom + delta * .28 + const Vec2(0, -120);
    final controlB = _handoffFrom + delta * .72 + const Vec2(0, 95);
    final inverse = 1 - t;
    return _handoffFrom * (inverse * inverse * inverse) +
        controlA * (3 * inverse * inverse * t) +
        controlB * (3 * inverse * t * t) +
        _handoffTo * (t * t * t);
  }

  Vec2 _battleCentroid() {
    var x = 0.0;
    var y = 0.0;
    var count = 0;
    for (final unit in simulation.units) {
      if (!unit.alive) continue;
      x += unit.position.x;
      y += unit.position.y;
      count += 1;
    }
    return count == 0
        ? Vec2(
            simulation.config.worldWidth / 2,
            simulation.config.worldHeight / 2,
          )
        : Vec2(x / count, y / count);
  }

  void _updateTrail(double dt) {
    if (lowSpecMode || cosmeticLoadout.trailId == 'trail_none') {
      _trailPoints.clear();
      return;
    }
    final controlled = simulation.controlledUnit;
    if (controlled == null || !controlled.alive || _handoffElapsed >= 0) {
      return;
    }
    _trailAccumulator += dt;
    if (_trailAccumulator < .075) return;
    _trailAccumulator = 0;
    if (_trailPoints.isEmpty ||
        _trailPoints.last.distanceSquaredTo(controlled.position) >= 20) {
      _trailPoints.add(controlled.position);
      if (_trailPoints.length > 14) _trailPoints.removeAt(0);
    }
  }

  void _publishHud() {
    final controlled = simulation.controlledUnit;
    _hudAliveCounts.fillRange(0, _hudAliveCounts.length, 0);
    _hudLevelSums.fillRange(0, _hudLevelSums.length, 0);
    _hudFactionKills.fillRange(0, _hudFactionKills.length, 0);
    for (final unit in simulation.units) {
      _hudFactionKills[unit.faction.index] += unit.kills;
      if (unit.alive) {
        _hudAliveCounts[unit.faction.index] += 1;
        _hudLevelSums[unit.faction.index] += unit.level;
      }
    }
    final rankOrder = List<Faction>.of(Faction.values)
      ..sort((a, b) {
        var comparison = _hudAliveCounts[b.index].compareTo(
          _hudAliveCounts[a.index],
        );
        if (comparison != 0) return comparison;
        comparison = _hudLevelSums[b.index].compareTo(_hudLevelSums[a.index]);
        if (comparison != 0) return comparison;
        comparison = _hudFactionKills[b.index].compareTo(
          _hudFactionKills[a.index],
        );
        return comparison != 0 ? comparison : a.index.compareTo(b.index);
      });
    _hudPlayerRank = rankOrder.indexOf(playerFaction) + 1;
    hud.value = BattleHudSnapshot(
      elapsed: simulation.matchElapsed,
      remaining: math.max(0, simulation.matchLimit - simulation.matchElapsed),
      aliveByFaction: {
        for (final faction in Faction.values)
          faction: _hudAliveCounts[faction.index],
      },
      currentLevel: controlled?.level ?? 0,
      currentKills: controlled?.kills ?? 0,
      relayCount: _relayCount,
      directiveProgress: _directiveProgress,
      handoffProgress: _handoffElapsed < 0
          ? null
          : (_handoffElapsed / HandoffTimeline.duration).clamp(0.0, 1.0),
      handoffStage: handoffStage,
      playerEliminated: _hudAliveCounts[playerFaction.index] == 0,
      fps: _fpsSmoothed.clamp(0, 999),
      lowSpecMode: lowSpecMode,
      mouseCameraEnabled: mouseCameraEnabled,
      cameraZoom: _lastRenderZoom,
      manualRelayCharge: manualRelayCharge,
      manualRelayReady: manualRelayReady,
      manualRelayPending: manualRelayPending,
      relayRoute: selectedRelayRoute,
      manualRelayCount: _manualRelayCount,
    );
  }

  void _maybeConcludePlayerElimination() {
    if (mode != GameMode.chronicle ||
        _resultReported ||
        !simulation.playerFactionEliminated) {
      return;
    }
    _publishConclusion(ChronicleEndReason.playerEliminated);
  }

  void _publishConclusion(ChronicleEndReason reason) {
    if (_resultReported) return;
    _resultReported = true;
    final standings = simulation.standings();
    final playerStanding = standings.firstWhere(
      (standing) => standing.faction == playerFaction,
    );
    final result = simulation.result;
    final report = BattleReport(
      endReason: isRecovery ? ChronicleEndReason.recovery : reason,
      recoveryOutcome: simulation.recovery?.outcome,
      recoveredSignals: simulation.recovery?.recoveredCount ?? 0,
      standingsAtConclusion: standings,
      globalWinner: reason == ChronicleEndReason.playerEliminated
          ? null
          : result?.winner,
      commandRelays: _relayCount,
      manualRelays: _manualRelayCount,
      relayRoute: selectedRelayRoute,
      commandKills: _commandKills,
      longestCommandLinkSeconds: _longestCommandLinkSeconds,
      playerRank: standings.indexOf(playerStanding) + 1,
      playerSurvivors: playerStanding.survivors,
    );
    onBattleConcluded(report);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawColor(TokenfrontColors.deepField, BlendMode.src);
    _debugRenderedUnitCount = 0;
    _debugCulledUnitCount = 0;
    _debugAtlasBatchSubmissionCount = 0;
    _debugAtlasBatchSpriteCount = 0;
    _visibleRenderUnits.clear();
    if (size.x <= 0 || size.y <= 0) return;

    final config = simulation.config;
    final wideZoom = math
        .min(
          size.x / (config.worldWidth + 120),
          size.y / (config.worldHeight + 120),
        )
        .clamp(.31, .65);
    final followZoom = math
        .min(size.x / 1400, size.y / 820)
        .clamp(wideZoom, .92);
    final reveal = reduceMotion
        ? 1.0
        : ((_realElapsed - 1.0) / 3.0).clamp(0.0, 1.0);
    final baseZoom =
        wideZoom +
        (followZoom - wideZoom) * Curves.easeInOutCubic.transform(reveal);
    final minimumZoom = wideZoom * (lowSpecMode ? .92 : .72);
    final zoom = (baseZoom * _densityZoom * _manualZoom * _handoffZoomFactor())
        .clamp(minimumZoom, 1.35)
        .toDouble();
    _lastRenderZoom = zoom;
    final halfWidth = size.x / (2 * zoom);
    final halfHeight = size.y / (2 * zoom);
    final renderCenter = Vec2(
      halfWidth * 2 >= config.worldWidth
          ? config.worldWidth / 2
          : _cameraCenter.x
                .clamp(halfWidth, config.worldWidth - halfWidth)
                .toDouble(),
      halfHeight * 2 >= config.worldHeight
          ? config.worldHeight / 2
          : _cameraCenter.y
                .clamp(halfHeight, config.worldHeight - halfHeight)
                .toDouble(),
    );
    _visibleWorldBounds = Rect.fromLTRB(
      math.max(0, renderCenter.x - halfWidth),
      math.max(0, renderCenter.y - halfHeight),
      math.min(config.worldWidth, renderCenter.x + halfWidth),
      math.min(config.worldHeight, renderCenter.y + halfHeight),
    );
    final visibleUnitBounds = Rect.fromLTRB(
      renderCenter.x - halfWidth - _unitCullMargin,
      renderCenter.y - halfHeight - _unitCullMargin,
      renderCenter.x + halfWidth + _unitCullMargin,
      renderCenter.y + halfHeight + _unitCullMargin,
    );

    canvas.save();
    canvas.clipRect(Offset.zero & Size(size.x, size.y));
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(zoom);
    canvas.translate(-renderCenter.x, -renderCenter.y);

    _drawArena(canvas, zoom);
    _drawOrbitalBackdrop(canvas, zoom);
    if (simulation.recovery case final recovery?) {
      for (var index = 0; index < 3; index++) {
        final position = RecoveryState.destinations[index];
        final color = recovery.seconds[index] >= RecoveryState.requiredSeconds
            ? TokenfrontColors.volt
            : recovery.selected == index
            ? TokenfrontColors.threadCyan
            : TokenfrontColors.relayIvory;
        final center = Offset(position.x, position.y);
        canvas.drawCircle(
          center,
          RecoveryState.radius,
          Paint()..color = color.withValues(alpha: .12),
        );
        canvas.drawCircle(
          center,
          RecoveryState.radius,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = recovery.selected == index ? 4 : 2,
        );
        // Occupancy arc: the node itself shows banked progress, so the 5s
        // midway beat is readable without relying on audio or haptics.
        final banked = recovery.seconds[index];
        if (banked > 0) {
          const arcRadius = RecoveryState.radius - 7;
          final sweep =
              (banked / RecoveryState.requiredSeconds).clamp(0.0, 1.0) *
              math.pi *
              2;
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: arcRadius),
            -math.pi / 2,
            sweep,
            false,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..strokeCap = StrokeCap.round,
          );
        }
        // Midway notch at 5s, so crossing it is a visible event.
        if (banked < RecoveryState.requiredSeconds) {
          const midwayAngle =
              -math.pi / 2 +
              (RecoveryState.midwaySeconds / RecoveryState.requiredSeconds) *
                  math.pi *
                  2;
          final reached = banked >= RecoveryState.midwaySeconds;
          final inner =
              center +
              Offset(math.cos(midwayAngle), math.sin(midwayAngle)) *
                  (RecoveryState.radius - 13);
          final outer =
              center +
              Offset(math.cos(midwayAngle), math.sin(midwayAngle)) *
                  (RecoveryState.radius - 1);
          canvas.drawLine(
            inner,
            outer,
            Paint()
              ..color = color.withValues(alpha: reached ? 1 : .45)
              ..strokeWidth = reached ? 3 : 2
              ..strokeCap = StrokeCap.round,
          );
        }
        final label = TextPainter(
          text: TextSpan(
            text: '${index + 1}',
            style: TokenfrontType.instrument.copyWith(
              color: color,
              fontSize: 24,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
      }
    }
    _drawMovementTrail(canvas, zoom);
    if (_isImpactChromaticActive) {
      _drawChromaticEchoes(canvas, zoom, visibleUnitBounds);
    }
    for (final unit in simulation.units) {
      final fallenFocus =
          _handoffElapsed >= 0 &&
          unit.id == _fallenUnitId &&
          _handoffElapsed < HandoffTimeline.casualtyFocusEnd;
      if (!unit.alive && !fallenFocus) continue;
      if (!fallenFocus && !_isWithinUnitBounds(unit, visibleUnitBounds)) {
        _debugCulledUnitCount += 1;
        continue;
      }
      _visibleRenderUnits.add(unit);
      _debugRenderedUnitCount += 1;
    }
    final atlas = _unitAtlas;
    if (atlas != null && _visibleRenderUnits.isNotEmpty) {
      _drawAtlasUnitBatch(canvas, atlas, _visibleRenderUnits);
      for (final unit in _visibleRenderUnits) {
        _drawUnit(canvas, unit, zoom, drawBase: false);
      }
    } else {
      for (final unit in _visibleRenderUnits) {
        _drawUnit(canvas, unit, zoom);
      }
    }
    _drawCombatFlashes(canvas, zoom, renderCenter);
    if (_handoffElapsed >= 0 && !reduceMotion) _drawRelayTape(canvas, zoom);
    canvas.restore();

    if (_isImpactChromaticActive) {
      final hit =
          (1 - (_handoffElapsed / HandoffTimeline.impactEnd).clamp(0.0, 1.0)) *
          .18;
      if (hit > 0) {
        canvas.drawRect(
          Rect.fromLTWH(0, 0, 5, size.y),
          Paint()..color = TokenfrontColors.cobalt.withValues(alpha: hit),
        );
        canvas.drawRect(
          Rect.fromLTWH(size.x - 5, 0, 5, size.y),
          Paint()..color = TokenfrontColors.prism.withValues(alpha: hit),
        );
      }
    }
  }

  bool get _isImpactChromaticActive =>
      _handoffElapsed >= 0 &&
      _handoffElapsed < HandoffTimeline.impactEnd &&
      !reduceMotion &&
      !lowSpecMode;

  double _handoffZoomFactor() {
    if (_handoffElapsed < 0 || reduceMotion || lowSpecMode) return 1;
    final elapsed = _handoffElapsed;
    if (elapsed < HandoffTimeline.impactEnd) return 1;
    if (elapsed < HandoffTimeline.casualtyFocusEnd) {
      final progress =
          (elapsed - HandoffTimeline.impactEnd) /
          (HandoffTimeline.casualtyFocusEnd - HandoffTimeline.impactEnd);
      return 1 + Curves.easeOutCubic.transform(progress) * .18;
    }
    if (elapsed < HandoffTimeline.successorScanEnd) return 1.18;
    if (elapsed < HandoffTimeline.relayTravelEnd) {
      final progress =
          (elapsed - HandoffTimeline.successorScanEnd) /
          (HandoffTimeline.relayTravelEnd - HandoffTimeline.successorScanEnd);
      return 1.18 - Curves.easeInOutCubic.transform(progress) * .18;
    }
    return 1;
  }

  void _drawArena(Canvas canvas, double zoom) {
    final config = simulation.config;
    final arena = Rect.fromLTWH(0, 0, config.worldWidth, config.worldHeight);
    canvas.drawRect(
      arena,
      Paint()
        ..color = TokenfrontColors.battlefieldOxide
        ..isAntiAlias = false,
    );
    final gridPaint = Paint()
      ..color = TokenfrontColors.relayIvory.withValues(alpha: .055)
      ..strokeWidth = 1 / zoom
      ..isAntiAlias = false;
    final gridStep = config.gridCellSize * (lowSpecMode ? 2 : 1);
    for (var x = 0.0; x <= config.worldWidth; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, config.worldHeight), gridPaint);
    }
    for (var y = 0.0; y <= config.worldHeight; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(config.worldWidth, y), gridPaint);
    }
    canvas.drawRect(
      arena.deflate(4 / zoom),
      Paint()
        ..color = TokenfrontColors.relayIvory.withValues(alpha: .24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 / zoom
        ..isAntiAlias = false,
    );
  }

  void _drawOrbitalBackdrop(Canvas canvas, double zoom) {
    final config = simulation.config;
    final center = Offset(config.worldWidth / 2, config.worldHeight / 2);
    final arcPaint = Paint()
      ..color = TokenfrontColors.relayIvory.withValues(alpha: .10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 / zoom
      ..isAntiAlias = false;
    for (final (radius, start, sweep) in <(double, double, double)>[
      (240, .28, 2.10),
      (420, 2.72, 2.26),
      (620, -.42, 2.45),
    ]) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        arcPaint,
      );
    }
    canvas.drawCircle(
      center,
      22,
      Paint()
        ..color = TokenfrontColors.relayIvory.withValues(alpha: .16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 / zoom
        ..isAntiAlias = false,
    );
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..color = TokenfrontColors.relayIvory.withValues(alpha: .22)
        ..isAntiAlias = false,
    );
    final nodeOffset = 310.0;
    for (final (offset, color) in <(Offset, Color)>[
      (Offset(-nodeOffset, 24), TokenfrontColors.amethyst),
      (Offset(22, -nodeOffset), TokenfrontColors.cobalt),
      (Offset(nodeOffset, -28), TokenfrontColors.volt),
      (Offset(-34, nodeOffset), TokenfrontColors.prism),
    ]) {
      canvas.drawCircle(
        center + offset,
        8,
        Paint()
          ..color = color.withValues(alpha: .18)
          ..isAntiAlias = false,
      );
    }
  }

  bool _isWithinUnitBounds(Unit unit, Rect bounds) {
    final position = unit.position;
    return position.x >= bounds.left &&
        position.x <= bounds.right &&
        position.y >= bounds.top &&
        position.y <= bounds.bottom;
  }

  void _drawChromaticEchoes(
    Canvas canvas,
    double zoom,
    Rect visibleUnitBounds,
  ) {
    final strength =
        1 - (_handoffElapsed / HandoffTimeline.impactEnd).clamp(0.0, 1.0);
    final offset = 3.5 / zoom;
    for (final unit in simulation.units) {
      if (!unit.alive && unit.id != _fallenUnitId) continue;
      if (unit.id != _fallenUnitId &&
          !_isWithinUnitBounds(unit, visibleUnitBounds)) {
        continue;
      }
      final radius = 5.2 + unit.level * .43;
      final center = Offset(unit.position.x, unit.position.y);
      for (final echo in <(Offset, Color)>[
        (Offset(-offset, 0), TokenfrontColors.cobalt),
        (Offset(offset, 0), TokenfrontColors.prism),
      ]) {
        canvas.drawPath(
          _polygon(
            center + echo.$1,
            radius,
            unit.faction.visual.sides,
            _rotation(unit),
          ),
          Paint()
            ..color = echo.$2.withValues(alpha: strength * .25)
            ..style = PaintingStyle.fill
            ..blendMode = BlendMode.plus
            ..isAntiAlias = false,
        );
      }
    }
  }

  void _drawAtlasUnitBatch(
    Canvas canvas,
    ui.Image atlas,
    List<Unit> visibleUnits,
  ) {
    final count = visibleUnits.length;
    final transformLength = count * 4;
    if (_atlasTransforms.length < transformLength) {
      final capacity = simulation.units.length * 4;
      _atlasTransforms = Float32List(capacity);
      _atlasRects = Float32List(capacity);
      _atlasColors = Int32List(simulation.units.length);
    }

    for (var index = 0; index < count; index++) {
      final unit = visibleUnits[index];
      final isFallenFocus = !unit.alive && unit.id == _fallenUnitId;
      final focusProgress = isFallenFocus
          ? ((_handoffElapsed - HandoffTimeline.impactEnd) /
                    (HandoffTimeline.casualtyFocusEnd -
                        HandoffTimeline.impactEnd))
                .clamp(0.0, 1.0)
          : 0.0;
      final radius =
          (5.2 + unit.level * .43) *
          (isFallenFocus
              ? 1 + Curves.easeOutCubic.transform(focusProgress) * .4
              : 1);
      final side = radius * 3.8;
      final scale = side / _unitAtlasCell;
      final transformOffset = index * 4;
      _atlasTransforms[transformOffset] = scale;
      _atlasTransforms[transformOffset + 1] = 0;
      _atlasTransforms[transformOffset + 2] = unit.position.x - side / 2;
      _atlasTransforms[transformOffset + 3] = unit.position.y - side / 2;

      final sourceLeft = unit.faction.index * _unitAtlasCell;
      _atlasRects[transformOffset] = sourceLeft;
      _atlasRects[transformOffset + 1] = 0;
      _atlasRects[transformOffset + 2] = sourceLeft + _unitAtlasCell;
      _atlasRects[transformOffset + 3] = _unitAtlasCell;
      final alpha = isFallenFocus ? 1 - focusProgress * .72 : 1.0;
      _atlasColors[index] = ((alpha * 255).round() << 24) | 0x00ffffff;
    }

    canvas.drawRawAtlas(
      atlas,
      Float32List.sublistView(_atlasTransforms, 0, transformLength),
      Float32List.sublistView(_atlasRects, 0, transformLength),
      Int32List.sublistView(_atlasColors, 0, count),
      BlendMode.modulate,
      null,
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );
    _debugAtlasBatchSubmissionCount = 1;
    _debugAtlasBatchSpriteCount = count;
  }

  void _drawUnit(
    Canvas canvas,
    Unit unit,
    double zoom, {
    bool drawBase = true,
  }) {
    final color = unit.faction.visual.color;
    final isFallenFocus = !unit.alive && unit.id == _fallenUnitId;
    final focusProgress = isFallenFocus
        ? ((_handoffElapsed - HandoffTimeline.impactEnd) /
                  (HandoffTimeline.casualtyFocusEnd -
                      HandoffTimeline.impactEnd))
              .clamp(0.0, 1.0)
        : 0.0;
    final radius =
        (5.2 + unit.level * .43) *
        (isFallenFocus
            ? 1 + Curves.easeOutCubic.transform(focusProgress) * .4
            : 1);
    final center = Offset(unit.position.x, unit.position.y);
    final atlas = _unitAtlas;
    if (drawBase && atlas != null) {
      final side = radius * 3.8;
      canvas.drawImageRect(
        atlas,
        _unitAtlasSource(unit.faction),
        Rect.fromCenter(center: center, width: side, height: side),
        Paint()
          ..color = const Color(
            0xFFFFFFFF,
          ).withValues(alpha: isFallenFocus ? 1 - focusProgress * .72 : 1)
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false,
      );
    } else if (drawBase) {
      final path = _polygon(
        center,
        radius,
        unit.faction.visual.sides,
        _rotation(unit),
      );
      final fill = Paint()
        ..color = isFallenFocus
            ? color.withValues(alpha: 1 - focusProgress * .72)
            : color
        ..style = PaintingStyle.fill
        ..isAntiAlias = false;
      final shade = Paint()
        ..color = Color.lerp(color, TokenfrontColors.deepField, .44)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / zoom
        ..isAntiAlias = false;
      canvas.drawPath(path, fill);
      canvas.drawPath(path, shade);
    }

    if (unit.level >= 7) {
      canvas.drawCircle(
        center,
        math.max(1.2 / zoom, radius * .22),
        Paint()
          ..color = TokenfrontColors.relayIvory.withValues(alpha: .88)
          ..isAntiAlias = false,
      );
    }

    final successorHighlightVisible =
        _handoffElapsed < 0 ||
        _handoffElapsed >= HandoffTimeline.successorScanEnd;
    if (unit.alive &&
        simulation.controlledUnitId == unit.id &&
        successorHighlightVisible) {
      final relayPulse = _handoffElapsed < 0
          ? 0.0
          : math.sin(
              ((_handoffElapsed - HandoffTimeline.successorScanEnd) /
                          (HandoffTimeline.duration -
                              HandoffTimeline.successorScanEnd))
                      .clamp(0.0, 1.0) *
                  math.pi *
                  3,
            );
      canvas.drawPath(
        _polygon(
          center,
          radius + (5 + math.max(0, relayPulse) * 3) / zoom,
          4,
          math.pi / 4,
        ),
        Paint()
          ..color = _commandAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 / zoom
          ..isAntiAlias = false,
      );
      final direction = unit.velocity.lengthSquared == 0
          ? const Vec2(0, -1)
          : unit.velocity.normalized();
      final tip =
          center + Offset(direction.x, direction.y) * (radius + 10 / zoom);
      final perpendicular = Offset(-direction.y, direction.x);
      final arrow = Path()
        ..moveTo(
          tip.dx + direction.x * 4 / zoom,
          tip.dy + direction.y * 4 / zoom,
        )
        ..lineTo(
          tip.dx - direction.x * 3 / zoom + perpendicular.dx * 3 / zoom,
          tip.dy - direction.y * 3 / zoom + perpendicular.dy * 3 / zoom,
        )
        ..lineTo(
          tip.dx - direction.x * 3 / zoom - perpendicular.dx * 3 / zoom,
          tip.dy - direction.y * 3 / zoom - perpendicular.dy * 3 / zoom,
        )
        ..close();
      canvas.drawPath(
        arrow,
        Paint()
          ..color = _commandAccent
          ..isAntiAlias = false,
      );
    }
  }

  void _drawMovementTrail(Canvas canvas, double zoom) {
    if (_trailPoints.length < 2 || lowSpecMode) return;
    final cinder = cosmeticLoadout.trailId == 'trail_cinder';
    for (var index = 1; index < _trailPoints.length; index++) {
      final progress = index / _trailPoints.length;
      final point = _trailPoints[index];
      final previous = _trailPoints[index - 1];
      final alpha = (.1 + progress * .52).clamp(0.0, 1.0);
      if (cinder) {
        if (index.isOdd) continue;
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(point.x, point.y),
            width: 5 / zoom,
            height: 5 / zoom,
          ),
          Paint()
            ..color = _trailAccent.withValues(alpha: alpha)
            ..isAntiAlias = false,
        );
      } else {
        canvas.drawLine(
          Offset(previous.x, previous.y),
          Offset(point.x, point.y),
          Paint()
            ..color = _trailAccent.withValues(alpha: alpha)
            ..strokeWidth = 2.5 / zoom
            ..strokeCap = StrokeCap.square
            ..isAntiAlias = false,
        );
      }
    }
  }

  double _rotation(Unit unit) => switch (unit.faction) {
    Faction.amethyst => 0,
    Faction.cobalt => math.pi / 4,
    Faction.volt => -math.pi / 2,
    Faction.prism => math.pi / 6,
  };

  Rect _unitAtlasSource(Faction faction) => Rect.fromLTWH(
    faction.index * _unitAtlasCell,
    0,
    _unitAtlasCell,
    _unitAtlasCell,
  );

  Path _polygon(Offset center, double radius, int sides, double rotation) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = rotation + math.pi * 2 * i / sides;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  double get _combatFlashMinCanvasY {
    const floor = 8.0;
    final ctx = buildContext;
    if (ctx == null || !ctx.mounted) return floor;
    final mq = MediaQuery.maybeOf(ctx);
    if (mq == null) return floor;
    return math.max(floor, math.max(mq.padding.top, mq.viewPadding.top));
  }

  void _drawCombatFlashes(Canvas canvas, double zoom, Vec2 renderCenter) {
    final minCanvasY = _combatFlashMinCanvasY;
    for (final flash in _combatFlashes) {
      final duration = lowSpecMode ? .26 : _combatFlashDuration;
      final age = (_realElapsed - flash.createdAt) / duration;
      final alpha = (1 - age).clamp(0.0, 1.0);
      final event = flash.event;
      final center = Offset(event.position.x, event.position.y);
      canvas.drawRect(
        Rect.fromCenter(
          center: center,
          width: (18 + age * 22) / zoom,
          height: 3 / zoom,
        ),
        Paint()
          ..color = event.winnerFaction.visual.color.withValues(alpha: alpha)
          ..isAntiAlias = false,
      );
      if (event.loserFaction == playerFaction) {
        _drawPlayerDeathMark(canvas, center, age, alpha, zoom);
      }
      final painter = TextPainter(
        text: TextSpan(
          text: event.tiedLevels
              ? '$combatWinCode  LV ${event.winnerLevel} = ${event.loserLevel}  $combatOutCode'
              : '$combatWinCode  LV ${event.winnerLevel} > ${event.loserLevel}  $combatOutCode',
          style: TextStyle(
            color: TokenfrontColors.relayIvory.withValues(alpha: alpha),
            fontFamily: 'monospace',
            fontWeight: FontWeight.w800,
            fontSize: 10 / zoom,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final eventCanvasY = size.y / 2 + (center.dy - renderCenter.y) * zoom;
      final labelCanvasTop = combatFlashLabelCanvasTop(
        eventCanvasY: eventCanvasY,
        minCanvasY: minCanvasY,
      );
      final labelWorldY = renderCenter.y + (labelCanvasTop - size.y / 2) / zoom;
      painter.paint(canvas, Offset(center.dx - painter.width / 2, labelWorldY));
    }
  }

  void _drawPlayerDeathMark(
    Canvas canvas,
    Offset center,
    double age,
    double alpha,
    double zoom,
  ) {
    final paint = Paint()
      ..color = _deathAccent.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 / zoom
      ..isAntiAlias = false;
    final radius = (10 + age * 22) / zoom;
    if (cosmeticLoadout.deathEffectId == 'death_fracture') {
      for (var index = 0; index < 4; index++) {
        final angle = math.pi / 4 + index * math.pi / 2;
        final direction = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(
          center + direction * (4 / zoom),
          center + direction * radius,
          paint,
        );
      }
      return;
    }
    canvas.drawCircle(center, radius, paint);
  }

  void _drawRelayTape(Canvas canvas, double zoom) {
    final progress =
        ((_handoffElapsed - HandoffTimeline.successorScanEnd) /
                (HandoffTimeline.relayTravelEnd -
                    HandoffTimeline.successorScanEnd))
            .clamp(0.0, 1.0);
    if (progress <= 0) return;
    final start = Offset(_handoffFrom.x, _handoffFrom.y);
    final end = Offset(_handoffTo.x, _handoffTo.y);
    final delta = end - start;
    final path = Path()..moveTo(start.dx, start.dy);
    if (lowSpecMode) {
      path.lineTo(end.dx, end.dy);
    } else {
      path.cubicTo(
        start.dx + delta.dx * .28,
        start.dy - 120,
        start.dx + delta.dx * .72,
        start.dy + delta.dy * .72 + 95,
        end.dx,
        end.dy,
      );
    }
    final metrics = path.computeMetrics().iterator;
    if (!metrics.moveNext()) return;
    final metric = metrics.current;
    if (metric.length <= 0) return;
    final partial = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(
      partial,
      Paint()
        ..color = TokenfrontColors.relayIvory
        ..style = PaintingStyle.stroke
        ..strokeWidth = (lowSpecMode ? 2.5 : 4.5) / zoom
        ..strokeCap = StrokeCap.square
        ..strokeJoin = StrokeJoin.miter
        ..isAntiAlias = false,
    );
  }

  @override
  void onRemove() {
    if (!_hudDisposed) {
      hud.dispose();
      _hudDisposed = true;
    }
    super.onRemove();
  }
}
