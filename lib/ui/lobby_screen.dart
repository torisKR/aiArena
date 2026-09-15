import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../design/tokens.dart';
import '../game/faction_visuals.dart';
import '../game/simulation.dart';
import '../l10n/l10n.dart';
import '../story/story_localizations.dart';
import '../story/story_catalog.dart';
import '../story/story_models.dart';
import 'orbital_progress_ring.dart';
import 'primitives.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({
    super.key,
    required this.selectedMode,
    required this.storyProgress,
    required this.rewardLedger,
    required this.selectedChronicleFaction,
    required this.selectedSkirmishFaction,
    required this.onSelectChronicleCore,
    required this.onSelectSkirmishFaction,
    required this.onDeployChronicle,
    required this.onDeploySkirmish,
    required this.onOpenArchive,
    required this.warTokenBalance,
    required this.onOpenSettings,
    required this.onOpenLocker,
    required this.bannerVisible,
    this.bannerAd,
    this.onChooseEnding,
    this.chronicleAvailable = true,
    this.lowSpec = false,
    this.reduceMotion = false,
  });

  final GameMode selectedMode;
  final StoryProgress storyProgress;
  final ProfileRewardLedger rewardLedger;
  final Faction selectedChronicleFaction;
  final Faction selectedSkirmishFaction;
  final ValueChanged<Faction> onSelectChronicleCore;
  final ValueChanged<Faction> onSelectSkirmishFaction;
  final VoidCallback onDeployChronicle;
  final VoidCallback onDeploySkirmish;
  final VoidCallback onOpenArchive;
  final int warTokenBalance;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLocker;
  final bool bannerVisible;
  final BannerAd? bannerAd;
  final ValueChanged<EndingChoice>? onChooseEnding;
  final bool chronicleAvailable;
  final bool lowSpec;
  final bool reduceMotion;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late GameMode mode = widget.selectedMode;

  @override
  void didUpdateWidget(covariant LobbyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMode != widget.selectedMode) {
      mode = widget.selectedMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final compact = viewport.width < TokenfrontBreakpoints.compact;
    final dense = viewport.height < TokenfrontBreakpoints.stackedActions;
    final copy = StoryLocalizations(context.l10n);
    final lockedCore = widget.storyProgress.campaignFaction;
    final selectedCore = lockedCore ?? widget.selectedChronicleFaction;
    final operation = widget.storyProgress.currentOperation;
    final pendingEnding =
        operation == null &&
        widget.storyProgress.ending == null &&
        widget.onChooseEnding != null;
    return Scaffold(
      body: TacticalBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: compact
                    ? TokenfrontSpacing.lg
                    : TokenfrontSpacing.xxl,
                vertical: compact ? TokenfrontSpacing.lg : TokenfrontSpacing.xl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1060),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(compact: compact, mode: mode),
                      const SizedBox(height: TokenfrontSpacing.md),
                      _UtilityRail(
                        compact: compact,
                        warTokenBalance: widget.warTokenBalance,
                        onOpenSettings: widget.onOpenSettings,
                        onOpenLocker: widget.onOpenLocker,
                      ),
                      SizedBox(
                        height: compact
                            ? TokenfrontSpacing.lg + TokenfrontSpacing.xs
                            : TokenfrontSpacing.xxl - TokenfrontSpacing.xs,
                      ),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 10,
                        children: [
                          Text(
                            copy.commandDeck,
                            style: TokenfrontType.instrument.copyWith(
                              fontSize: compact ? 16 : 19,
                            ),
                          ),
                          _ModeRail(
                            selectedMode: mode,
                            chronicleAvailable: widget.chronicleAvailable,
                            onChronicle: () =>
                                setState(() => mode = GameMode.chronicle),
                            onSkirmish: () =>
                                setState(() => mode = GameMode.skirmish),
                          ),
                        ],
                      ),
                      const SizedBox(height: TokenfrontSpacing.lg),
                      if (mode == GameMode.chronicle) ...[
                        _StoryRole(copy: copy, compact: compact),
                        const SizedBox(height: TokenfrontSpacing.lg),
                        if (lockedCore == null && operation != null) ...[
                          _Prologue(prologue: copy.prologue),
                          ExcludeSemantics(
                            child: Text(
                              'OP-${(operation.index + 1).toString().padLeft(2, '0')}',
                              style: TokenfrontType.instrument.copyWith(
                                color: TokenfrontColors.quietText,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                        if (operation != null)
                          _Briefing(
                            operation: StoryCatalog.byId(operation),
                            copy: copy,
                          ),
                        if (pendingEnding)
                          _EndingChoicePanel(
                            onChooseEnding: widget.onChooseEnding!,
                          ),
                        OrbitalProgressRing(
                          progress: widget.storyProgress,
                          lowSpec: widget.lowSpec,
                          reduceMotion: widget.reduceMotion,
                        ),
                        const SizedBox(height: 7),
                        _CoreGrid(
                          selected: selectedCore,
                          locked: lockedCore != null,
                          compact: compact || dense,
                          onSelected: (faction) {
                            if (lockedCore != null) return;
                            widget.onSelectChronicleCore(faction);
                          },
                        ),
                        const SizedBox(height: TokenfrontSpacing.lg),
                        TacticalPanel(
                          child: Text(
                            context.l10n.recoveryInstruction,
                            style: TokenfrontType.body,
                          ),
                        ),
                        const SizedBox(height: TokenfrontSpacing.lg),
                        if (!pendingEnding)
                          TacticalButton(
                            key: const Key('chronicle-deploy'),
                            expanded: compact,
                            label: operation == null
                                ? context.l10n.chronicleUnavailable
                                : context.l10n.recoveryTitle,
                            color: selectedCore.visual.color,
                            onPressed: operation == null
                                ? null
                                : () {
                                    widget.onDeployChronicle();
                                  },
                          ),
                      ] else ...[
                        _FactionSelector(
                          selected: widget.selectedSkirmishFaction,
                          compact: compact || dense,
                          onSelected: widget.onSelectSkirmishFaction,
                        ),
                        const SizedBox(height: 18),
                        _ProtocolPanel(faction: widget.selectedSkirmishFaction),
                        const SizedBox(height: 16),
                        TacticalButton(
                          key: const Key('skirmish-deploy'),
                          expanded: compact,
                          label: context.l10n.deploySignal,
                          color: widget.selectedSkirmishFaction.visual.color,
                          onPressed: widget.onDeploySkirmish,
                        ),
                        const SizedBox(height: 10),
                        if (widget.storyProgress.ending != null)
                          Text(
                            context.l10n.archiveSimulation,
                            textAlign: TextAlign.center,
                            style: TokenfrontType.instrument.copyWith(
                              color: TokenfrontColors.quietText,
                              fontSize: 9,
                            ),
                          ),
                      ],
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            key: const Key('archive-action'),
                            onPressed: widget.onOpenArchive,
                            icon: const Icon(Icons.archive_outlined, size: 17),
                            label: Text(copy.archive),
                          ),
                          if (mode == GameMode.skirmish) const _RulesStrip(),
                        ],
                      ),
                      if (widget.bannerVisible) ...[
                        const SizedBox(height: 18),
                        _SponsorRail(ad: widget.bannerAd),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Prologue extends StatelessWidget {
  const _Prologue({required this.prologue});
  final String prologue;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: TokenfrontSpacing.md),
    child: Text(
      prologue,
      style: TokenfrontType.body.copyWith(
        fontSize: 15,
        color: TokenfrontColors.relayIvory,
      ),
    ),
  );
}

