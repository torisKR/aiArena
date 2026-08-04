import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../economy/cosmetic_catalog.dart';
import '../economy/war_token_wallet.dart';
import '../l10n/l10n.dart';
import 'primitives.dart';

Future<void> showSignalLocker({
  required BuildContext context,
  required WarTokenWallet wallet,
  required VoidCallback onWalletChanged,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: TokenfrontColors.deepField.withValues(alpha: .78),
  builder: (context) =>
      _SignalLocker(wallet: wallet, onWalletChanged: onWalletChanged),
);

class _SignalLocker extends StatefulWidget {
  const _SignalLocker({required this.wallet, required this.onWalletChanged});

  final WarTokenWallet wallet;
  final VoidCallback onWalletChanged;

  @override
  State<_SignalLocker> createState() => _SignalLockerState();
}

class _SignalLockerState extends State<_SignalLocker> {
  void _act(CosmeticDefinition definition) {
    final item = definition.item;
    if (!widget.wallet.isUnlocked(item.id)) {
      final result = widget.wallet.unlock(item);
      if (result == CosmeticUnlockResult.insufficientFunds) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.needMoreWarTokens(item.cost - widget.wallet.balance),
            ),
          ),
        );
        return;
      }
    }
    widget.wallet.equip(item);
    widget.onWalletChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 920),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Material(
          color: TokenfrontColors.battlefieldOxide,
          shape: const BeveledRectangleBorder(
            side: BorderSide(color: Color(0x99F2E9D1)),
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.signalLocker,
                            style: TokenfrontType.display.copyWith(
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            context.l10n.lockerSubtitle,
                            style: TokenfrontType.body.copyWith(
                              color: TokenfrontColors.quietText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TacticalPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: Text(
                        context.l10n.warTokenBalance(widget.wallet.balance),
                        style: TokenfrontType.instrument.copyWith(fontSize: 10),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.closeSignalLocker,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                for (final category in CosmeticCategory.values) ...[
                  Text(
                    _categoryLabel(context.l10n, category),
                    style: TokenfrontType.instrument.copyWith(
                      color: TokenfrontColors.quietText,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 9),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 720
                          ? 3
                          : constraints.maxWidth >= 480
                          ? 2
                          : 1;
                      final width =
                          (constraints.maxWidth - (columns - 1) * 10) / columns;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final definition in CosmeticCatalog.forCategory(
                            category,
                          ))
                            SizedBox(
                              width: width,
                              child: _CosmeticCard(
                                definition: definition,
                                unlocked: widget.wallet.isUnlocked(
                                  definition.item.id,
                                ),
                                equipped:
                                    widget.wallet.equippedId(category) ==
                                    definition.item.id,
                                onPressed: () => _act(definition),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _CosmeticCard extends StatelessWidget {
  const _CosmeticCard({
    required this.definition,
    required this.unlocked,
    required this.equipped,
    required this.onPressed,
  });

  final CosmeticDefinition definition;
  final bool unlocked;
  final bool equipped;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = Color(definition.accentValue);
    return TacticalPanel(
      borderColor: equipped ? accent : TokenfrontColors.panelStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: ShapeDecoration(
                  color: accent.withValues(alpha: .26),
                  shape: BeveledRectangleBorder(
                    side: BorderSide(color: accent),
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _cosmeticName(context.l10n, definition.item.id),
                  style: TokenfrontType.instrument.copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            _cosmeticDescription(context.l10n, definition.item.id),
            style: TokenfrontType.body.copyWith(
              color: TokenfrontColors.quietText,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: equipped ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: TokenfrontColors.relayIvory,
                side: BorderSide(color: accent.withValues(alpha: .72)),
                shape: const BeveledRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(7)),
                ),
                textStyle: TokenfrontType.instrument.copyWith(fontSize: 9),
              ),
              child: Text(
                equipped
                    ? context.l10n.equipped
                    : unlocked
                    ? context.l10n.equip
                    : context.l10n.unlockCost(definition.item.cost),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _categoryLabel(AppLocalizations l10n, CosmeticCategory category) =>
    switch (category) {
      CosmeticCategory.factionColor => l10n.commandEdge,
      CosmeticCategory.movementTrail => l10n.movementTrace,
      CosmeticCategory.deathEffect => l10n.defeatMark,
    };

String _cosmeticName(AppLocalizations l10n, String id) => switch (id) {
  'color_field_issue' => l10n.cosmeticFieldIssueName,
  'color_relay_ivory' => l10n.cosmeticRelayIvoryName,
  'color_oxide' => l10n.cosmeticOxideEdgeName,
  'trail_none' => l10n.cosmeticCleanWakeName,
  'trail_relay_tape' => l10n.cosmeticRelayTapeName,
  'trail_cinder' => l10n.cosmeticCinderGridName,
  'death_ring' => l10n.cosmeticSignalRingName,
  'death_fracture' => l10n.cosmeticFractureName,
  _ => throw StateError('Missing localized cosmetic name for $id'),
};

String _cosmeticDescription(AppLocalizations l10n, String id) => switch (id) {
  'color_field_issue' => l10n.cosmeticFieldIssueDescription,
  'color_relay_ivory' => l10n.cosmeticRelayIvoryDescription,
  'color_oxide' => l10n.cosmeticOxideEdgeDescription,
  'trail_none' => l10n.cosmeticCleanWakeDescription,
  'trail_relay_tape' => l10n.cosmeticRelayTapeDescription,
  'trail_cinder' => l10n.cosmeticCinderGridDescription,
  'death_ring' => l10n.cosmeticSignalRingDescription,
  'death_fracture' => l10n.cosmeticFractureDescription,
  _ => throw StateError('Missing localized cosmetic description for $id'),
};
