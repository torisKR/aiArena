import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/ui/launch_splash.dart';

void main() {
  testWidgets('artwork is contained and hands off after two seconds', (
    tester,
  ) async {
    await tester.pumpWidget(
      const LaunchSplash(child: SizedBox(key: Key('app'))),
    );
    expect(find.byKey(const Key('launch-splash')), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, LaunchSplash.asset);
    expect(image.fit, BoxFit.contain);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.byKey(const Key('app')), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('app')), findsOneWidget);
    expect(find.byKey(const Key('launch-splash')), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('app')), findsOneWidget);
  });

  testWidgets('unmount cancels the pending handoff', (tester) async {
    await tester.pumpWidget(const LaunchSplash(child: SizedBox()));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