class _StoryRole extends StatelessWidget {
  const _StoryRole({required this.copy, required this.compact});

  final StoryLocalizations copy;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        copy.storyRoleTitle,
        key: const Key('story-role-title'),
        style: TokenfrontType.display.copyWith(fontSize: compact ? 24 : 32),
      ),
      const SizedBox(height: TokenfrontSpacing.sm),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Text(
          context.l10n.recoveryAutomatic,
          key: const Key('story-role-body'),
          style: TokenfrontType.body.copyWith(
            fontSize: compact ? 12 : 14,
            color: TokenfrontColors.archiveAsh,
          ),
        ),
      ),
    ],
  );
}

class _Briefing extends StatelessWidget {
  const _Briefing({required this.operation, required this.copy});
  final StoryOperation operation;
  final StoryLocalizations copy;
  @override
  Widget build(BuildContext context) => TacticalPanel(
    padding: const EdgeInsets.symmetric(
      horizontal: TokenfrontSpacing.md,
      vertical: TokenfrontSpacing.sm + TokenfrontSpacing.xs,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy.operationTitle(operation.id),
          key: const Key('current-operation-title'),
          style: TokenfrontType.instrument.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 7),
        Text(
          copy.incident(operation.id),
          key: const Key('current-operation-incident'),
          style: TokenfrontType.body.copyWith(
            fontSize: 12,
            color: TokenfrontColors.relayIvory,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          context.l10n.recoveryTitle,
          style: TokenfrontType.body.copyWith(
            fontSize: 10,
            color: TokenfrontColors.relayIvory,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          copy.directiveBonus(operation.oneTimeBonus),
          style: TokenfrontType.instrument.copyWith(
            fontSize: 9,
            color: TokenfrontColors.volt,
          ),
        ),
      ],
    ),
  );
}

