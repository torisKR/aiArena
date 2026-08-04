import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../game/faction_visuals.dart';
import '../game/simulation.dart';
import '../l10n/l10n.dart';
import '../story/story_models.dart';
import 'primitives.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({
    super.key,
    required this.onDeploy,
    required this.warTokenBalance,
    required this.onOpenSettings,
    required this.onOpenLocker,
    required this.bannerVisible,
    this.onOpenChronicle,
    this.onChronicleDeploy,
    this.chronicleAvailable = true,
    this.briefing = false,
    this.currentOperation,
  });

  final void Function(Faction faction) onDeploy;
  final int warTokenBalance;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLocker;
  final bool bannerVisible;
  final VoidCallback? onOpenChronicle;
  final void Function(Faction faction)? onChronicleDeploy;
  final bool chronicleAvailable;
  final bool briefing;
  final StoryOperation? currentOperation;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  Faction selected = Faction.amethyst;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TacticalBackdrop(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 18 : 42,
                vertical: compact ? 18 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1060),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(compact: compact),
                      const SizedBox(height: 12),
                      _UtilityRail(
                        compact: compact,
                        warTokenBalance: widget.warTokenBalance,
                        onOpenSettings: widget.onOpenSettings,
                        onOpenLocker: widget.onOpenLocker,
                      ),
                      SizedBox(height: compact ? 38 : 72),
                      if (widget.briefing && widget.currentOperation != null)
                        _BriefingHeader(operation: widget.currentOperation!),
                      if (!widget.briefing) ...[
                        _ModeRail(
                          chronicleAvailable: widget.chronicleAvailable,
                          onChronicle: widget.onOpenChronicle,
                          onSkirmish: () => widget.onDeploy(selected),
                        ),
                        const SizedBox(height: 18),
                      ],
                      _FactionSelector(
                        selected: selected,
                        compact: compact,
                        onSelected: (faction) =>
                            setState(() => selected = faction),
                      ),
                      const SizedBox(height: 26),
                      Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: TacticalPanel(
                            color: TokenfrontColors.deepField.withValues(
                              alpha: .82,
                            ),
                            child: Row(
                              children: [
                                FactionGlyph(
                                  kind: _glyphFor(selected),
                                  color: selected.visual.color,
                                  size: 52,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n.factionSignal(
                                          selected.visual.name,
                                        ),
                                        style: TokenfrontType.instrument
                                            .copyWith(
                                              color: selected.visual.color,
                                              fontSize: 15,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        context.l10n.factionBrief,
                                        style: TextStyle(
                                          color: TokenfrontColors.quietText,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.center,
                        child: TacticalButton(
                          key: widget.briefing
                              ? const Key('chronicle-deploy')
                              : widget.chronicleAvailable
                              ? const Key('skirmish-deploy')
                              : const Key('skirmish-action'),
                          label: widget.briefing
                              ? 'DEPLOY OP-${(widget.currentOperation!.id.index + 1).toString().padLeft(2, '0')}'
                              : context.l10n.deploySignal,
                          color: selected.visual.color,
                          icon: FactionGlyph(
                            kind: _glyphFor(selected),
                            color: TokenfrontColors.deepField,
                            size: 20,
                          ),
                          onPressed: widget.briefing
                              ? () => widget.onChronicleDeploy?.call(selected)
                              : () => widget.onDeploy(selected),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _RulesStrip(),
                      if (widget.bannerVisible) ...[
                        const SizedBox(height: 18),
                        const _SponsorRail(),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
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
    runSpacing: 8,
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
      shape: const BeveledRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(7)),
      ),
      textStyle: TokenfrontType.instrument.copyWith(fontSize: 9),
    ),
  );
}

class _ModeRail extends StatelessWidget {
  const _ModeRail({
    required this.chronicleAvailable,
    required this.onChronicle,
    required this.onSkirmish,
  });

  final bool chronicleAvailable;
  final VoidCallback? onChronicle;
  final VoidCallback onSkirmish;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 10,
    runSpacing: 10,
    children: [
      TacticalButton(
        key: chronicleAvailable
            ? const Key('chronicle-mode')
            : const Key('chronicle-deploy-disabled'),
        label: chronicleAvailable
            ? 'CHRONICLE'
            : context.l10n.chronicleUnavailable,
        color: TokenfrontColors.relayIvory,
        onPressed: chronicleAvailable ? onChronicle : null,
      ),
      TacticalButton(
        key: chronicleAvailable
            ? const Key('skirmish-mode')
            : const Key('skirmish-deploy'),
        label: 'SKIRMISH',
        color: TokenfrontColors.cobalt,
        onPressed: onSkirmish,
      ),
    ],
  );
}

class _BriefingHeader extends StatelessWidget {
  const _BriefingHeader({required this.operation});

  final StoryOperation operation;

  @override
  Widget build(BuildContext context) => TacticalPanel(
    color: TokenfrontColors.deepField.withValues(alpha: .82),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OP-${(operation.id.index + 1).toString().padLeft(2, '0')} // SIGNAL CHRONICLE',
          style: TokenfrontType.instrument.copyWith(
            color: TokenfrontColors.relayIvory,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'SEED ${operation.seed}  //  ${operation.duration.inSeconds}s',
          style: TokenfrontType.instrument.copyWith(
            color: TokenfrontColors.quietText,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.compact});
  final bool compact;

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
                fontSize: compact ? 35 : 58,
                color: TokenfrontColors.relayIvory,
                shadows: const [
                  Shadow(color: TokenfrontColors.deepField, blurRadius: 12),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              context.l10n.lobbyTagline,
              style: TokenfrontType.instrument.copyWith(
                fontSize: compact ? 10 : 13,
                color: TokenfrontColors.quietText,
              ),
            ),
          ],
        ),
      ),
      TacticalPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          '${context.l10n.offline}\n15:00',
          textAlign: TextAlign.right,
          style: TokenfrontType.instrument.copyWith(fontSize: 11, height: 1.4),
        ),
      ),
    ],
  );
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
    spacing: compact ? 9 : 14,
    runSpacing: compact ? 9 : 14,
    children: [
      for (final faction in Faction.values)
        _FactionCard(
          faction: faction,
          selected: faction == selected,
          compact: compact,
          onTap: () => onSelected(faction),
        ),
    ],
  );
}

