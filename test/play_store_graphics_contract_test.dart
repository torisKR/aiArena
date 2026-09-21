import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> asMap(Object? value, String label) {
  expect(
    value,
    isA<Map<String, dynamic>>(),
    reason: '$label must be an object',
  );
  return value! as Map<String, dynamic>;
}

Future<String> sha256(File file) async {
  final result = await Process.run('shasum', <String>['-a', '256', file.path]);
  expect(
    result.exitCode,
    0,
    reason: 'shasum must hash ${file.path}: ${result.stderr}',
  );
  return (result.stdout as String).trim().split(RegExp(r'\s+')).first;
}

Future<ui.Image> decode(File file) async {
  final codec = await ui.instantiateImageCodec(await file.readAsBytes());
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

Future<void> expectOpaque(ui.Image image, String label) async {
  final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  expect(rgba, isNotNull, reason: '$label must decode to RGBA pixels');
  final pixels = rgba!.buffer.asUint8List();
  for (var offset = 3; offset < pixels.length; offset += 4) {
    expect(pixels[offset], 255, reason: '$label must be fully opaque');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Play graphics contract records verifiable lineage for every file',
    () async {
      final contract = asMap(
        jsonDecode(
          await File(
            'store-assets/android/play-store-graphics-contract.json',
          ).readAsString(),
        ),
        'contract',
      );
      expect(contract['version'], 1);

      final generation = asMap(contract['imageGeneration'], 'imageGeneration');
      final references = <Map<String, dynamic>>[
        asMap(generation['reference'], 'imageGeneration.reference'),
      ];
      final sources = asMap(contract['sources'], 'sources');
      final outputs = asMap(contract['outputs'], 'outputs');
      final records = <Map<String, dynamic>>[
        ...references,
        ...sources.values.map((value) => asMap(value, 'source')),
        ...outputs.values.map((value) => asMap(value, 'output')),
      ];

      for (final record in records) {
        final path = record['path'];
        final expectedHash = record['sha256'];
        expect(path, isA<String>(), reason: 'every record needs a file path');
        expect(
          expectedHash,
          matches(RegExp(r'^[a-f0-9]{64}$')),
          reason: '$path must record a SHA-256',
        );
        final file = File(path as String);
        expect(await file.exists(), isTrue, reason: '$path must exist');
        expect(
          await sha256(file),
          expectedHash,
          reason: '$path changed without an updated provenance contract',
        );
      }
    },
  );

  test(
    'Play icon is a full-square opaque RGBA PNG without source rounding',
    () async {
      final contract =
          jsonDecode(
                await File(
                  'store-assets/android/play-store-graphics-contract.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      final generation = contract['iconGeneration'] as Map<String, dynamic>;
      expect(generation['source'], 'assets/images/logo_image.png');
      expect(generation['sourceDimensions'], <int>[1254, 1254]);
      final icon = File('store-assets/android/ai-war-simulator-icon-512.png');
      expect(
        await icon.readAsBytes(),
        await File('store-assets/android/icon-512.png').readAsBytes(),
      );
      final bytes = await icon.readAsBytes();
      expect(bytes.sublist(0, 8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
      expect(bytes[25], 6, reason: 'icon PNG must use RGBA color type');
      expect(bytes.length, lessThanOrEqualTo(1024 * 1024));
      final image = await decode(icon);
      expect((image.width, image.height), (512, 512));
      await expectOpaque(image, icon.path);
      image.dispose();
    },
  );

  test(
    'Play feature graphic is a bounded opaque 1024 by 500 RGB JPEG',
    () async {
      final feature = File('store-assets/android/feature-graphic-1024x500.jpg');
      final bytes = await feature.readAsBytes();
      expect(bytes.take(2), <int>[0xff, 0xd8]);
      expect(bytes.skip(bytes.length - 2), <int>[0xff, 0xd9]);
      expect(bytes.length, lessThanOrEqualTo(1024 * 1024));
      final image = await decode(feature);
      expect((image.width, image.height), (1024, 500));
      await expectOpaque(image, feature.path);
      image.dispose();
    },
  );
}
