import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/ui/launch_splash.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'runtime art uses compact copies without packaging source PNGs',
    () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();
      for (final source in [
        'assets/images/logo_image.png',
        'assets/images/splah_image.png',
        'assets/blender/tokenfront_keyart.png',
      ]) {
        expect(File(source).existsSync(), isTrue);
        expect(assets, isNot(contains(source)));
      }
      expect(LaunchSplash.duration, const Duration(seconds: 2));
      expect(LaunchSplash.asset, 'assets/images/splah_image.webp');
      for (final art in {
        LaunchSplash.asset: [1254, 1254],
        'assets/blender/tokenfront_keyart.webp': [1440, 900],
      }.entries) {
        final bytes = await rootBundle.load(art.key);
        expect(bytes.lengthInBytes, lessThan(500000));
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        expect([frame.image.width, frame.image.height], art.value);
        frame.image.dispose();
        codec.dispose();
      }
      expect(assets, contains('assets/images/tokenfront_token_atlas.png'));
      expect(assets, contains('assets/images/tokenfront_token_atlas.json'));
    },
  );
}
