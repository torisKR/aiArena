import 'package:flutter/material.dart';

import '../design/tokens.dart';
import 'simulation.dart';

class FactionVisual {
  const FactionVisual({
    required this.name,
    required this.mark,
    required this.color,
    required this.sides,
  });

  final String name;
  final String mark;
  final Color color;
  final int sides;
}

extension FactionVisuals on Faction {
  FactionVisual get visual => switch (this) {
    Faction.claude => const FactionVisual(
      name: 'AMETHYST',
      mark: '◆',
      color: TokenfrontColors.amethyst,
      sides: 4,
    ),
    Faction.codex => const FactionVisual(
      name: 'COBALT',
      mark: '[ ]',
      color: TokenfrontColors.cobalt,
      sides: 4,
    ),
    Faction.grok => const FactionVisual(
      name: 'VOLT',
      mark: 'ϟ',
      color: TokenfrontColors.volt,
      sides: 3,
    ),
    Faction.gemini => const FactionVisual(
      name: 'PRISM',
      mark: '✣',
      color: TokenfrontColors.prism,
      sides: 6,
    ),
  };
}
