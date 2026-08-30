import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main deploy workflow verifies and uploads the Flutter web release', () {
    final workflow = File(
      '.github/workflows/deploy-web.yml',
    ).readAsStringSync();

    for (final contract in <String>[
      'branches: [main]',
      'workflow_dispatch:',
      "if: github.ref == 'refs/heads/main'",
      'contents: read',
      'deployments: write',
      'flutter-version: 3.44.6',
      'flutter analyze --fatal-infos',
      'flutter test --reporter compact',
      'flutter build web --release',
      'CLOUDFLARE_API_TOKEN',
      'CLOUDFLARE_ACCOUNT_ID',
      'pages deploy build/web --project-name=tokenfront-orbital-war --branch=main',
    ]) {
      expect(workflow, contains(contract));
    }
    expect(workflow, isNot(contains('pull_request_target')));
    expect(
      workflow,
      contains('actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd'),
    );
    expect(
      workflow,
      contains(
        'subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2',
      ),
    );
    expect(
      workflow,
      contains(
        'cloudflare/wrangler-action@ebbaa1584979971c8614a24965b4405ff95890e0',
      ),
    );
  });
}
