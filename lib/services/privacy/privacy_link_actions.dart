import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

abstract interface class PrivacyLinkActions {
  Future<void> copy(String text);
  Future<bool> openExternal(Uri uri);
}

final class PlatformPrivacyLinkActions implements PrivacyLinkActions {
  const PlatformPrivacyLinkActions();

  @override
  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  @override
  Future<bool> openExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
