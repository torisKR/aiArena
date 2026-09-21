import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deletion page provides truthful draft route and public contact', () {
    final page = File('web/delete-account.html').readAsStringSync();
    expect(page, contains('mailto:korea@toris.kr'));
    expect(page, contains('not yet deployed'));
    expect(page, contains('Delete billing account'));
    expect(page, contains('not guaranteed'));
    expect(page, contains('Google Play'));
    expect(page, contains('backups'));
    expect(page, isNot(contains('<form')));
    expect(page, isNot(contains('accounts.google.com/o/oauth2')));
  });
}
