import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/app/tokenfront_state_store.dart';

void main() {
  test('web localStorage survives state-store recreation', () async {
    final firstStore = createTokenfrontStateStore();
    final payload =
        '{"qa":"web-store-recreation","run":${DateTime.now().microsecondsSinceEpoch}}';

    await firstStore.write(payload);

    final recreatedStore = createTokenfrontStateStore();

    expect(recreatedStore, isNot(same(firstStore)));
    expect(await recreatedStore.read(), payload);
  }, skip: !kIsWeb);
}
