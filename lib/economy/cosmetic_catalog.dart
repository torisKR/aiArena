import 'war_token_wallet.dart';

final class CosmeticDefinition {
  const CosmeticDefinition({
    required this.item,
    required this.name,
    required this.description,
    required this.accentValue,
  });

  final CosmeticItem item;
  final String name;
  final String description;

  /// ARGB value kept UI-framework agnostic for deterministic loadouts.
  final int accentValue;
}

abstract final class CosmeticCatalog {
  static const items = <CosmeticDefinition>[
    CosmeticDefinition(
      item: CosmeticItem(
        id: 'color_field_issue',
        category: CosmeticCategory.factionColor,
        cost: 0,
      ),
      name: 'FIELD ISSUE',
      description: 'Standard faction signal pigment.',
      accentValue: 0xFFF2E9D1,
    ),
    CosmeticDefinition(
      item: CosmeticItem(
        id: 'color_relay_ivory',
        category: CosmeticCategory.factionColor,
        cost: 90,
      ),
      name: 'RELAY IVORY',
      description: 'Ivory command outline; faction core stays readable.',
      accentValue: 0xFFF2E9D1,
    ),
    CosmeticDefinition(
      item: CosmeticItem(
        id: 'color_oxide',
        category: CosmeticCategory.factionColor,
        cost: 140,
      ),
      name: 'OXIDE EDGE',
      description: 'Warm tactical edge for the controlled token.',
      accentValue: 0xFFFF8D6D,
    ),
    CosmeticDefinition(
      item: CosmeticItem(
        id: 'trail_none',
        category: CosmeticCategory.movementTrail,
        cost: 0,
      ),
      name: 'CLEAN WAKE',
      description: 'No persistent movement trace.',
      accentValue: 0x00F2E9D1,
    ),
    CosmeticDefinition(
      item: CosmeticItem(
        id: 'trail_relay_tape',
        category: CosmeticCategory.movementTrail,
        cost: 110,
      ),
      name: 'RELAY TAPE',
      description: 'A short segmented command trace.',
      accentValue: 0xBFF2E9D1,
    ),
    CosmeticDefinition(
      item: CosmeticItem(
        id: 'trail_cinder',
        category: CosmeticCategory.movementTrail,
        cost: 160,
      ),
      name: 'CINDER GRID',
      description: 'A sparse oxide wake for fast movement.',
      accentValue: 0xBFFF8D6D,
    ),
    CosmeticDefinition(
      item: CosmeticItem(
        id: 'death_ring',
        category: CosmeticCategory.deathEffect,
        cost: 0,
      ),
      name: 'SIGNAL RING',
      description: 'Standard compact defeat pulse.',
      accentValue: 0xFFF2E9D1,
    ),
    CosmeticDefinition(
      item: CosmeticItem(
        id: 'death_fracture',
        category: CosmeticCategory.deathEffect,
        cost: 130,
      ),
      name: 'FOUR-WAY FRACTURE',
      description: 'A crisp geometric break with no gameplay effect.',
      accentValue: 0xFFFF8D6D,
    ),
  ];

  static Iterable<CosmeticDefinition> forCategory(CosmeticCategory category) =>
      items.where((definition) => definition.item.category == category);

  static CosmeticDefinition byId(String id) =>
      items.firstWhere((definition) => definition.item.id == id);

  static void installDefaults(WarTokenWallet wallet) {
    for (final definition in items.where(
      (definition) => definition.item.cost == 0,
    )) {
      wallet.unlock(definition.item);
      if (wallet.equippedId(definition.item.category) == null) {
        wallet.equip(definition.item);
      }
    }
  }
}

final class CosmeticLoadout {
  const CosmeticLoadout({
    required this.colorId,
    required this.trailId,
    required this.deathEffectId,
  });

  factory CosmeticLoadout.fromWallet(WarTokenWallet wallet) => CosmeticLoadout(
    colorId:
        wallet.equippedId(CosmeticCategory.factionColor) ?? 'color_field_issue',
    trailId: wallet.equippedId(CosmeticCategory.movementTrail) ?? 'trail_none',
    deathEffectId:
        wallet.equippedId(CosmeticCategory.deathEffect) ?? 'death_ring',
  );

  final String colorId;
  final String trailId;
  final String deathEffectId;
}
