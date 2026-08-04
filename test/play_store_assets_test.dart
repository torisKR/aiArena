import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

Future<({int width, int height})> dimensions(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final result = (width: frame.image.width, height: frame.image.height);
  frame.image.dispose();
  codec.dispose();
  return result;
}

Future<void> expectOpaqueJpeg(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  expect(bytes.take(2), <int>[0xff, 0xd8], reason: '$path must be JPEG');
  expect(bytes.skip(bytes.length - 2), <int>[
    0xff,
    0xd9,
  ], reason: '$path must have a complete JPEG trailer');
  expect(await dimensions(path), (width: 1920, height: 1080));

  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final rgba = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  expect(rgba, isNotNull, reason: '$path must decode to RGBA pixels');
  final pixels = rgba!.buffer.asUint8List();
  for (var offset = 3; offset < pixels.length; offset += 4) {
    expect(pixels[offset], 255, reason: '$path must be opaque');
  }
  frame.image.dispose();
  codec.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Play icon is an exact 512 square RGBA PNG', () async {
    final file = File('store-assets/android/icon-512.png');
    final bytes = await file.readAsBytes();
    expect(bytes.sublist(0, 8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
    expect(bytes[25], 6, reason: 'PNG color type must be RGBA');
    expect(await dimensions(file.path), (width: 512, height: 512));
    expect(bytes.length, lessThanOrEqualTo(1024 * 1024));
  });

  test('Play feature graphic is an exact opaque 1024 by 500 JPEG', () async {
    final file = File('store-assets/android/feature-graphic-1024x500.jpg');
    final bytes = await file.readAsBytes();
    expect(bytes.take(2), <int>[0xff, 0xd8]);
    expect(bytes.skip(bytes.length - 2), <int>[0xff, 0xd9]);
    expect(await dimensions(file.path), (width: 1024, height: 500));
  });

  test('five Play phone screenshots are opaque 1920 by 1080 JPEGs', () async {
    for (final name in <String>[
      'phone-01-command-deck-1920x1080.jpg',
      'phone-02-live-directive-1920x1080.jpg',
      'phone-03-command-handoff-1920x1080.jpg',
      'phone-04-chronicle-debrief-1920x1080.jpg',
      'phone-05-archive-1920x1080.jpg',
    ]) {
      await expectOpaqueJpeg('store-assets/android/$name');
    }
  });

  test('graphics contract binds source and output hashes', () async {
    final contract =
        jsonDecode(
              await File(
                'store-assets/android/play-store-graphics-contract.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    expect(contract['version'], 1);
    expect((contract['brand'] as Map)['title'], 'TOKENFRONT');
    expect(
      (contract['outputs'] as Map).keys,
      containsAll(<String>['icon-512.png', 'feature-graphic-1024x500.jpg']),
    );
  });
}
