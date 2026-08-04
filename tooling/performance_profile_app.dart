// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/game/tokenfront_game.dart';
import 'package:tokenfront/l10n/l10n.dart';
import 'package:tokenfront/ui/battle_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final game = TokenfrontGame(
    playerFaction: Faction.claude,
    audioEnabled: false,
    hapticsEnabled: false,
    onMatchEnded: (_, _) {},
  );
  runApp(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BattleScreen(game: game),
    ),
  );
  _runProfile(game);
}

Future<void> _runProfile(TokenfrontGame game) async {
  await game.loaded;

  // Keep all 4,000 units inside one camera-sized region. Faction bands touch so
  // this exercises dense rendering, spatial queries, movement, and combat.
  for (var index = 0; index < game.simulation.units.length; index++) {
    final unit = game.simulation.units[index];
    unit.position = Vec2(600 + (index % 100) * 10, 450 + (index ~/ 100) * 10);
    unit.velocity = Vec2.zero;
  }

  // Exclude installation, shader warmup, and asset loading from the sample.
  await Future<void>.delayed(const Duration(seconds: 3));
  game.debugResetPerformanceMetrics();
  await Future<void>.delayed(const Duration(seconds: 30));

  final report = <String, Object>{
    'unitsAllocated': game.simulation.units.length,
    'unitsAlive': game.simulation.units.where((unit) => unit.alive).length,
    'samples': game.debugFpsSampleCount,
    'averageFps': double.parse(game.averageFps.toStringAsFixed(2)),
    'onePercentLowFps': game.onePercentLowFps,
    'simulationTicks': game.simulation.simulationTickCount,
    'renderedUnits': game.debugRenderedUnitCount,
    'culledUnits': game.debugCulledUnitCount,
  };
  // One machine-readable line makes the result easy to retain from device logs.
  debugPrint('TOKENFRONT_PERFORMANCE ${jsonEncode(report)}');
}
