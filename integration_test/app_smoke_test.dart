import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/main.dart';
import 'package:tokenfront/settings/game_preferences.dart';
import 'package:tokenfront/ui/battle_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches, configures, deploys, and survives app resume', (
    tester,
  ) async {
    final runtime = TokenfrontRuntime(
      preferences: GamePreferences(audioEnabled: false, hapticsEnabled: false),
    );
    addTearDown(runtime.dispose);
    await tester.pumpWidget(TokenfrontApp(runtime: runtime));
    await tester.pumpAndSettle();

    expect(find.text('TOKENFRONT'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.text('SIGNAL CONDITIONING'), findsOneWidget);
    await tester.tap(find.byTooltip('Close settings'));
    await tester.pumpAndSettle();

    if (find.text('DEPLOY SIGNAL').evaluate().isNotEmpty) {
      await tester.ensureVisible(find.text('DEPLOY SIGNAL'));
      await tester.tap(find.text('DEPLOY SIGNAL'));
    } else {
      await tester.tap(find.text('SKIRMISH').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('skirmish-deploy')));
    }
    await tester.pump();
    expect(find.byType(BattleScreen), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('SIGNAL HELD  /  BATTLE PAUSED'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('SIGNAL HELD  /  BATTLE PAUSED'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
