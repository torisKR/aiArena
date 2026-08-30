import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/design/tokens.dart';
import 'package:tokenfront/ui/primitives.dart';

void main() {
  testWidgets('TacticalPanel is a square narrative plane on the token scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TacticalPanel(child: Text('narrative'))),
    );

    final panel = tester.widget<Container>(
      find.descendant(
        of: find.byType(TacticalPanel),
        matching: find.byType(Container),
      ),
    );
    expect(panel.padding, const EdgeInsets.all(TokenfrontSpacing.lg));
    final decoration = panel.decoration! as ShapeDecoration;
    final shape = decoration.shape as BeveledRectangleBorder;
    expect(shape.borderRadius, BorderRadius.zero);
    expect(shape.side.color, TokenfrontColors.panelBorder);
  });

  testWidgets('TacticalButton uses canonical size, padding, gap, and radius', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TacticalButton(
          label: 'DEPLOY',
          icon: const Icon(Icons.bolt),
          onPressed: () {},
        ),
      ),
    );

    final filled = tester.widget<FilledButton>(find.byType(FilledButton));
    final style = filled.style!;
    expect(
      style.minimumSize!.resolve(<WidgetState>{}),
      TokenfrontSizes.buttonSize,
    );
    expect(
      style.padding!.resolve(<WidgetState>{}),
      const EdgeInsets.symmetric(
        horizontal: TokenfrontSpacing.buttonHorizontal,
        vertical: TokenfrontSpacing.buttonVertical,
      ),
    );
    final shape =
        style.shape!.resolve(<WidgetState>{})! as BeveledRectangleBorder;
    expect(
      shape.borderRadius,
      const BorderRadius.all(Radius.circular(TokenfrontRadii.control)),
    );
    expect(
      tester.widget<SizedBox>(find.byType(SizedBox).last).width,
      TokenfrontSpacing.buttonIconGap,
    );
  });
}
