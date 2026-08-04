import 'package:flutter/material.dart';

import '../app/tokenfront_runtime.dart';
import '../design/tokens.dart';
import '../game/faction_visuals.dart';
import '../game/simulation.dart';
import '../l10n/l10n.dart';
import '../services/ads/ad_service.dart';
import 'primitives.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.matchId,
    required this.playerFaction,
    required this.relays,
    required this.elapsed,
    required this.baseReward,
    required this.warTokenBalance,
    required this.bannerVisible,
    required this.onDoubleReward,
    required this.onOpenSettings,
    required this.onOpenLocker,
    required this.onRematch,
    required this.onLobby,
  });

  final MatchResult result;
  final String matchId;
  final Faction playerFaction;
  final int relays;
  final double elapsed;
  final int baseReward;
  final int warTokenBalance;
  final bool bannerVisible;
  final Future<RewardedClaim> Function() onDoubleReward;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLocker;
  final VoidCallback onRematch;
  final VoidCallback onLobby;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool doubled = false;
  bool requestingReward = false;
  String? rewardMessage;

  String get duration {
    final total = widget.elapsed.floor();
    return '${(total ~/ 60).toString().padLeft(2, '0')}:'
        '${(total % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _doubleReward() async {
    if (requestingReward || doubled) return;
    setState(() {
      requestingReward = true;
      rewardMessage = null;
    });
    final claim = await widget.onDoubleReward();
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      requestingReward = false;
      doubled = claim.earned || claim.alreadyClaimed;
      rewardMessage = claim.earned
          ? l10n.warTokensSecured(claim.credited)
          : _rewardFailureCopy(l10n, claim.adResult.status);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final winner = widget.result.winner;
    final won = winner == widget.playerFaction;
    return Scaffold(
      body: TacticalBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      won ? l10n.signalSurvived : l10n.signalLost,
                      textAlign: TextAlign.center,
                      style: TokenfrontType.display.copyWith(
                        color:
                            winner?.visual.color ?? TokenfrontColors.relayIvory,
                        fontSize: 38,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      winner == null
                          ? l10n.drawSummary(
                              duration,
                              widget.matchId.toUpperCase(),
                            )
                          : l10n.winnerSummary(
                              winner.visual.name,
                              duration,
                              widget.matchId.toUpperCase(),
                            ),
                      textAlign: TextAlign.center,
                      style: TokenfrontType.instrument.copyWith(
                        color: TokenfrontColors.quietText,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TacticalPanel(
                      color: TokenfrontColors.deepField.withValues(alpha: .84),
                      child: Column(
                        children: [
                          const _StandingHeader(),
                          const Divider(color: Color(0x33F2E9D1)),
                          for (
                            var index = 0;
                            index < widget.result.standings.length;
                            index++
                          )
                            _StandingRow(
                              rank: index + 1,
                              standing: widget.result.standings[index],
                              player:
                                  widget.result.standings[index].faction ==
                                  widget.playerFaction,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TacticalPanel(
                      child: Row(
                        children: [
                          Expanded(
                            child: _Metric(
                              label: l10n.relays,
                              value: '${widget.relays}',
                            ),
                          ),
                          Expanded(
                            child: _Metric(
                              label: l10n.match,
                              value: l10n.complete,
                            ),
                          ),
                          Expanded(
                            child: _Metric(
                              label: l10n.warToken,
                              value:
                                  '+${widget.baseReward * (doubled ? 2 : 1)}  /  ${widget.warTokenBalance}',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (rewardMessage case final message?) ...[
                      TacticalPanel(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        borderColor: doubled
                            ? TokenfrontColors.volt
                            : TokenfrontColors.quietText,
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TokenfrontType.body.copyWith(fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        TacticalButton(
                          label: requestingReward
                              ? l10n.requestingAd
                              : doubled
                              ? l10n.rewardDoubled
                              : l10n.doubleReward,
                          onPressed: doubled || requestingReward
                              ? null
                              : _doubleReward,
                          color: TokenfrontColors.volt,
                        ),
                        TacticalButton(
                          label: l10n.rematch,
                          onPressed: widget.onRematch,
                          color: widget.playerFaction.visual.color,
                        ),
                        OutlinedButton(
                          onPressed: widget.onLobby,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(124, 50),
                            foregroundColor: TokenfrontColors.relayIvory,
                            side: const BorderSide(color: Color(0x66F2E9D1)),
                            shape: const BeveledRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            textStyle: TokenfrontType.instrument,
                          ),
                          child: Text(l10n.lobby),
                        ),
                        OutlinedButton(
                          onPressed: widget.onOpenLocker,
                          style: _secondaryButtonStyle(),
                          child: Text(l10n.locker),
                        ),
                        OutlinedButton(
                          onPressed: widget.onOpenSettings,
                          style: _secondaryButtonStyle(),
                          child: Text(l10n.settings),
                        ),
                      ],
                    ),
                    if (widget.bannerVisible) ...[
                      const SizedBox(height: 18),
                      const _ResultSponsorRail(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

ButtonStyle _secondaryButtonStyle() => OutlinedButton.styleFrom(
  minimumSize: const Size(112, 50),
  foregroundColor: TokenfrontColors.relayIvory,
  side: const BorderSide(color: Color(0x55F2E9D1)),
  shape: const BeveledRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
  ),
  textStyle: TokenfrontType.instrument,
);

String _rewardFailureCopy(AppLocalizations l10n, AdStatus status) =>
    switch (status) {
      AdStatus.skippedConsent => l10n.adRequestsOffMessage,
      AdStatus.skippedOffline => l10n.noConnectionRewardMessage,
      AdStatus.unavailable => l10n.noRewardedAdMessage,
      AdStatus.failed => l10n.adFailedRewardMessage,
      AdStatus.skippedPolicy ||
      AdStatus.skippedFrequency => l10n.rewardOfferUnavailableMessage,
      AdStatus.shown ||
      AdStatus.rewardEarned => l10n.rewardRequestCompleteMessage,
    };

class _ResultSponsorRail extends StatelessWidget {
  const _ResultSponsorRail();

  @override
  Widget build(BuildContext context) => TacticalPanel(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    color: TokenfrontColors.deepField.withValues(alpha: .72),
    child: Text(
      context.l10n.resultSponsorPlacement,
      textAlign: TextAlign.center,
      style: TokenfrontType.instrument.copyWith(
        color: TokenfrontColors.quietText,
        fontSize: 9,
      ),
    ),
  );
}

class _StandingHeader extends StatelessWidget {
  const _StandingHeader();
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        const SizedBox(width: 34, child: Text('#')),
        Expanded(flex: 3, child: Text(l10n.faction)),
        Expanded(child: Text(l10n.alive, textAlign: TextAlign.right)),
        Expanded(child: Text(l10n.levelSum, textAlign: TextAlign.right)),
        Expanded(child: Text(l10n.kills, textAlign: TextAlign.right)),
      ],
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    required this.rank,
    required this.standing,
    required this.player,
  });
  final int rank;
  final FactionStanding standing;
  final bool player;

  @override
  Widget build(BuildContext context) {
    final factionLabel =
        '${standing.faction.visual.mark}  ${standing.faction.visual.name}';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: TokenfrontColors.relayIvory.withValues(alpha: .08),
          ),
        ),
      ),
      child: DefaultTextStyle(
        style: TokenfrontType.instrument.copyWith(
          color: player
              ? TokenfrontColors.relayIvory
              : TokenfrontColors.quietText,
          fontSize: 11,
        ),
        child: Row(
          children: [
            SizedBox(width: 34, child: Text('$rank')),
            Expanded(
              flex: 3,
              child: Text(
                player
                    ? context.l10n.standingFactionYou(factionLabel)
                    : factionLabel,
                style: TextStyle(color: standing.faction.visual.color),
              ),
            ),
            Expanded(
              child: Text('${standing.survivors}', textAlign: TextAlign.right),
            ),
            Expanded(
              child: Text('${standing.levelSum}', textAlign: TextAlign.right),
            ),
            Expanded(
              child: Text('${standing.kills}', textAlign: TextAlign.right),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: TokenfrontType.instrument.copyWith(
          color: TokenfrontColors.relayIvory,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: TokenfrontType.instrument.copyWith(
          color: TokenfrontColors.quietText,
          fontSize: 9,
        ),
      ),
    ],
  );
}