class _EndingChoicePanel extends StatelessWidget {
  const _EndingChoicePanel({required this.onChooseEnding});

  final ValueChanged<EndingChoice> onChooseEnding;

  @override
  Widget build(BuildContext context) {
    final copy = StoryLocalizations(context.l10n);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TacticalPanel(
        borderColor: TokenfrontColors.volt,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(copy.endingHeading, style: TokenfrontType.instrument),
            const SizedBox(height: 8),
            Text(
              context.l10n.continueCampaign,
              style: TokenfrontType.body.copyWith(
                color: TokenfrontColors.quietText,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                TacticalButton(
                  key: const Key('claim-ending'),
                  label: copy.endingLabel(EndingChoice.claimRelay),
                  onPressed: () => onChooseEnding(EndingChoice.claimRelay),
                  color: TokenfrontColors.relayIvory,
                ),
                TacticalButton(
                  key: const Key('open-ending'),
                  label: copy.endingLabel(EndingChoice.openRelay),
                  onPressed: () => onChooseEnding(EndingChoice.openRelay),
                  color: TokenfrontColors.volt,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeRail extends StatelessWidget {
  const _ModeRail({
    required this.selectedMode,
    required this.chronicleAvailable,
    required this.onChronicle,
    required this.onSkirmish,
  });
  final GameMode selectedMode;
  final bool chronicleAvailable;
  final VoidCallback onChronicle;
  final VoidCallback onSkirmish;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      TacticalButton(
        key: chronicleAvailable
            ? const Key('chronicle-mode')
            : const Key('chronicle-deploy-disabled'),
        label: chronicleAvailable
            ? context.l10n.chronicle
            : context.l10n.chronicleUnavailable,
        color: selectedMode == GameMode.chronicle
            ? TokenfrontColors.relayIvory
            : TokenfrontColors.quietText,
        onPressed: chronicleAvailable ? onChronicle : null,
      ),
      TacticalButton(
        key: const Key('skirmish-mode'),
        label: context.l10n.skirmish,
        color: selectedMode == GameMode.skirmish
            ? TokenfrontColors.cobalt
            : TokenfrontColors.quietText,
        onPressed: onSkirmish,
      ),
    ],
  );
}

class _CoreGrid extends StatelessWidget {
  const _CoreGrid({
    required this.selected,
    required this.locked,
    required this.compact,
    required this.onSelected,
  });
  final Faction? selected;
  final bool locked;
  final bool compact;
  final ValueChanged<Faction> onSelected;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: compact ? 7 : 12,
    runSpacing: compact ? 7 : 12,
    children: [
      for (final faction in Faction.values)
        _CoreCard(
          faction: faction,
          selected: faction == selected,
          locked: locked,
          compact: compact,
          onTap: () => onSelected(faction),
        ),
    ],
  );
}

class _CoreCard extends StatelessWidget {
  const _CoreCard({
    required this.faction,
    required this.selected,
    required this.locked,
    required this.compact,
    required this.onTap,
  });
  final Faction faction;
  final bool selected;
  final bool locked;
  final bool compact;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final visual = faction.visual;
    final card = Material(
      color: locked
          ? TokenfrontColors.deepField.withValues(alpha: .5)
          : selected
          ? visual.color.withValues(alpha: .22)
          : TokenfrontColors.deepField.withValues(alpha: .82),
      shape: BeveledRectangleBorder(
        side: BorderSide(
          color: selected
              ? visual.color
              : TokenfrontColors.relayIvory.withValues(alpha: .25),
        ),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: InkWell(
        onTap: locked ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FactionGlyph(
                kind: _glyphFor(faction),
                color: locked ? TokenfrontColors.quietText : visual.color,
                size: compact ? 24 : 45,
                selected: selected,
              ),
              SizedBox(height: compact ? 3 : 7),
              Text(
                visual.name,
                style: TokenfrontType.instrument.copyWith(
                  fontSize: compact ? 9 : 12,
                  color: locked ? TokenfrontColors.quietText : visual.color,
                ),
              ),
              Text(
                      context.l10n.unitsCount(100),
                style: TokenfrontType.body.copyWith(
                  fontSize: compact ? 8 : 9,
                  color: TokenfrontColors.quietText,
                ),
              ),
              if (!locked && !compact)
                Text(
                  StoryLocalizations(context.l10n).coreIdentity(faction),
                  textAlign: TextAlign.center,
                  style: TokenfrontType.body.copyWith(
                    fontSize: 9,
                    color: TokenfrontColors.quietText,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      label: locked
          ? context.l10n.chronicleCoreLocked(visual.name)
          : context.l10n.chooseFaction(visual.name),
      button: !locked,
      enabled: !locked,
      selected: selected,
      onTap: locked ? null : onTap,
      child: ExcludeSemantics(
        child: SizedBox(
          width: compact ? 142 : 214,
          height: compact ? 90 : 148,
          child: card,
        ),
      ),
    );
  }
}

class _FactionSelector extends StatelessWidget {
  const _FactionSelector({
    required this.selected,
    required this.compact,
    required this.onSelected,
  });
  final Faction selected;
  final bool compact;
  final ValueChanged<Faction> onSelected;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: compact ? 7 : 12,
    runSpacing: compact ? 7 : 12,
    children: [
      for (final faction in Faction.values)
        _CoreCard(
          faction: faction,
          selected: faction == selected,
          locked: false,
          compact: compact,
          onTap: () => onSelected(faction),
        ),
    ],
  );
}

class _ProtocolPanel extends StatelessWidget {
  const _ProtocolPanel({required this.faction});
  final Faction faction;
  @override
  Widget build(BuildContext context) {
    final copy = StoryLocalizations(context.l10n);
    return TacticalPanel(
      child: Row(
        children: [
          FactionGlyph(
            kind: _glyphFor(faction),
            color: faction.visual.color,
            size: 42,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.coreProtocol(faction),
                  style: TokenfrontType.instrument.copyWith(
                    color: faction.visual.color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  copy.coreIdentity(faction),
                  style: TokenfrontType.body.copyWith(
                    color: TokenfrontColors.quietText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '“${copy.coreVoice(faction)}”',
                  key: const Key('core-voice'),
                  style: TokenfrontType.body.copyWith(
                    color: TokenfrontColors.threadCyan,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.l10n.factionBrief,
                  style: TokenfrontType.body.copyWith(
                    color: TokenfrontColors.quietText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.compact, required this.mode});
  final bool compact;
  final GameMode mode;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TOKENFRONT',
              style: TokenfrontType.display.copyWith(
                fontSize: compact ? 34 : 56,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mode == GameMode.chronicle
                  ? context.l10n.recoveryAutomatic
                  : context.l10n.lobbyTagline,
              style: TokenfrontType.instrument.copyWith(
                fontSize: compact ? 9 : 12,
                color: TokenfrontColors.quietText,
              ),
            ),
          ],
        ),
      ),
      TacticalPanel(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          '${context.l10n.offline}\n${mode == GameMode.chronicle ? '01:30' : '15:00'}',
          textAlign: TextAlign.right,
          style: TokenfrontType.instrument.copyWith(fontSize: 10, height: 1.3),
        ),
      ),
    ],
  );
}

class _UtilityRail extends StatelessWidget {
  const _UtilityRail({
    required this.compact,
    required this.warTokenBalance,
    required this.onOpenSettings,
    required this.onOpenLocker,
  });
  final bool compact;
  final int warTokenBalance;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLocker;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 8,
    children: [
      _UtilityButton(
        label: context.l10n.lockerBalance(warTokenBalance),
        icon: Icons.inventory_2_outlined,
        onPressed: onOpenLocker,
      ),
      _UtilityButton(
        label: compact ? context.l10n.tune : context.l10n.signalSettings,
        icon: Icons.tune,
        onPressed: onOpenSettings,
      ),
    ],
  );
}

class _UtilityButton extends StatelessWidget {
  const _UtilityButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 15),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 38),
      foregroundColor: TokenfrontColors.relayIvory,
      side: const BorderSide(color: Color(0x55F2E9D1)),
      textStyle: TokenfrontType.instrument.copyWith(fontSize: 9),
    ),
  );
}

class _RulesStrip extends StatelessWidget {
  const _RulesStrip();
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 16,
    runSpacing: 7,
    children: [
      _Rule(label: '4,000', detail: context.l10n.units),
      _Rule(label: context.l10n.highLevel, detail: context.l10n.wins),
      _Rule(label: context.l10n.equalLevel, detail: '50 / 50'),
      _Rule(label: context.l10n.death, detail: context.l10n.relays),
      _Rule(label: context.l10n.move, detail: context.l10n.stickWasd),
      _Rule(label: context.l10n.dash, detail: context.l10n.buttonSpace),
    ],
  );
}

