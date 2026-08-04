import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/app/tokenfront_state_store.dart';

void main() {
  test(
    'web platform store round-trips before the app widget is mounted',
    () async {
      final store = createTokenfrontStateStore();
      const payload = '{"qa":"web-bootstrap"}';

      await store.write(payload);

      expect(await store.read(), payload);
    },
    skip: !kIsWeb,
  );
}
