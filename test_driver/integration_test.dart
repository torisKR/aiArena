import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final directory = Directory(
    Platform.environment['PLAY_STORE_CAPTURE_DIR'] ?? '.play-store-captures',
  );
  directory.createSync(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final output = File('${directory.path}/$name.png');
      await output.writeAsBytes(bytes, flush: true);
      return output.lengthSync() > 0;
    },
  );
}
