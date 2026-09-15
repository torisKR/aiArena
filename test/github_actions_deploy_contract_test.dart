import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main deploy workflow publishes only the static privacy page', () {
    final workflow = File(
      '.github/workflows/deploy-web.yml',
    ).readAsStringSync();

    for (final contract in <String>[
      'branches: [main]',
      'workflow_dispatch:',
      "if: github.ref == 'refs/heads/main'",
      'contents: read',
      'deployments: write',
      'CLOUDFLARE_API_TOKEN',
      'CLOUDFLARE_ACCOUNT_ID',
      'pages deploy web --project-name=tokenfront-orbital-war --branch=main',
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
        'cloudflare/wrangler-action@ebbaa1584979971c8614a24965b4405ff95890e0',
      ),
    );
    expect(workflow, isNot(contains('flutter build web')));
    expect(File('web/privacy.html').existsSync(), isTrue);
  });
}
