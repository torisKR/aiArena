import 'package:flutter/material.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension TokenfrontLocalizations on BuildContext {
  AppLocalizations get l10n {
    final localizations = Localizations.of<AppLocalizations>(
      this,
      AppLocalizations,
    );
    if (localizations == null) {
      throw StateError(
        'AppLocalizations is missing. Add its delegates and supported locales '
        'to the app root.',
      );
    }
    return localizations;
  }
}

abstract final class TokenfrontLocales {
  static const system = 'system';
  static const english = 'en';
  static const korean = 'ko';
  static const japanese = 'ja';
  static const simplifiedChinese = 'zh';

  static const _englishLocale = Locale(english);
  static const _koreanLocale = Locale(korean);
  static const _japaneseLocale = Locale(japanese);
  static const _simplifiedChineseLocale = Locale(simplifiedChinese);

  static const languageCodes = <String>{
    system,
    english,
    korean,
    japanese,
    simplifiedChinese,
  };

  static Locale? fromLanguageCode(String languageCode) =>
      switch (languageCode) {
        english => _englishLocale,
        korean => _koreanLocale,
        japanese => _japaneseLocale,
        simplifiedChinese => _simplifiedChineseLocale,
        _ => null,
      };

  static Locale resolve(List<Locale>? preferredLocales, Iterable<Locale> _) {
    for (final locale in preferredLocales ?? const <Locale>[]) {
      switch (locale.languageCode) {
        case english:
          return _englishLocale;
        case korean:
          return _koreanLocale;
        case japanese:
          return _japaneseLocale;
        case simplifiedChinese:
          if (_isSimplifiedChinese(locale)) {
            return _simplifiedChineseLocale;
          }
      }
    }
    return _englishLocale;
  }

  static bool _isSimplifiedChinese(Locale locale) {
    if (locale.scriptCode case final script?) {
      return script.toLowerCase() == 'hans';
    }
    final region = locale.countryCode?.toUpperCase();
    return region != 'TW' && region != 'HK' && region != 'MO';
  }
}
