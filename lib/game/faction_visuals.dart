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
    Faction.amethyst => const FactionVisual(
      name: 'AMETHYST',
      mark: '◆',
      color: TokenfrontColors.amethyst,
      sides: 4,
    ),
    Faction.cobalt => const FactionVisual(
      name: 'COBALT',
      mark: '[ ]',
      color: TokenfrontColors.cobalt,
      sides: 4,
    ),
    Faction.volt => const FactionVisual(
      name: 'VOLT',
      mark: 'ϟ',
      color: TokenfrontColors.volt,
      sides: 3,
    ),
    Faction.prism => const FactionVisual(
      name: 'PRISM',
      mark: '✣',
      color: TokenfrontColors.prism,
      sides: 6,
    ),
  };
}
