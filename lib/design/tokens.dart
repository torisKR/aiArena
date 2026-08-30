import 'package:flutter/material.dart';

abstract final class TokenfrontColors {
  // Story and Fun semantic palette. Keep the established names below as
  // compatibility identifiers while exposing role-oriented aliases for new
  // surfaces.
  static const orbitBlack = Color(0xFF071012);
  static const battlefieldOxide = Color(0xFF10191B);
  static const oxideField = battlefieldOxide;
  static const deepField = Color(0xFF091113);
  static const relayIvory = Color(0xFFF2E9D1);
  static const archiveAsh = Color(0xFF839190);
  static const threadCyan = Color(0xFF6CD6D3);
  static const amethyst = Color(0xFFA276FF);
  static const cobalt = Color(0xFF408CFF);
  static const volt = Color(0xFFE3D33E);
  static const prism = Color(0xFFFF6D94);
  static const panel = Color(0x1FF2E9D1);
  static const panelStrong = Color(0x33F2E9D1);
  static const panelBorder = Color(0x4DF2E9D1);
  static const divider = Color(0x33F2E9D1);
  static const quietText = Color(0xA6F2E9D1);
  static const danger = Color(0xFFFF8D6D);
  static const faultCoral = danger;
}

/// The spacing scale shared by narrative planes and controls.
abstract final class TokenfrontSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  // Numeric aliases keep the scale discoverable for layout code.
  static const double space4 = xs;
  static const double space8 = sm;
  static const double space12 = md;
  static const double space16 = lg;
  static const double space24 = xl;
  static const double space32 = xxl;

  static const double buttonHorizontal = xl;
  static const double buttonVertical = lg;
  static const double buttonIconGap = sm;

  static const double tacticalButtonHorizontal = buttonHorizontal;
  static const double tacticalButtonVertical = buttonVertical;
  static const double tacticalButtonIconGap = buttonIconGap;
}

abstract final class TokenfrontRadii {
  static const double narrative = 0;
  static const double control = 8;
}

abstract final class TokenfrontSizes {
  static const double joystick = 104;
  static const double action = 72;
  static const double threadStroke = 2;
  static const double buttonWidth = 124;
  static const double buttonHeight = 50;
  static const Size buttonSize = Size(buttonWidth, buttonHeight);

  static const double tacticalButtonWidth = buttonWidth;
  static const double tacticalButtonHeight = buttonHeight;
  static const Size tacticalButtonSize = buttonSize;
}

abstract final class TokenfrontBreakpoints {
  static const double compact = 720;
  static const double stackedActions = 560;
}

abstract final class TokenfrontMotion {
  static const screenTransition = Duration(milliseconds: 160);
  static const directiveCue = Duration(milliseconds: 180);
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
