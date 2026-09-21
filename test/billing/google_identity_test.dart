import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/services/identity/android_google_identity.dart';
import 'package:tokenfront/services/identity/google_identity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('tokenfront/google_identity');
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test('native method receives exact nonce and Web audience', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'signIn' ? 'id-token' : null;
        });
    final google = AndroidGoogleIdentity();
    expect(
      await google.signIn(
        serverClientId: '123-test.apps.googleusercontent.com',
        nonce: 'n' * 43,
      ),
      'id-token',
    );
    expect(calls.single.arguments, {
      'serverClientId': '123-test.apps.googleusercontent.com',
      'nonce': 'n' * 43,
    });
    await google.clearCredentialState();
    expect(calls.last.method, 'clearCredentialState');
  });
  test('platform cancellation redacts native error details', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(
            code: 'canceled',
            message: 'secret',
            details: 'secret',
          );
        });
    await expectLater(
      AndroidGoogleIdentity().signIn(
        serverClientId: '123-test.apps.googleusercontent.com',
        nonce: 'n' * 43,
      ),
      throwsA(
        isA<IdentityException>()
            .having((e) => e.code, 'code', 'canceled')
            .having((e) => e.toString().contains('secret'), 'redacted', false),
      ),
    );
  });
  test('unsupported platform fails closed', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await expectLater(
      AndroidGoogleIdentity().signIn(
        serverClientId: '123-test.apps.googleusercontent.com',
        nonce: 'n' * 43,
      ),
      throwsA(
        isA<IdentityException>().having((e) => e.code, 'code', 'unsupported'),
      ),
    );
  });
}
