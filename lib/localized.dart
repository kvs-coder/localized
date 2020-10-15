library localized;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

final List<String> localizationCodes = [];

extension Localized on String {
  String localized(BuildContext context) =>
      LocalizationService.of(context).translate(this);
}

class LocalizationService {
  static const LocalizationsDelegate<LocalizationService> delegate =
      _LocalizationServiceDelegate();
  static LocalizationService of(BuildContext context) =>
      Localizations.of<LocalizationService>(context, LocalizationService);

  final Locale locale;

  LocalizationService(this.locale);

  Map<String, String> _localizedStrings;

  Future<bool> load() async {
    final jsonString =
        await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
    return true;
  }

  String translate(String key) => _localizedStrings[key];
}

class _LocalizationServiceDelegate
    extends LocalizationsDelegate<LocalizationService> {
  const _LocalizationServiceDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'de', 'ru'].contains(locale.languageCode);
  }

  @override
  Future<LocalizationService> load(Locale locale) async {
    final localizations = LocalizationService(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_LocalizationServiceDelegate old) => false;
}