class _Rule extends StatelessWidget {
  const _Rule({required this.label, required this.detail});
  final String label;
  final String detail;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: TokenfrontType.instrument.copyWith(fontSize: 10)),
      const SizedBox(width: 5),
      Text(
        detail,
        style: TokenfrontType.instrument.copyWith(
          color: TokenfrontColors.quietText,
          fontSize: 8,
        ),
      ),
    ],
  );
}

class _SponsorRail extends StatelessWidget {
  const _SponsorRail({this.ad});
  final BannerAd? ad;
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.sponsorBannerArea,
    child: TacticalPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: ad == null
          ? Text(
              '${context.l10n.sponsorSignal}  /  ${context.l10n.lobbyPlacement}',
              textAlign: TextAlign.center,
              style: TokenfrontType.instrument.copyWith(fontSize: 9),
            )
          : SizedBox(
              width: ad!.size.width.toDouble(),
              height: ad!.size.height.toDouble(),
              child: AdWidget(ad: ad!),
            ),
    ),
  );
}

FactionGlyphKind _glyphFor(Faction faction) => switch (faction) {
  Faction.amethyst => FactionGlyphKind.diamond,
  Faction.cobalt => FactionGlyphKind.brackets,
  Faction.volt => FactionGlyphKind.bolt,
  Faction.prism => FactionGlyphKind.prism,
};
