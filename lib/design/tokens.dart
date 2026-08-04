import 'package:flutter/material.dart';

abstract final class TokenfrontColors {
  static const battlefieldOxide = Color(0xFF10191B);
  static const deepField = Color(0xFF091113);
  static const relayIvory = Color(0xFFF2E9D1);
  static const amethyst = Color(0xFFA276FF);
  static const cobalt = Color(0xFF408CFF);
  static const volt = Color(0xFFE3D33E);
  static const prism = Color(0xFFFF6D94);
  static const panel = Color(0x1FF2E9D1);
  static const panelStrong = Color(0x33F2E9D1);
  static const quietText = Color(0xA6F2E9D1);
  static const danger = Color(0xFFFF8D6D);
}

abstract final class TokenfrontType {
  static const display = TextStyle(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w900,
    letterSpacing: 1.8,
    height: .92,
  );

  static const body = TextStyle(
    fontFamily: 'sans-serif',
    fontWeight: FontWeight.w600,
    letterSpacing: .1,
    height: 1.25,
  );

  static const instrument = TextStyle(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w700,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    letterSpacing: .7,
    height: 1,
  );
}

ThemeData buildTokenfrontTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: TokenfrontColors.amethyst,
    brightness: Brightness.dark,
    surface: TokenfrontColors.battlefieldOxide,
  );
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: TokenfrontColors.battlefieldOxide,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textTheme:
        const TextTheme(
          displayLarge: TokenfrontType.display,
          headlineLarge: TokenfrontType.display,
          titleLarge: TokenfrontType.instrument,
          titleMedium: TokenfrontType.instrument,
          bodyLarge: TokenfrontType.body,
          bodyMedium: TokenfrontType.body,
          labelLarge: TokenfrontType.instrument,
        ).apply(
          bodyColor: TokenfrontColors.relayIvory,
          displayColor: TokenfrontColors.relayIvory,
        ),
    focusColor: TokenfrontColors.relayIvory,
  );
}
