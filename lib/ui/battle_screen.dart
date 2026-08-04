import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter/services.dart';

import '../design/tokens.dart';
import '../game/faction_visuals.dart';
import '../game/simulation.dart';
import '../game/tokenfront_game.dart';
import '../l10n/l10n.dart';
import '../settings/game_preferences.dart';
import '../story/story_models.dart';
import 'primitives.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({
    super.key,
    required this.game,
    this.preferences,
    this.requireLandscape = false,
    this.observeLifecycle = true,
    this.lifecycleState = AppLifecycleState.resumed,
  });

  final TokenfrontGame game;
  final GamePreferences? preferences;
  final bool requireLandscape;
  final bool observeLifecycle;
  final AppLifecycleState lifecycleState;

  @override
  State<BattleScreen> createState() => BattleScreenState();
}

class BattleScreenState extends State<BattleScreen>
    with WidgetsBindingObserver {
  int? _mousePanPointer;
  bool _lifecyclePaused = false;
  bool _userPaused = false;
  bool _disposing = false;

  TokenfrontGame get game => widget.game;
  bool get _gameplayInputEnabled =>
      !_lifecyclePaused && !_userPaused && !game.paused;

  @override
  void initState() {
    super.initState();
    if (widget.observeLifecycle) WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    handleLifecycleState(state);
  }

  @override
  void didUpdateWidget(covariant BattleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lifecycleState != widget.lifecycleState &&
        !widget.observeLifecycle) {
      handleLifecycleState(widget.lifecycleState);
    }
    if (oldWidget.game != game) {
      oldWidget.game.clearInputs();
      oldWidget.game.endMouseCameraPan();
      oldWidget.game.endMinimapCameraPan();
      _mousePanPointer = null;
      FocusManager.instance.primaryFocus?.unfocus(
        disposition: UnfocusDisposition.scope,
      );
      // Flame removes the old game from the GameWidget during this update.
      // Dispose only after that subtree has finished updating so focus and
      // input callbacks cannot reach a disposed game.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.game != oldWidget.game) {
          oldWidget.game.dispose();
        }
      });
    }
  }

  /// Called by the single lifecycle owner ([TokenfrontRoot]).
  void handleLifecycleState(AppLifecycleState state) {
    if (!mounted || _disposing) return;
    final paused = state != AppLifecycleState.resumed;
    if (paused) {
      game.clearInputs();
      game.endMouseCameraPan();
      game.endMinimapCameraPan();
      _mousePanPointer = null;
      if (!game.paused) game.pauseEngine();
    } else if (!_userPaused && game.paused) {
      game.resumeEngine();
    }
    if (mounted) {
      setState(() => _lifecyclePaused = paused);
      if (widget.observeLifecycle) {
        WidgetsBinding.instance.scheduleForcedFrame();
      }
    }
  }

  void _toggleUserPause() {
    if (_lifecyclePaused) return;
    if (_userPaused) {
      game.resumeEngine();
      setState(() => _userPaused = false);
    } else {
      game.clearInputs();
      game.endMouseCameraPan();
      game.endMinimapCameraPan();
      _mousePanPointer = null;
      game.pauseEngine();
      setState(() => _userPaused = true);
    }
  }

  bool _isMousePanButton(int buttons) =>
      buttons & (kPrimaryMouseButton | kMiddleMouseButton) != 0;

  void _onPointerDown(PointerDownEvent event) {
    if (!_gameplayInputEnabled ||
        event.kind != PointerDeviceKind.mouse ||
        !game.mouseCameraEnabled ||
        !_isMousePanButton(event.buttons)) {
      return;
    }
    _mousePanPointer = event.pointer;
    game.beginMouseCameraPan();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_gameplayInputEnabled && event.pointer == _mousePanPointer) {
      game.updateMouseCameraPan(event.delta);
    }
  }

  void _endMousePan(int pointer) {
    if (pointer != _mousePanPointer) return;
    _mousePanPointer = null;
    game.endMouseCameraPan();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (_gameplayInputEnabled &&
        event is PointerScrollEvent &&
        event.kind == PointerDeviceKind.mouse) {
      game.applyMouseWheel(event.scrollDelta.dy);
    }
  }

  @override
  void dispose() {
    _disposing = true;
    if (widget.observeLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
    }
    FocusManager.instance.primaryFocus?.unfocus(
      disposition: UnfocusDisposition.scope,
    );
    game.clearInputs();
    game.endMouseCameraPan();
    game.endMinimapCameraPan();
    game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) => _gameplayInputEnabled
          ? game.onFocusedMovementKeyEvent(event)
          : KeyEventResult.ignored,
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (widget.requireLandscape &&
                constraints.maxHeight > constraints.maxWidth) {
              game.clearInputs();
              game.endMouseCameraPan();
              game.endMinimapCameraPan();
              _mousePanPointer = null;
              return Stack(
                fit: StackFit.expand,
                children: [
                  const _LandscapeRequired(),
                  if (_lifecyclePaused || game.paused)
                    Center(child: _PausedReadout(userPaused: _userPaused)),
                ],
              );
            }
            final compact = constraints.maxWidth < 620;
            final short = constraints.maxHeight < 560;
            final compactControls = compact || short;
            final joystickSize = compactControls ? 104.0 : 112.0;
            final dashSize = compactControls ? 72.0 : 78.0;
            final minimapWidth = (constraints.maxWidth * (short ? .20 : .18))
                .clamp(short ? 118.0 : 148.0, short ? 170.0 : 220.0)
                .toDouble();
            final minimapHeight =
                minimapWidth *
                game.simulation.config.worldHeight /
                game.simulation.config.worldWidth;
            return Stack(
              fit: StackFit.expand,
              children: [
                Listener(
                  key: const Key('battle-game-surface'),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: (event) => _endMousePan(event.pointer),
                  onPointerCancel: (event) => _endMousePan(event.pointer),
                  onPointerSignal: _onPointerSignal,
                  child: GameWidget<TokenfrontGame>(
                    game: game,
                    autofocus: true,
                  ),
                ),
                SafeArea(
                  minimum: EdgeInsets.all(short ? 6 : 10),
                  child: ValueListenableBuilder<BattleHudSnapshot>(
                    valueListenable: game.hud,
                    builder: (context, snapshot, _) => Stack(
                      fit: StackFit.expand,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: _CommandRail(
                            snapshot: snapshot,
                            compact: compact,
                          ),
                        ),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: compact ? (short ? 6 : 10) : 10,
                              left: 10,
                            ),
                            child: _PauseButton(
                              paused: _userPaused,
                              enabled: !_lifecyclePaused,
                              onPressed: _toggleUserPause,
                            ),
                          ),
                        ),
                        if (snapshot.directiveProgress != null)
                          Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: compact ? (short ? 62 : 72) : 58,
                              ),
                              child: _DirectiveRail(
                                game: game,
                                snapshot: snapshot,
                                compact: compact,
                              ),
                            ),
                          ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: compact ? (short ? 66 : 78) : 0,
                            ),
                            child: _ViewRail(
                              game: game,
                              snapshot: snapshot,
                              vertical: compact,
                              preferences: widget.preferences,
                              enabled: _gameplayInputEnabled,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: _PlayerControls(
                            game: game,
                            snapshot: snapshot,
                            joystickSize: joystickSize,
                            compact: compactControls,
                            enabled: _gameplayInputEnabled,
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: minimapWidth + 10),
                            child: _DashControl(
                              game: game,
                              size: dashSize,
                              enabled: _gameplayInputEnabled,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: _BattleMinimap(
                            game: game,
                            snapshot: snapshot,
                            width: minimapWidth,
                            height: minimapHeight,
                            enabled: _gameplayInputEnabled,
                          ),
                        ),
                        if (snapshot.handoffProgress case final progress?)
                          Center(
                            child: _RelayReadout(
                              progress: progress,
                              stage:
                                  snapshot.handoffStage ??
                                  HandoffStage.impactHold,
                              reduceMotion: game.reduceMotion,
                            ),
                          ),
                        if (snapshot.playerEliminated)
                          Align(
                            alignment: const Alignment(0, -.68),
                            child: TacticalPanel(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              borderColor: TokenfrontColors.danger,
                              child: Text(
                                context.l10n.signalLostObserving,
                                style: TokenfrontType.instrument.copyWith(
                                  color: TokenfrontColors.danger,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        if (game.paused)
                          Center(
                            child: _PausedReadout(userPaused: _userPaused),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _LandscapeRequired extends StatelessWidget {
  const _LandscapeRequired();

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const Key('landscape-required'),
    color: TokenfrontColors.deepField,
    child: SafeArea(
      minimum: const EdgeInsets.all(24),
      child: Center(
        child: Semantics(
          liveRegion: true,
          label: context.l10n.rotateToPlay,
          hint: context.l10n.rotateToPlayHint,
          child: ExcludeSemantics(
            child: TacticalPanel(
              borderColor: TokenfrontColors.relayIvory,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.screen_rotation_outlined,
                    color: TokenfrontColors.relayIvory,
                    size: 42,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.rotateToPlay,
                    textAlign: TextAlign.center,
                    style: TokenfrontType.instrument.copyWith(
                      color: TokenfrontColors.relayIvory,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.rotateToPlayHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: TokenfrontColors.quietText,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CommandRail extends StatelessWidget {
  const _CommandRail({required this.snapshot, required this.compact});
  final BattleHudSnapshot snapshot;
  final bool compact;

  String get time {
    final seconds = snapshot.remaining.ceil();
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  String semanticsLabel(BuildContext context) => [
    context.l10n.timeRemaining(time),
    for (final faction in Faction.values)
      context.l10n.factionAlive(
        faction.visual.name,
        snapshot.aliveByFaction[faction] ?? 0,
      ),
  ].join(', ');

  Widget get factionCounts => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: compact ? 10 : 0,
    runSpacing: 5,
    children: [
      for (final faction in Faction.values) ...[
        _FactionCount(
          faction: faction,
          count: snapshot.aliveByFaction[faction] ?? 0,
        ),
        if (!compact && faction != Faction.values.last)
          Container(
            width: 1,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 7),
            color: TokenfrontColors.relayIvory.withValues(alpha: .16),
          ),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: semanticsLabel(context),
    child: ExcludeSemantics(
      child: TacticalPanel(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 11,
          vertical: compact ? 7 : 9,
        ),
        color: TokenfrontColors.deepField.withValues(alpha: .84),
        child: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TokenfrontType.instrument.copyWith(
                      color: TokenfrontColors.relayIvory,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  factionCounts,
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  factionCounts,
                  Container(
                    width: 1,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: TokenfrontColors.relayIvory.withValues(alpha: .35),
                  ),
                  Text(
                    time,
                    style: TokenfrontType.instrument.copyWith(
                      color: TokenfrontColors.relayIvory,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

/// The Chronicle objective is deliberately a read-only rail.  The animated
/// panel is excluded from semantics and a separate, stable live-region label
/// changes only at operation start, its midpoint, and completion.
class _DirectiveRail extends StatefulWidget {
  const _DirectiveRail({
    required this.game,
    required this.snapshot,
    required this.compact,
  });

  final TokenfrontGame game;
  final BattleHudSnapshot snapshot;
  final bool compact;

  @override
  State<_DirectiveRail> createState() => _DirectiveRailState();
}

class _DirectiveRailState extends State<_DirectiveRail> {
  Timer? _cueTimer;
  bool _cueActive = false;
  int _announcedMilestone = -1;

  DirectiveProgress get progress => widget.snapshot.directiveProgress!;

  @override
  void initState() {
    super.initState();
    _announcedMilestone = _milestoneFor(progress);
    // Localized copy is unavailable during initState; announce after the
    // first frame once Localizations has attached to this subtree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _queueAnnouncement(progress, _announcedMilestone);
    });
    if (_isBattleComplete(progress)) _startCueIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _DirectiveRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isBattleComplete(oldWidget.snapshot.directiveProgress!) &&
        _isBattleComplete(progress)) {
      _startCueIfNeeded();
    }
    final nextMilestone = _milestoneFor(progress);
    if (nextMilestone != _announcedMilestone) {
      _announcedMilestone = nextMilestone;
      _queueAnnouncement(progress, nextMilestone);
    }
    if (widget.game.reduceMotion || widget.game.lowSpecMode) {
      _cueTimer?.cancel();
      _cueTimer = null;
      _cueActive = false;
    }
  }

  void _queueAnnouncement(DirectiveProgress value, int milestone) {
    final label = _labelFor(value, milestone);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          label,
          Directionality.of(context),
        ),
      );
    });
  }

  int _milestoneFor(DirectiveProgress value) {
    // Final rank is provisional until the BattleReport is created. A good
    // transient rank must never announce the irreversible completion cue.
    if (value.kind == DirectiveKind.finalRank) {
      return value.current <= value.target ? 1 : 0;
    }
    if (value.completed) return 2;
    if (value.current <= 0) return 0;
    final midpoint = math.max(1, (value.target / 2).floor());
    return value.current >= midpoint ? 1 : 0;
  }

  String _labelFor(DirectiveProgress value, int milestone) {
    final name = _directiveName(context, value.kind);
    final target = value.target.round();
    if (value.kind == DirectiveKind.finalRank) {
      final current = value.current.round();
      return value.current <= value.target
          ? context.l10n.directiveOnTrack(
              context.l10n.directive,
              name,
              current,
              target,
            )
          : context.l10n.directivePending(
              context.l10n.directive,
              name,
              current,
              target,
            );
    }
    if (milestone == 2) return context.l10n.directiveLocked;
    final current = milestone == 1
        ? (value.target / 2).floor().clamp(1, target)
        : 0;
    return context.l10n.directiveLiveProgress(
      context.l10n.directive,
      name,
      current,
      target,
    );
  }

  bool _isBattleComplete(DirectiveProgress value) =>
      value.kind != DirectiveKind.finalRank && value.completed;

  void _startCueIfNeeded() {
    if (!progress.completed ||
        widget.game.reduceMotion ||
        widget.game.lowSpecMode) {
      return;
    }
    _cueTimer?.cancel();
    if (mounted) setState(() => _cueActive = true);
    _cueTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _cueActive = false);
    });
  }

  @override
  void dispose() {
    _cueTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = progress;
    final milestone = _milestoneFor(value);
    final completed = _isBattleComplete(value);
    final current = value.current.round().clamp(0, value.target.round());
    final target = value.target.round();
    final name = _directiveName(context, value.kind);
    final text = completed
        ? context.l10n.directiveLocked
        : value.kind == DirectiveKind.finalRank
        ? value.current <= value.target
              ? context.l10n.directiveOnTrack(
                  context.l10n.directive,
                  name,
                  value.current.round(),
                  target,
                )
              : context.l10n.directivePending(
                  context.l10n.directive,
                  name,
                  value.current.round(),
                  target,
                )
        : context.l10n.directiveLiveProgress(
            context.l10n.directive,
            name,
            current,
            target,
          );
    return IgnorePointer(
      child: Semantics(
        key: Key('directive-rail-semantics-$milestone'),
        container: true,
        label: _labelFor(value, milestone),
        child: ExcludeSemantics(
          child: AnimatedContainer(
            key: const Key('directive-rail'),
            duration: widget.game.reduceMotion || widget.game.lowSpecMode
                ? Duration.zero
                : const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 12,
              vertical: widget.compact ? 5 : 6,
            ),
            decoration: BoxDecoration(
              color: TokenfrontColors.deepField.withValues(alpha: .9),
              border: Border.all(
                color:
                    _cueActive ||
                        (completed &&
                            (widget.game.reduceMotion ||
                                widget.game.lowSpecMode))
                    ? TokenfrontColors.volt
                    : TokenfrontColors.relayIvory.withValues(alpha: .32),
                width: completed || _cueActive ? 1.5 : 1,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            child: Text(
              text,
              style: TokenfrontType.instrument.copyWith(
                color: completed
                    ? TokenfrontColors.volt
                    : TokenfrontColors.relayIvory,
                fontSize: widget.compact ? 9 : 10,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _directiveName(BuildContext context, DirectiveKind kind) =>
    switch (kind) {
      DirectiveKind.longestCommandLink =>
        context.l10n.directiveNameLongestCommandLink,
      DirectiveKind.commandRelays => context.l10n.directiveNameCommandRelays,
      DirectiveKind.commandKills => context.l10n.directiveNameCommandKills,
      DirectiveKind.finalRank => context.l10n.directiveNameFinalRank,
      DirectiveKind.victory => context.l10n.directiveNameVictory,
    };

class _ViewRail extends StatelessWidget {
  const _ViewRail({
    required this.game,
    required this.snapshot,
    required this.vertical,
    required this.preferences,
    required this.enabled,
  });

  final TokenfrontGame game;
  final BattleHudSnapshot snapshot;
  final bool vertical;
  final GamePreferences? preferences;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final controls = <Widget>[
      TacticalToggle(
        label: context.l10n.cameraShort,
        semanticLabel: context.l10n.mouseCameraSemantics,
        selected: snapshot.mouseCameraEnabled,
        onPressed: enabled
            ? () {
                final cameraEnabled = !snapshot.mouseCameraEnabled;
                game.setMouseCameraEnabled(cameraEnabled);
                preferences?.setMouseCameraEnabled(cameraEnabled);
              }
            : null,
      ),
      TacticalToggle(
        label: context.l10n.ecoShort,
        semanticLabel: context.l10n.lowPowerModeSemantics,
        selected: snapshot.lowSpecMode,
        onPressed: enabled
            ? () {
                final lowSpecEnabled = !snapshot.lowSpecMode;
                game.setLowSpecMode(lowSpecEnabled);
                preferences?.setLowSpecMode(lowSpecEnabled);
              }
            : null,
      ),
      TacticalToggle(
        label: context.l10n.lockShort,
        semanticLabel: context.l10n.resetCameraSemantics,
        selected: null,
        onPressed: enabled ? game.resetCameraView : null,
      ),
    ];
    return TacticalPanel(
      padding: const EdgeInsets.all(4),
      color: TokenfrontColors.deepField.withValues(alpha: .78),
      child: vertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < controls.length; index++) ...[
                  controls[index],
                  if (index != controls.length - 1) const SizedBox(height: 3),
                ],
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < controls.length; index++) ...[
                  controls[index],
                  if (index != controls.length - 1) const SizedBox(width: 3),
                ],
              ],
            ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({
    required this.paused,
    required this.enabled,
    required this.onPressed,
  });

  final bool paused;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    key: const Key('battle-pause'),
    button: true,
    enabled: enabled,
    excludeSemantics: true,
    label: paused ? context.l10n.resumeBattle : context.l10n.pauseBattle,
    hint: context.l10n.pauseBattleSemantics,
    child: TacticalButton(
      label: paused ? context.l10n.resumeBattle : context.l10n.pauseBattle,
      onPressed: enabled ? onPressed : null,
      color: TokenfrontColors.relayIvory,
    ),
  );
}

class _PausedReadout extends StatelessWidget {
  const _PausedReadout({required this.userPaused});

  final bool userPaused;

  @override
  Widget build(BuildContext context) => Semantics(
    label: userPaused
        ? context.l10n.pauseBattleSemantics
        : context.l10n.battlePausedSemantics,
    child: TacticalPanel(
      borderColor: TokenfrontColors.relayIvory,
      color: TokenfrontColors.deepField.withValues(alpha: .94),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Text(
        context.l10n.battlePaused,
        style: TokenfrontType.instrument.copyWith(fontSize: 11),
      ),
    ),
  );
}

class _FactionCount extends StatelessWidget {
  const _FactionCount({required this.faction, required this.count});
  final Faction faction;
  final int count;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '${faction.visual.mark} ',
          style: TextStyle(color: faction.visual.color),
        ),
        TextSpan(text: count.toString().padLeft(3, '0')),
      ],
    ),
    style: TokenfrontType.instrument.copyWith(fontSize: 11),
  );
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({
    required this.game,
    required this.snapshot,
    required this.joystickSize,
    required this.compact,
    required this.enabled,
  });
  final TokenfrontGame game;
  final BattleHudSnapshot snapshot;
  final double joystickSize;
  final bool compact;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        container: true,
        label: context.l10n.controlledUnitStatus(
          snapshot.currentLevel,
          snapshot.currentKills,
          snapshot.relayCount,
        ),
        child: ExcludeSemantics(
          child: TacticalPanel(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 9 : 12,
              vertical: compact ? 7 : 9,
            ),
            color: TokenfrontColors.deepField.withValues(alpha: .78),
            child: Text(
              context.l10n.controlledUnitVisualStatus(
                snapshot.currentLevel.toString().padLeft(2, '0'),
                snapshot.currentKills.toString().padLeft(2, '0'),
                snapshot.relayCount.toString().padLeft(2, '0'),
              ),
              style: TokenfrontType.instrument.copyWith(
                fontSize: compact ? 10 : 11,
              ),
            ),
          ),
        ),
      ),
      SizedBox(height: compact ? 5 : 8),
      _VirtualJoystick(
        size: joystickSize,
        enabled: enabled,
        onChanged: game.setTouchInput,
      ),
    ],
  );
}

class _VirtualJoystick extends StatefulWidget {
  const _VirtualJoystick({
    required this.size,
    required this.enabled,
    required this.onChanged,
  });
  final double size;
  final bool enabled;
  final ValueChanged<Vec2> onChanged;

  @override
  State<_VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<_VirtualJoystick> {
  Offset knob = Offset.zero;
  int? activePointer;

  double get radius => widget.size * .32;

  void update(Offset localPosition) {
    final raw = localPosition - Offset(widget.size / 2, widget.size / 2);
    final distance = raw.distance;
    final clamped = distance > radius ? raw / distance * radius : raw;
    setState(() => knob = clamped);
    widget.onChanged(Vec2(clamped.dx / radius, clamped.dy / radius));
  }

  void reset() {
    activePointer = null;
    if (!mounted) return;
    setState(() => knob = Offset.zero);
    widget.onChanged(Vec2.zero);
  }

  @override
  void dispose() {
    activePointer = null;
    widget.onChanged(Vec2.zero);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.movementJoystick,
    hint: context.l10n.movementJoystickHint,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (!widget.enabled) return;
        if (activePointer != null) return;
        activePointer = event.pointer;
        update(event.localPosition);
      },
      onPointerMove: (event) {
        if (!widget.enabled) return;
        if (event.pointer == activePointer) update(event.localPosition);
      },
      onPointerUp: (event) {
        if (event.pointer == activePointer) reset();
      },
      onPointerCancel: (event) {
        if (event.pointer == activePointer) reset();
      },
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _JoystickPainter(knob, compact: widget.size < 100),
        ),
      ),
    ),
  );
}

class _JoystickPainter extends CustomPainter {
  const _JoystickPainter(this.knob, {required this.compact});
  final Offset knob;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = Paint()
      ..color = TokenfrontColors.deepField.withValues(alpha: .72)
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = TokenfrontColors.relayIvory.withValues(alpha: .46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = false;
    final ringRadius = size.shortestSide * .43;
    final crossExtent = ringRadius * .8;
    canvas.drawCircle(center, ringRadius, base);
    canvas.drawCircle(center, ringRadius, line);
    canvas.drawLine(
      center + Offset(-crossExtent, 0),
      center + Offset(crossExtent, 0),
      line,
    );
    canvas.drawLine(
      center + Offset(0, -crossExtent),
      center + Offset(0, crossExtent),
      line,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: center + knob,
        width: compact ? 18 : 22,
        height: compact ? 18 : 22,
      ),
      Paint()
        ..color = TokenfrontColors.relayIvory.withValues(alpha: .9)
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) =>
      oldDelegate.knob != knob || oldDelegate.compact != compact;
}

class _DashControl extends StatefulWidget {
  const _DashControl({
    required this.game,
    required this.size,
    required this.enabled,
  });
  final TokenfrontGame game;
  final double size;
  final bool enabled;

  @override
  State<_DashControl> createState() => _DashControlState();
}

class _DashControlState extends State<_DashControl> {
  bool focused = false;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, right: 4),
    child: Semantics(
      label: context.l10n.dashSemantics,
      hint: context.l10n.dashHint,
      button: true,
      enabled: widget.enabled,
      child: ExcludeSemantics(
        child: Material(
          color: widget.game.playerFaction.visual.color.withValues(alpha: .88),
          shape: BeveledRectangleBorder(
            side: BorderSide(
              color: focused
                  ? TokenfrontColors.relayIvory
                  : TokenfrontColors.deepField.withValues(alpha: .38),
              width: focused ? 3 : 1,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(16)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.enabled ? widget.game.triggerDash : null,
            canRequestFocus: true,
            focusColor: TokenfrontColors.relayIvory.withValues(alpha: .28),
            onFocusChange: (value) {
              if (mounted && value != focused) setState(() => focused = value);
            },
            child: SizedBox.square(
              dimension: widget.size,
              child: Center(
                child: Text(
                  context.l10n.dashKeyLabel,
                  textAlign: TextAlign.center,
                  style: TokenfrontType.instrument.copyWith(
                    color: TokenfrontColors.deepField,
                    fontSize: widget.size < 64 ? 8 : 10,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _BattleMinimap extends StatefulWidget {
  const _BattleMinimap({
    required this.game,
    required this.snapshot,
    required this.width,
    required this.height,
    required this.enabled,
  });

  final TokenfrontGame game;
  final BattleHudSnapshot snapshot;
  final double width;
  final double height;
  final bool enabled;

  @override
  State<_BattleMinimap> createState() => _BattleMinimapState();
}

class _BattleMinimapState extends State<_BattleMinimap> {
  int? activePointer;
  int inputRevision = 0;
  bool focused = false;
  final FocusNode focusNode = FocusNode(debugLabel: 'battle-minimap');
  final List<List<Offset>> pointBuffers = List<List<Offset>>.generate(
    Faction.values.length,
    (_) => <Offset>[],
    growable: false,
  );

  @override
  void didUpdateWidget(covariant _BattleMinimap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.endMinimapCameraPan();
      activePointer = null;
    }
  }

  void updateCamera(Offset localPosition) {
    final x = (localPosition.dx / widget.width).clamp(0.0, 1.0);
    final y = (localPosition.dy / widget.height).clamp(0.0, 1.0);
    widget.game.updateMinimapCamera(
      Vec2(
        x * widget.game.simulation.config.worldWidth,
        y * widget.game.simulation.config.worldHeight,
      ),
    );
    setState(() => inputRevision += 1);
  }

  void endPointer(int pointer) {
    if (pointer != activePointer) return;
    activePointer = null;
    widget.game.endMinimapCameraPan();
  }

  KeyEventResult handleKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final config = widget.game.simulation.config;
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => Vec2(-config.worldWidth * .08, 0),
      LogicalKeyboardKey.arrowRight => Vec2(config.worldWidth * .08, 0),
      LogicalKeyboardKey.arrowUp => Vec2(0, -config.worldHeight * .08),
      LogicalKeyboardKey.arrowDown => Vec2(0, config.worldHeight * .08),
      _ => null,
    };
    if (delta == null) return KeyEventResult.ignored;
    widget.game.nudgeMinimapCamera(delta);
    setState(() => inputRevision += 1);
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    focusNode.unfocus(disposition: UnfocusDisposition.scope);
    widget.game.endMinimapCameraPan();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.tacticalMapSemantics,
    hint: context.l10n.tacticalMapHint,
    button: true,
    enabled: widget.enabled,
    onTap: widget.enabled ? widget.game.resetCameraView : null,
    child: Focus(
      focusNode: focusNode,
      onKeyEvent: handleKey,
      onFocusChange: (value) {
        if (mounted && value != focused) setState(() => focused = value);
      },
      child: RepaintBoundary(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            if (!widget.enabled) return;
            if (activePointer != null) return;
            focusNode.requestFocus();
            activePointer = event.pointer;
            widget.game.beginMinimapCameraPan();
            updateCamera(event.localPosition);
          },
          onPointerMove: (event) {
            if (!widget.enabled) return;
            if (event.pointer == activePointer) {
              updateCamera(event.localPosition);
            }
          },
          onPointerUp: (event) => endPointer(event.pointer),
          onPointerCancel: (event) => endPointer(event.pointer),
          child: SizedBox(
            key: const Key('battle-minimap'),
            width: widget.width,
            height: widget.height,
            child: ClipRect(
              child: CustomPaint(
                painter: _MinimapPainter(
                  game: widget.game,
                  focused: focused,
                  pointBuffers: pointBuffers,
                  revision: Object.hash(
                    widget.snapshot.elapsed,
                    inputRevision,
                    widget.snapshot.cameraZoom,
                    focused,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MinimapPainter extends CustomPainter {
  const _MinimapPainter({
    required this.game,
    required this.focused,
    required this.pointBuffers,
    required this.revision,
  });

  final TokenfrontGame game;
  final bool focused;
  final List<List<Offset>> pointBuffers;
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    final config = game.simulation.config;
    Offset mapPoint(Vec2 point) => Offset(
      point.x / config.worldWidth * size.width,
      point.y / config.worldHeight * size.height,
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = TokenfrontColors.deepField.withValues(alpha: .92)
        ..isAntiAlias = false,
    );
    final gridPaint = Paint()
      ..color = TokenfrontColors.relayIvory.withValues(alpha: .09)
      ..strokeWidth = 1
      ..isAntiAlias = false;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      gridPaint,
    );

    for (final points in pointBuffers) {
      points.clear();
    }
    for (final unit in game.simulation.units) {
      if (unit.alive) {
        pointBuffers[unit.faction.index].add(mapPoint(unit.position));
      }
    }
    for (final faction in Faction.values) {
      final points = pointBuffers[faction.index];
      if (points.isEmpty) continue;
      canvas.drawPoints(
        ui.PointMode.points,
        points,
        Paint()
          ..color = faction.visual.color.withValues(alpha: .88)
          ..strokeWidth = game.lowSpecMode
              ? 1.5
              : switch (faction) {
                  Faction.amethyst => 2.0,
                  Faction.cobalt => 2.2,
                  Faction.volt => 1.25,
                  Faction.prism => 3.0,
                }
          ..strokeCap = faction.index.isEven
              ? StrokeCap.square
              : StrokeCap.round
          ..isAntiAlias = false,
      );
    }

    final viewport = game.visibleWorldBounds;
    if (!viewport.isEmpty) {
      canvas.drawRect(
        Rect.fromLTRB(
          viewport.left / config.worldWidth * size.width,
          viewport.top / config.worldHeight * size.height,
          viewport.right / config.worldWidth * size.width,
          viewport.bottom / config.worldHeight * size.height,
        ),
        Paint()
          ..color = TokenfrontColors.relayIvory.withValues(alpha: .88)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..isAntiAlias = false,
      );
    }

    final controlled = game.simulation.controlledUnit;
    if (controlled != null && controlled.alive) {
      final center = mapPoint(controlled.position);
      canvas.drawCircle(
        center,
        4,
        Paint()
          ..color = TokenfrontColors.deepField
          ..style = PaintingStyle.fill
          ..isAntiAlias = false,
      );
      canvas.drawCircle(
        center,
        3,
        Paint()
          ..color = TokenfrontColors.relayIvory
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..isAntiAlias = false,
      );
    }

    canvas.drawRect(
      (Offset.zero & size).deflate(.75),
      Paint()
        ..color = focused
            ? TokenfrontColors.relayIvory
            : TokenfrontColors.relayIvory.withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = focused ? 3 : 1.5
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) =>
      oldDelegate.game != game ||
      oldDelegate.focused != focused ||
      oldDelegate.revision != revision;
}

class _RelayReadout extends StatelessWidget {
  const _RelayReadout({
    required this.progress,
    required this.stage,
    required this.reduceMotion,
  });
  final double progress;
  final HandoffStage stage;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final stageLabel = _handoffLabel(context.l10n, stage);
    final percent = (progress * 100).round();
    return IgnorePointer(
      child: Semantics(
        label: context.l10n.commandHandoff(stageLabel, percent),
        child: Opacity(
          opacity: reduceMotion
              ? 1
              : math.sin(progress * math.pi).clamp(.18, 1.0),
          child: TacticalPanel(
            color: TokenfrontColors.deepField.withValues(alpha: .82),
            borderColor: TokenfrontColors.relayIvory,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(
              '$stageLabel  ${percent.toString().padLeft(3, '0')}%',
              style: TokenfrontType.instrument.copyWith(fontSize: 10),
            ),
          ),
        ),
      ),
    );
  }
}

String _handoffLabel(AppLocalizations l10n, HandoffStage stage) =>
    switch (stage) {
      HandoffStage.impactHold => l10n.handoffImpactHold,
      HandoffStage.casualtyFocus => l10n.handoffCasualtyFocus,
      HandoffStage.successorScan => l10n.handoffSuccessorScan,
      HandoffStage.relayTravel => l10n.handoffRelayTravel,
      HandoffStage.signalLock => l10n.handoffSignalLock,
    };
