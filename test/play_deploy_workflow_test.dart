import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Play deployment workflow keeps the production release contract', () {
    final workflow = File(
      '.github/workflows/deploy-play.yml',
    ).readAsStringSync();

    for (final contract in <String>[
      'branches: [main]',
      'workflow_dispatch:',
      "if: github.ref == 'refs/heads/main'",
      'permissions:\n  contents: read',
      'cancel-in-progress: false',
      'TOKENFRONT_UPLOAD_KEYSTORE_BASE64',
      'TOKENFRONT_UPLOAD_STORE_PASSWORD',
      'TOKENFRONT_UPLOAD_KEY_ALIAS',
      'TOKENFRONT_UPLOAD_KEY_PASSWORD',
      'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON',
      'actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd',
      'actions/setup-java@0f481fcb613427c0f801b606911222b5b6f3083a',
      'subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2',
      'google-github-actions/auth@7c6bc770dae815cd3e89ee6cdf493a5fab2cc093',
      'r0adkll/upload-google-play@e738b9dd8f2476ea806d921b64aacd24f34515a5',
      'com.toris.tokenfront.tokenfront',
      'access_token_scopes: https://www.googleapis.com/auth/androidpublisher',
      'create_credentials_file: false',
      'export_environment_variables: false',
      r'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/$PACKAGE_NAME/edits',
      r'$api/$edit_id/bundles',
      r"jq -er '[.bundles[]?.versionCode | tonumber] | max // 0'",
      r'version_code="$(date -u +%s)"',
      r'version_code="$((highest + 1))"',
      r'test "$version_code" -gt "$highest"',
      r'test "$version_code" -le 2100000000',
      'track: production',
      'status: completed',
      'changesNotSentForReview: false',
    ]) {
      expect(workflow, contains(contract));
    }

    expect(workflow, isNot(contains('pull_request_target')));
    expect(workflow, isNot(contains('\n  pull_request:')));
  });
}