class _FactionCard extends StatelessWidget {
  const _FactionCard({
    required this.faction,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final Faction faction;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = faction.visual;
    return Semantics(
      label: context.l10n.chooseFaction(visual.name),
      selected: selected,
      button: true,
      child: SizedBox(
        width: compact ? 146 : 205,
        height: compact ? 120 : 150,
        child: Material(
          color: selected
              ? Color.alphaBlend(
                  visual.color.withValues(alpha: .24),
                  TokenfrontColors.deepField.withValues(alpha: .88),
                )
              : TokenfrontColors.deepField.withValues(alpha: .78),
          shape: BeveledRectangleBorder(
            side: BorderSide(
              color: selected
                  ? visual.color
                  : TokenfrontColors.relayIvory.withValues(alpha: .22),
              width: selected ? 2 : 1,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            focusColor: visual.color.withValues(alpha: .22),
            hoverColor: visual.color.withValues(alpha: .09),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FactionGlyph(
                    kind: _glyphFor(faction),
                    color: visual.color,
                    size: compact ? 41 : 55,
                    selected: selected,
                  ),
                  const SizedBox(height: 11),
                  Text(
                    visual.name,
                    style: TokenfrontType.instrument.copyWith(
                      color: selected
                          ? TokenfrontColors.relayIvory
                          : visual.color,
                      fontSize: compact ? 12 : 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    context.l10n.unitsCount(1000),
                    style: TextStyle(
                      color: TokenfrontColors.quietText,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RulesStrip extends StatelessWidget {
  const _RulesStrip();

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 22,
    runSpacing: 9,
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

class _SponsorRail extends StatelessWidget {
  const _SponsorRail();

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.sponsorBannerArea,
    child: TacticalPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      color: TokenfrontColors.deepField.withValues(alpha: .72),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.l10n.sponsorSignal,
            style: TokenfrontType.instrument.copyWith(fontSize: 9),
          ),
          const SizedBox(width: 9),
          Text(
            context.l10n.lobbyPlacement,
            style: TokenfrontType.instrument.copyWith(
              color: TokenfrontColors.quietText,
              fontSize: 8,
            ),
          ),
        ],
      ),
    ),
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
      Text(label, style: TokenfrontType.instrument.copyWith(fontSize: 11)),
      const SizedBox(width: 6),
      Text(
        detail,
        style: TokenfrontType.instrument.copyWith(
          color: TokenfrontColors.quietText,
          fontSize: 9,
        ),
      ),
    ],
  );
}

FactionGlyphKind _glyphFor(Faction faction) => switch (faction) {
  Faction.amethyst => FactionGlyphKind.diamond,
  Faction.cobalt => FactionGlyphKind.brackets,
  Faction.volt => FactionGlyphKind.bolt,
  Faction.prism => FactionGlyphKind.prism,
};
