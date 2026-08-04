import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/app/tokenfront_state_store.dart';
import 'package:tokenfront/l10n/l10n.dart';
import 'package:tokenfront/main.dart';
import 'package:tokenfront/services/privacy/privacy_state.dart';

final class _MemoryStateStore implements TokenfrontStateStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

void main() {
  test('English Korean Japanese and Simplified Chinese are supported', () {
    expect(AppLocalizations.supportedLocales, <Locale>[
      const Locale('en'),
      const Locale('ko'),
      const Locale('ja'),
      const Locale('zh'),
    ]);
  });

  test('system locale resolution does not mislabel Traditional Chinese', () {
    expect(
      TokenfrontLocales.resolve(const <Locale>[
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ], AppLocalizations.supportedLocales),
      const Locale('zh'),
    );
    expect(
      TokenfrontLocales.resolve(const <Locale>[
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ], AppLocalizations.supportedLocales),
      const Locale('en'),
    );
  });

  testWidgets('missing localization configuration fails loudly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            context.l10n;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('explicit Korean choice localizes the lobby immediately', (
    tester,
  ) async {
    final runtime = TokenfrontRuntime(platform: ClientPlatform.web);
    addTearDown(runtime.dispose);
    runtime.preferences.setLanguageCode('ko');

    await tester.pumpWidget(TokenfrontApp(runtime: runtime));
    await tester.pumpAndSettle();

    expect(find.text('궤도 투입'), findsOneWidget);
    expect(find.text('SIGNAL SETTINGS'), findsNothing);
  });

  testWidgets('system language selects Japanese when no override exists', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localesTestValue = const <Locale>[
      Locale('ja'),
    ];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    final runtime = TokenfrontRuntime(platform: ClientPlatform.web);
    addTearDown(runtime.dispose);

    await tester.pumpWidget(TokenfrontApp(runtime: runtime));
    await tester.pumpAndSettle();

    expect(find.text('軌道へ展開'), findsOneWidget);
  });

  testWidgets('language selector updates an open settings panel immediately', (
    tester,
  ) async {
    final runtime = TokenfrontRuntime(platform: ClientPlatform.web);
    addTearDown(runtime.dispose);

    await tester.pumpWidget(TokenfrontApp(runtime: runtime));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('language-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('한국어').last);
    await tester.pumpAndSettle();

    expect(runtime.preferences.languageCode, 'ko');
    expect(find.text('신호 조정'), findsOneWidget);
    expect(find.text('SIGNAL CONDITIONING'), findsNothing);
  });

  for (final localeCase
      in const <({String code, String deploy, String status, String tune})>[
        (code: 'ko', deploy: '궤도 투입', status: '처치', tune: '조정'),
        (code: 'ja', deploy: '軌道へ展開', status: '撃破', tune: '調整'),
        (code: 'zh', deploy: '部署至轨道', status: '击杀', tune: '调校'),
      ]) {
    testWidgets('${localeCase.code} remains usable on a narrow screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final runtime = TokenfrontRuntime(platform: ClientPlatform.web);
      addTearDown(runtime.dispose);
      runtime.preferences
        ..setAudioEnabled(false)
        ..setHapticsEnabled(false)
        ..setLanguageCode(localeCase.code);

      await tester.pumpWidget(TokenfrontApp(runtime: runtime));
      await tester.pumpAndSettle();

      expect(find.text(localeCase.deploy), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(localeCase.tune));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('language-selector')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(localeCase.deploy));
      await tester.tap(find.text(localeCase.deploy));
      await tester.pump();
      expect(find.textContaining(localeCase.status), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('language choice survives runtime recreation', () async {
    final store = _MemoryStateStore();
    final first = await TokenfrontRuntime.restore(
      platform: ClientPlatform.web,
      stateStore: store,
    );
    first.preferences.setLanguageCode('zh');
    await first.flushLocalState();
    first.dispose();

    final restored = await TokenfrontRuntime.restore(
      platform: ClientPlatform.web,
      stateStore: store,
    );
    addTearDown(restored.dispose);
    expect(restored.preferences.languageCode, 'zh');
  });
}
