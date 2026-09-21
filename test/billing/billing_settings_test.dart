import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'billing_controller_test.dart' as f;
import 'remove_ads_billing_test.dart' as s;
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/l10n/l10n.dart';
import 'package:tokenfront/services/billing/billing_controller.dart';
import 'package:tokenfront/ui/billing_settings.dart';

void main() {
  for (final language in ['en', 'ko', 'ja', 'zh']) {
    testWidgets('deletion confirmation can be canceled in $language', (
      tester,
    ) async {
      final store = s.FakeStore();
      final billing = BillingController(
        backend: f.Backend(),
        sku: s.sku,
        cache: f.MemoryCache(),
        storeFactory: (_) => store,
      );
      await billing.signIn();
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BillingSettings(billing: billing),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.byKey(const Key('billing-delete')));
      await tester.tap(find.byKey(const Key('billing-delete')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      final l = AppLocalizations.of(tester.element(find.byType(AlertDialog)));
      expect(find.text(l.billingDeleteWarning), findsOneWidget);
      await tester.tap(find.byKey(const Key('billing-delete-cancel')));
      await tester.pumpAndSettle();
      expect(billing.signedIn, true);
      await tester.pumpWidget(const SizedBox());
      billing.dispose();
      await store.events.close();
    });
  }

  testWidgets('store localized price and cancellation update settings live', (
    tester,
  ) async {
    final store = s.FakeStore();
    final billing = BillingController(
      backend: f.Backend(),
      sku: s.sku,
      cache: f.MemoryCache(),
      storeFactory: (_) => store,
    );
    await billing.signIn();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: BillingSettings(billing: billing)),
      ),
    );
    expect(find.text('Buy · ₩3,000'), findsOneWidget);
    await tester.tap(find.byKey(const Key('billing-buy')));
    await tester.pump();
    store.events.add([s.purchase(PurchaseStatus.canceled)]);
    await tester.pump();
    expect(find.text('Canceled. You can try again.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    billing.dispose();
    await store.events.close();
  });
  testWidgets(
    'unconfigured settings show unavailable and disabled purchase restore Google controls',
    (tester) async {
      final billing = BillingController.unavailable();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: BillingSettings(billing: billing)),
        ),
      );
      expect(find.text('Purchases unavailable'), findsOneWidget);
      for (final key in ['billing-buy', 'billing-restore', 'billing-login']) {
        expect(
          tester.widget<OutlinedButton>(find.byKey(Key(key))).onPressed,
          isNull,
        );
      }
      billing.dispose();
    },
  );
}
