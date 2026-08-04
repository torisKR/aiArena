enum CosmeticCategory { factionColor, movementTrail, deathEffect }

/// A non-gameplay item. The economy intentionally has no generic purchase API.
final class CosmeticItem {
  const CosmeticItem({
    required this.id,
    required this.category,
    required this.cost,
  }) : assert(id != ''),
       assert(cost >= 0);

  final String id;
  final CosmeticCategory category;
  final int cost;
}

enum CosmeticUnlockResult { unlocked, alreadyUnlocked, insufficientFunds }

enum CosmeticEquipResult { equipped, locked }

/// Runtime-owned wallet whose only spending operation unlocks cosmetics.
///
/// The app runtime persists versioned snapshots of this model. It remains a
/// local soft-currency wallet rather than a purchase or account ledger.
final class WarTokenWallet {
  WarTokenWallet({
    int initialBalance = 0,
    Iterable<String> initialUnlockedIds = const <String>[],
    Map<CosmeticCategory, String> initialEquippedIds =
        const <CosmeticCategory, String>{},
  }) : assert(initialBalance >= 0),
       _balance = initialBalance {
    _unlockedIds.addAll(initialUnlockedIds.where((id) => id.isNotEmpty));
    for (final entry in initialEquippedIds.entries) {
      if (_unlockedIds.contains(entry.value)) {
        _equippedIds[entry.key] = entry.value;
      }
    }
  }

  int _balance;
  final Set<String> _unlockedIds = <String>{};
  final Map<CosmeticCategory, String> _equippedIds =
      <CosmeticCategory, String>{};

  int get balance => _balance;
  Set<String> get unlockedIds => Set<String>.unmodifiable(_unlockedIds);
  Map<CosmeticCategory, String> get equippedIds =>
      Map<CosmeticCategory, String>.unmodifiable(_equippedIds);

  /// Credits the guaranteed match reward, doubled only after a completed ad.
  int creditMatchReward({
    required int baseAmount,
    required bool rewardedAdCompleted,
  }) {
    if (baseAmount < 0) {
      throw ArgumentError.value(
        baseAmount,
        'baseAmount',
        'must be non-negative',
      );
    }
    final credited = baseAmount * (rewardedAdCompleted ? 2 : 1);
    _balance += credited;
    return credited;
  }

  /// Credits only the extra half of a 2x rewarded result after the ad adapter
  /// reports a completed reward. The result screen guards this operation
  /// by match id so a completed offer cannot be claimed twice.
  int creditRewardedBonus(int baseAmount) {
    if (baseAmount < 0) {
      throw ArgumentError.value(
        baseAmount,
        'baseAmount',
        'must be non-negative',
      );
    }
    _balance += baseAmount;
    return baseAmount;
  }

  bool isUnlocked(String cosmeticId) => _unlockedIds.contains(cosmeticId);

  CosmeticUnlockResult unlock(CosmeticItem item) {
    if (_unlockedIds.contains(item.id)) {
      return CosmeticUnlockResult.alreadyUnlocked;
    }
    if (_balance < item.cost) {
      return CosmeticUnlockResult.insufficientFunds;
    }
    _balance -= item.cost;
    _unlockedIds.add(item.id);
    return CosmeticUnlockResult.unlocked;
  }

  CosmeticEquipResult equip(CosmeticItem item) {
    if (!_unlockedIds.contains(item.id)) {
      return CosmeticEquipResult.locked;
    }
    _equippedIds[item.category] = item.id;
    return CosmeticEquipResult.equipped;
  }

  String? equippedId(CosmeticCategory category) => _equippedIds[category];
}
