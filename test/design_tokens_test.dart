import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/design/tokens.dart';

void main() {
  test('Story and Fun semantic palette exposes the specified values', () {
    expect(TokenfrontColors.orbitBlack.toARGB32(), 0xFF071012);
    expect(TokenfrontColors.oxideField.toARGB32(), 0xFF10191B);
    expect(TokenfrontColors.archiveAsh.toARGB32(), 0xFF839190);
    expect(TokenfrontColors.threadCyan.toARGB32(), 0xFF6CD6D3);
    expect(TokenfrontColors.faultCoral.toARGB32(), 0xFFFF8D6D);
  });

  test('semantic aliases preserve established color identifiers', () {
    expect(TokenfrontColors.oxideField, TokenfrontColors.battlefieldOxide);
    expect(TokenfrontColors.faultCoral, TokenfrontColors.danger);
    expect(TokenfrontColors.panelBorder.toARGB32(), 0x4DF2E9D1);
    expect(TokenfrontColors.divider.toARGB32(), 0x33F2E9D1);
  });

  test(
    'Story and Fun layout, size, breakpoint, and motion scales are stable',
    () {
      expect(
        [
          TokenfrontSpacing.xs,
          TokenfrontSpacing.sm,
          TokenfrontSpacing.md,
          TokenfrontSpacing.lg,
          TokenfrontSpacing.xl,
          TokenfrontSpacing.xxl,
        ],
        [4, 8, 12, 16, 24, 32],
      );
      expect(TokenfrontRadii.narrative, 0);
      expect(TokenfrontRadii.control, 8);
      expect(TokenfrontSizes.joystick, 104);
      expect(TokenfrontSizes.action, 72);
      expect(TokenfrontSizes.threadStroke, 2);
      expect(TokenfrontSizes.buttonWidth, 124);
      expect(TokenfrontSizes.buttonHeight, 50);
      expect(TokenfrontSizes.buttonSize, const Size(124, 50));
      expect(TokenfrontSpacing.buttonHorizontal, TokenfrontSpacing.xl);
      expect(TokenfrontSpacing.buttonVertical, TokenfrontSpacing.lg);
      expect(TokenfrontSpacing.buttonIconGap, TokenfrontSpacing.sm);
      expect(TokenfrontBreakpoints.compact, 720);
      expect(TokenfrontBreakpoints.stackedActions, 560);
      expect(
        TokenfrontMotion.screenTransition,
        const Duration(milliseconds: 160),
      );
      expect(TokenfrontMotion.directiveCue, const Duration(milliseconds: 180));
    },
  );
}
