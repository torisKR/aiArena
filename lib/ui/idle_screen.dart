import 'dart:async';

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../idle/idle_domain.dart';
import '../idle/idle_persistence.dart';
import '../idle/idle_state_store.dart';
import '../l10n/l10n.dart';
import 'primitives.dart';

class IdleScreen extends StatefulWidget {
  const IdleScreen({super.key, required this.onBack, this.repositoryFactory});
  final VoidCallback onBack;
  final IdleRepository Function()? repositoryFactory;

  @override
  State<IdleScreen> createState() => _IdleScreenState();
}

class _IdleScreenState extends State<IdleScreen> {
  late final IdleRepository repository = widget.repositoryFactory?.call() ??
      IdleRepository(_SharedIdleStore(), DateTime.now);
  Timer? _ticker;
  IdleSettlement? lastClaim;
  bool ready = false;
  bool loadError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await repository.initialize();
    } on Object {
      if (mounted) setState(() => loadError = true);
      return;
    }
    if (!mounted) return;
    setState(() {
      ready = true;
      loadError = false;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _claim());
  }

  Future<void> _retryLoad() async {
    if (!mounted) return;
    setState(() => loadError = false);
    await _load();
  }

  Future<void> _claim() async {
    if (!ready) return;
    final settlement = await repository.claim();
    if (mounted) setState(() => lastClaim = settlement);
  }

  Future<void> _upgrade() async {
    if (await repository.upgrade() && mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    if (!ready) {
      if (loadError) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(copy.retryDirective),
                const SizedBox(height: TokenfrontSpacing.md),
                TacticalButton(
                  key: const Key('idle-save-retry'),
                  label: copy.retryDirective,
                  onPressed: _retryLoad,
                ),
              ],
            ),
          ),
        );
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final state = repository.state;
    final cost = IdleSimulation.upgradeCost(state.coreLevel);
    final progress = state.progress / IdleSimulation.stageGoal;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(TokenfrontSpacing.lg),
              child: Row(
                children: [
                  IconButton(
                    tooltip: copy.idleBack,
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      copy.idleMode,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TokenfrontType.display.copyWith(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: TokenfrontSpacing.sm),
                  Flexible(
                    child: Text(
                      '${state.credits} ${copy.idleCredits}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(TokenfrontSpacing.lg, 0, TokenfrontSpacing.lg, TokenfrontSpacing.lg),
                children: [
                  Semantics(
                    container: true,
                    label: copy.idleBattleSemantics(state.stage),
                    child: TacticalPanel(
                      color: TokenfrontColors.deepField,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(copy.idleBattle, style: TokenfrontType.instrument),
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: TokenfrontSpacing.xs,
                            children: [
                              Text(copy.idleStage(state.stage), style: TokenfrontType.display.copyWith(fontSize: 26)),
                              Text(copy.idleAutoCombat, style: TokenfrontType.instrument.copyWith(color: TokenfrontColors.volt)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(value: progress.clamp(0, 1).toDouble(), minHeight: 10),
                          const SizedBox(height: 8),
                          Text(copy.idleProgress(state.progress, IdleSimulation.stageGoal)),
                          if (lastClaim != null && lastClaim!.creditsEarned > 0)
                            Text(copy.idleClaimed(lastClaim!.creditsEarned), style: TokenfrontType.body.copyWith(color: TokenfrontColors.volt)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: TokenfrontSpacing.lg),
                  TacticalPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(copy.idleNextGoal, style: TokenfrontType.instrument),
                        const SizedBox(height: 6),
                        Text(copy.idleGoalBody, style: TokenfrontType.body),
                      ],
                    ),
                  ),
                  const SizedBox(height: TokenfrontSpacing.lg),
                  TacticalPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(copy.idleCoreLevel(state.coreLevel), style: TokenfrontType.display.copyWith(fontSize: 22)),
                        const SizedBox(height: 6),
                        Text(copy.idleUpgradeDetail, style: TokenfrontType.body),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: TacticalButton(
                            key: const Key('idle-upgrade'),
                            label: copy.idleUpgrade(cost),
                            onPressed: state.credits >= cost ? _upgrade : null,
                            color: TokenfrontColors.volt,
                            expanded: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Adapter keeps idle persistence isolated from the existing Tokenfront state key.
final class _SharedIdleStore implements IdleStateStore {
  final _delegate = SharedPreferencesIdleStateStore();
  @override
  Future<String?> read(String key) => _delegate.read(key);
  @override
  Future<void> write(String key, String value) => _delegate.write(key, value);
}
