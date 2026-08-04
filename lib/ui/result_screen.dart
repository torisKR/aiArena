import 'package:flutter/material.dart';

import '../app/tokenfront_runtime.dart';
import '../design/tokens.dart';
import '../game/faction_visuals.dart';
import '../game/simulation.dart';
import '../l10n/l10n.dart';
import '../services/ads/ad_service.dart';
import '../story/campaign_controller.dart';
import '../story/story_localizations.dart';
import '../story/story_models.dart';
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
    this.rewardedAdsAvailable = true,
    required this.onDoubleReward,
    required this.onOpenSettings,
    required this.onOpenLocker,
    required this.onRematch,
    required this.onLobby,
    this.onContinue,
    this.operation,
    this.campaignTransition,
    this.storyProgress,
    this.rewardLedger,
    this.replay = false,
    this.onChooseEnding,
    this.onCommandDeck,
  });

  final MatchResult result;
  final String matchId;
  final Faction playerFaction;
  final int relays;
  final double elapsed;
  final int baseReward;
  final int warTokenBalance;
  final bool bannerVisible;
  final bool rewardedAdsAvailable;
  final Future<RewardedClaim> Function() onDoubleReward;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLocker;
  final VoidCallback onRematch;
  final VoidCallback onLobby;
  final VoidCallback? onContinue;
  final StoryOperation? operation;
  final CampaignTransition? campaignTransition;
  final StoryProgress? storyProgress;
  final ProfileRewardLedger? rewardLedger;
  final bool replay;
  final ValueChanged<EndingChoice>? onChooseEnding;
  final VoidCallback? onCommandDeck;

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
    final copy = StoryLocalizations(l10n);
    final operation = widget.operation;
    final chronicle = operation != null;
    final directiveSucceeded =
        widget.campaignTransition?.directiveSucceeded ??
        (widget.storyProgress?.medals.contains(operation?.id) ?? false);
    final bonusCredit = widget.campaignTransition?.directiveBonusCredit ?? 0;
    final bonusClaimed =
        operation != null &&
        (bonusCredit > 0 ||
            (widget.rewardLedger?.claimedDirectiveBonusIds.contains(
                  operation.bonusClaimId,
                ) ??
                false));
    final ending = widget.storyProgress?.ending;
    final endingUnlocked =
        chronicle &&
        operation.id == StoryOperationId.lastInstruction &&
        widget.storyProgress?.concludedOperations.contains(
              StoryOperationId.lastInstruction,
            ) ==
            true;
    final showEndingChoices =
        endingUnlocked && ending == null && widget.onChooseEnding != null;
    return Scaffold(
      body: TacticalBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  key: const Key('result-scroll'),
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
                                  winner?.visual.color ??
                                  TokenfrontColors.relayIvory,
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
                          if (chronicle) ...[
                            _ChronicleDebriefPanel(
                              operation: operation,
                              playerFaction: widget.playerFaction,
                              directiveSucceeded: directiveSucceeded,
                              bonusClaimed: bonusClaimed,
                              bonusAmount: operation.oneTimeBonus,
                              ending: ending,
                            ),
                            const SizedBox(height: 14),
                          ],
                          TacticalPanel(
                            color: TokenfrontColors.deepField.withValues(
                              alpha: .84,
                            ),
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
                                        widget
                                            .result
                                            .standings[index]
                                            .faction ==
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
                                style: TokenfrontType.body.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              if (widget.onContinue != null && !chronicle)
                                TacticalButton(
                                  label: chronicle
                                      ? copy.continueCampaign
                                      : 'CONTINUE',
                                  onPressed: widget.onContinue,
                                  color: TokenfrontColors.relayIvory,
                                ),
                              if (widget.rewardedAdsAvailable)
                                TacticalButton(
                                  key: const Key('double-reward-button'),
                                  label: requestingReward
                                      ? l10n.requestingAd
                                      : doubled
                                      ? l10n.rewardDoubled
                                      : l10n.doubleReward,
                                  onPressed: doubled || requestingReward
                                      ? null
                                      : _doubleReward,
                                  color: TokenfrontColors.volt,
                                )
                              else
                                Text(
                                  l10n.releaseServicesUnavailable,
                                  key: const Key(
                                    'release-services-unavailable',
                                  ),
                                  style: TokenfrontType.instrument.copyWith(
                                    color: TokenfrontColors.quietText,
                                    fontSize: 10,
                                  ),
                                ),
                              if (!chronicle)
                                TacticalButton(
                                  label: l10n.rematch,
                                  onPressed: widget.onRematch,
                                  color: widget.playerFaction.visual.color,
                                ),
                              OutlinedButton(
                                onPressed:
                                    widget.onCommandDeck ?? widget.onLobby,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(124, 50),
                                  foregroundColor: TokenfrontColors.relayIvory,
                                  side: const BorderSide(
                                    color: Color(0x66F2E9D1),
                                  ),
                                  shape: const BeveledRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  textStyle: TokenfrontType.instrument,
                                ),
                                child: Text(
                                  chronicle ? copy.commandDeck : l10n.lobby,
                                ),
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
                          const SizedBox(
                            key: Key('result-scroll-end'),
                            height: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (chronicle && (widget.onContinue != null || showEndingChoices))
                _ChronicleActionLayer(
                  showEndingChoices: showEndingChoices,
                  onContinue: widget.onContinue,
                  onRetry: widget.onRematch,
                  retryColor: widget.playerFaction.visual.color,
                  onChooseEnding: widget.onChooseEnding,
                ),
            ],
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

class _ChronicleDebriefPanel extends StatelessWidget {
  const _ChronicleDebriefPanel({
    required this.operation,
    required this.playerFaction,
    required this.directiveSucceeded,
    required this.bonusClaimed,
    required this.bonusAmount,
    required this.ending,
  });

  final StoryOperation operation;
  final Faction playerFaction;
  final bool directiveSucceeded;
  final bool bonusClaimed;
  final int bonusAmount;
  final EndingChoice? ending;

  @override
  Widget build(BuildContext context) {
    final copy = StoryLocalizations(context.l10n);
    final directive = copy.directiveLabel(
      operation.directive.kind,
      target: operation.directive.target,
    );
    final medal = directiveSucceeded
        ? context.l10n.medalEarned
        : copy.directiveMissed;
    final bonus = bonusClaimed
        ? copy.bonusClaimed
        : copy.directiveBonus(bonusAmount);
    return TacticalPanel(
      key: const Key('chronicle-debrief'),
      borderColor: TokenfrontColors.relayIvory.withValues(alpha: .62),
      color: TokenfrontColors.deepField.withValues(alpha: .9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            copy.transmissionRecovered,
            style: TokenfrontType.instrument.copyWith(
              color: TokenfrontColors.volt,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            copy.operationTitle(operation.id),
            style: TokenfrontType.display.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 10),
          Text(
            copy.transmission(operation.id),
            style: TokenfrontType.body.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            copy.reveal(operation.id),
            style: TokenfrontType.body.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            copy.coreResponse(copy.coreName(playerFaction)),
            style: TokenfrontType.body.copyWith(
              color: TokenfrontColors.quietText,
              fontSize: 11,
            ),
          ),
          const Divider(color: Color(0x33F2E9D1), height: 22),
          Text(
            '$directive  //  $medal  //  $bonus',
            style: TokenfrontType.instrument.copyWith(
              color: directiveSucceeded
                  ? TokenfrontColors.volt
                  : TokenfrontColors.quietText,
              fontSize: 10,
            ),
          ),
          if (ending case final choice?) ...[
            const Divider(color: Color(0x33F2E9D1), height: 22),
            Text(
              '${copy.endingHeading}  //  ${copy.endingLabel(choice)}',
              style: TokenfrontType.instrument.copyWith(
                color: TokenfrontColors.volt,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 7),
            Text(copy.endingEpilogue(choice), style: TokenfrontType.body),
          ],
        ],
      ),
    );
  }
}

class _ChronicleActionLayer extends StatelessWidget {
  const _ChronicleActionLayer({
    required this.showEndingChoices,
    required this.onContinue,
    required this.onRetry,
    required this.retryColor,
    required this.onChooseEnding,
  });

  final bool showEndingChoices;
  final VoidCallback? onContinue;
  final VoidCallback onRetry;
  final Color retryColor;
  final ValueChanged<EndingChoice>? onChooseEnding;

  @override
  Widget build(BuildContext context) {
    final copy = StoryLocalizations(context.l10n);
    return DecoratedBox(
      key: const Key('chronicle-action-layer'),
      decoration: BoxDecoration(
        color: TokenfrontColors.deepField.withValues(alpha: .96),
        border: const Border(top: BorderSide(color: Color(0x55F2E9D1))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
        child: showEndingChoices
            ? TacticalPanel(
                borderColor: TokenfrontColors.volt,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(copy.endingHeading, style: TokenfrontType.instrument),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        TacticalButton endingButton(
                          EndingChoice choice,
                          Color color, {
                          bool expanded = false,
                        }) => TacticalButton(
                          label: copy.endingLabel(choice),
                          onPressed: () => onChooseEnding!(choice),
                          color: color,
                          expanded: expanded,
                        );
                        if (constraints.maxWidth < 280) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              endingButton(
                                EndingChoice.claimRelay,
                                TokenfrontColors.relayIvory,
                                expanded: true,
                              ),
                              const SizedBox(height: 10),
                              endingButton(
                                EndingChoice.openRelay,
                                TokenfrontColors.volt,
                                expanded: true,
                              ),
                            ],
                          );
                        }
                        return Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            endingButton(
                              EndingChoice.claimRelay,
                              TokenfrontColors.relayIvory,
                            ),
                            endingButton(
                              EndingChoice.openRelay,
                              TokenfrontColors.volt,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              )
            : Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  TacticalButton(
                    label: copy.continueCampaign,
                    onPressed: onContinue,
                    color: TokenfrontColors.relayIvory,
                  ),
                  TacticalButton(
                    label: copy.retryDirective,
                    onPressed: onRetry,
                    color: retryColor,
                  ),
                ],
              ),
      ),
    );
  }
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
