import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/game/tokenfront_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Blender atlas and manifest expose four exact 64-pixel cells', () async {
    final bytes = await rootBundle.load(
      'assets/images/tokenfront_token_atlas.png',
    );
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 256);
    expect(frame.image.height, 64);
    frame.image.dispose();
    codec.dispose();

    final manifest =
        jsonDecode(
              await rootBundle.loadString(
                'assets/images/tokenfront_token_atlas.json',
              ),
            )
            as Map<String, dynamic>;
    expect(manifest['cellSize'], 64);
    final frames = manifest['frames'] as Map<String, dynamic>;
    expect(frames.keys, ['amethyst', 'cobalt', 'volt', 'prism']);
    expect(
      [for (final frame in frames.values) (frame as Map)['x']],
      [0, 64, 128, 192],
    );
  });

  test(
    'game loads and samples the runtime atlas instead of whole-sheet draw',
    () async {
      final game = TokenfrontGame(
        playerFaction: Faction.amethyst,
        audioEnabled: false,
        hapticsEnabled: false,
        onMatchEnded: (_, _) {},
      );
      addTearDown(game.onRemove);

      await game.onLoad();

      expect(game.debugUnitAtlasLoaded, isTrue);
      for (final faction in Faction.values) {
        final source = game.debugUnitAtlasSource(faction);
        expect(source.left, faction.index * 64);
        expect(source.top, 0);
        expect(source.width, 64);
        expect(source.height, 64);
      }
    },
  );
}
