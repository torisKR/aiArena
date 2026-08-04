import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/economy/cosmetic_catalog.dart';
import 'package:tokenfront/economy/war_token_wallet.dart';

void main() {
  test('catalog installs and equips only zero-cost defaults', () {
    final wallet = WarTokenWallet();

    CosmeticCatalog.installDefaults(wallet);

    expect(wallet.unlockedIds, hasLength(3));
    expect(wallet.equippedIds, hasLength(3));
    expect(wallet.equippedId(CosmeticCategory.movementTrail), 'trail_none');
  });

  test('War Tokens can unlock and equip cosmetics only', () {
    final wallet = WarTokenWallet(initialBalance: 200);
    CosmeticCatalog.installDefaults(wallet);
    final tape = CosmeticCatalog.byId('trail_relay_tape');

    expect(wallet.equip(tape.item), CosmeticEquipResult.locked);
    expect(wallet.unlock(tape.item), CosmeticUnlockResult.unlocked);
    expect(wallet.balance, 90);
    expect(wallet.equip(tape.item), CosmeticEquipResult.equipped);
    expect(CosmeticLoadout.fromWallet(wallet).trailId, 'trail_relay_tape');
  });

  test('rewarded bonus adds only the second half of a 2x reward', () {
    final wallet = WarTokenWallet();

    expect(
      wallet.creditMatchReward(baseAmount: 40, rewardedAdCompleted: false),
      40,
    );
    expect(wallet.creditRewardedBonus(40), 40);
    expect(wallet.balance, 80);
  });
}
