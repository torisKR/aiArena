import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/idle/idle_persistence.dart';
import 'package:tokenfront/l10n/app_localizations.dart';
import 'package:tokenfront/ui/idle_screen.dart';
import 'package:tokenfront/ui/primitives.dart';

void main() {
  Widget localizedIdle({
    required Locale locale,
    required IdleRepository Function() repositoryFactory,
    double textScale = 1,
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: IdleScreen(
          repositoryFactory: repositoryFactory,
          onBack: () {},
        ),
      ),
    );
  }

  testWidgets('idle UI renders in every supported locale at narrow width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    for (final locale in const [
      Locale('en'),
      Locale('ko'),
      Locale('ja'),
      Locale('zh'),
    ]) {
      final repository = IdleRepository(
        MemoryIdleStateStore(),
        () => DateTime.utc(2026, 1, 1),
      );
      await tester.pumpWidget(
        localizedIdle(locale: locale, repositoryFactory: () => repository),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('idle UI survives landscape and large text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(568, 320));
    final repository = IdleRepository(
      MemoryIdleStateStore(),
      () => DateTime.utc(2026, 1, 1),
    );
    await tester.pumpWidget(
      localizedIdle(
        locale: const Locale('ja'),
        repositoryFactory: () => repository,
        textScale: 2,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(Scaffold), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('upgrade stays disabled when credits are insufficient', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(
      localizedIdle(
        locale: const Locale('en'),
        repositoryFactory: () => IdleRepository(
          MemoryIdleStateStore(),
          () => DateTime.utc(2026, 1, 1),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    final button = tester.widget<TacticalButton>(
      find.byKey(const Key('idle-upgrade')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('save error exposes retry and succeeds on the next attempt', (
    tester,
  ) async {
    final store = FlakyIdleStateStore()..failNextWrite = true;
    final repository = IdleRepository(
      store,
      () => DateTime.utc(2026, 1, 1),
    );
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(
      localizedIdle(locale: const Locale('en'), repositoryFactory: () => repository),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('idle-save-retry')), findsOneWidget);
    expect(find.byKey(const Key('idle-upgrade')), findsNothing);

    await tester.tap(find.byKey(const Key('idle-save-retry')));
    await tester.pump();
    for (var i = 0; i < 10 && find.byKey(const Key('idle-upgrade')).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byKey(const Key('idle-upgrade')), findsOneWidget);
    expect(find.byKey(const Key('idle-save-retry')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

final class MemoryIdleStateStore implements IdleStateStore {
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async => this.value = value;
}

final class FlakyIdleStateStore implements IdleStateStore {
  bool failNextWrite = false;
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('storage unavailable');
    }
    this.value = value;
  }
}
