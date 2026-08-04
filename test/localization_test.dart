import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/app/tokenfront_state_store.dart';
import 'package:tokenfront/l10n/l10n.dart';
import 'package:tokenfront/main.dart';
import 'package:tokenfront/services/privacy/privacy_state.dart';
import 'package:tokenfront/story/story_localizations.dart';
import 'package:tokenfront/story/story_models.dart';

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

  testWidgets('Signal Chronicle copy is complete in every supported locale', (
    tester,
  ) async {
    const productContracts = <String, (String, String, String)>{
      'en': (
        'Tokenfront: Orbital Signal War',
        'FOUR AI CORES. ONE LAST RELAY.',
        'DEPLOY TO ORBIT',
      ),
      'ko': ('Tokenfront: 궤도 신호전', '네 AI 코어. 단 하나의 최후 릴레이.', '궤도 투입'),
      'ja': ('Tokenfront: 軌道信号戦', '4つのAIコア。最後のリレーは1つ。', '軌道へ展開'),
      'zh': ('Tokenfront：轨道信号战', '四个AI核心，最后一座中继站。', '部署至轨道'),
    };

    for (final locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final copy = StoryLocalizations(context.l10n);
              for (final operation in StoryOperationId.values) {
                expect(copy.operationTitle(operation), isNotEmpty);
                expect(copy.briefing(operation), isNotEmpty);
                expect(copy.transmission(operation), isNotEmpty);
                expect(copy.response(operation), isNotEmpty);
              }
              for (final kind in DirectiveKind.values) {
                expect(copy.directiveLabel(kind, target: 45), isNotEmpty);
              }
              for (final ending in EndingChoice.values) {
                expect(copy.endingLabel(ending), isNotEmpty);
                expect(copy.endingEpilogue(ending), isNotEmpty);
              }
              final contract = productContracts[locale.languageCode]!;
              expect(context.l10n.appTitle, contract.$1);
              expect(context.l10n.lobbyTagline, contract.$2);
              expect(context.l10n.deploySignal, contract.$3);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
    }
  });

  testWidgets('Signal Chronicle English prologue uses the approved sentence', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SizedBox.shrink(),
      ),
    );
    await tester.pump();
    final context = tester.element(find.byType(SizedBox));
    expect(
      StoryLocalizations(context.l10n).prologue,
      'The surface has been silent for 72 years. '
      'You are a command signal without a body. '
      'The Last Relay is calling.',
    );
  });

  testWidgets('Command Deck archive and ring labels stay localized', (
    tester,
  ) async {
    for (final locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final copy = StoryLocalizations(context.l10n);
              expect(copy.commandDeck, isNotEmpty);
              expect(copy.archive, isNotEmpty);
              expect(copy.restart, isNotEmpty);
              expect(copy.archiveSimulation, isNotEmpty);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
    }
  });

  test('operation numbers are supplied as locale data, not fixed ARB copy', () {
    const localeCodes = <String>['en', 'ko', 'ja', 'zh'];
    const titleKeys = <String>[
      'operationWakeTitle',
      'operationEchoTitle',
      'operationSplitTitle',
      'operationCrownTitle',
      'operationLastInstructionTitle',
    ];
    for (final locale in localeCodes) {
      final arb =
          jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
              as Map<String, dynamic>;
      for (final key in titleKeys) {
        expect(arb[key], isNot(contains(RegExp(r'OP-0[1-5]'))));
        expect(arb[key], contains('{operation'));
      }
    }
  });

  testWidgets('localized directive rules preserve every numeric boundary', (
    tester,
  ) async {
    const expected = <String, List<String>>{
      'en': <String>[
        'Maintain one uninterrupted command link for 45 seconds.',
        'Complete 2 command handoffs.',
        'Accumulate 3 kills by directly commanded units.',
        'Finish at rank 2 or better.',
        'Win the battle.',
      ],
      'ko': <String>[
        '지휘 연결 45초 유지',
        '지휘권 인계 2회 완료',
        '직접 지휘 처치 3회',
        '2위 이상으로 종료',
        '단독 승리',
      ],
      'ja': <String>[
        '指揮リンクを45秒維持',
        '指揮引き継ぎを2回完了',
        '直接指揮で3体撃破',
        '2位以内で終了',
        '単独勝利',
      ],
      'zh': <String>[
        '保持指挥链路45秒',
        '完成2次指挥交接',
        '直接指挥击破3个单位',
        '以第2名或更高名次结束',
        '单独获胜',
      ],
    };
    for (final locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final copy = StoryLocalizations(context.l10n);
              final actual = <String>[
                copy.directiveLabel(
                  DirectiveKind.longestCommandLink,
                  target: 45,
                ),
                copy.directiveLabel(DirectiveKind.commandRelays, target: 2),
                copy.directiveLabel(DirectiveKind.commandKills, target: 3),
                copy.directiveLabel(DirectiveKind.finalRank, target: 2),
                copy.directiveLabel(DirectiveKind.victory),
              ];
              expect(actual, expected[locale.languageCode]);
              for (
                var index = 0;
                index < StoryOperationId.values.length;
                index++
              ) {
                expect(
                  copy.operationTitle(StoryOperationId.values[index]),
                  contains('OP-0${index + 1}'),
                );
              }
              for (final amount in const <int>[15, 20, 25, 30, 40]) {
                expect(copy.directiveBonus(amount), contains('$amount'));
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
    }
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
