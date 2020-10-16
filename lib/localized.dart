library localized;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A [Localized] extension for [String]
///
extension Localized on String {
  /// An extension function for extracting the value out of JSON file
  /// Requires [context] as a parameter.
  ///
  String localized(BuildContext context) =>
      LocalizationService.of(context).translate(this);
}

/// A [LocalizationService] service
/// Is responsible for extracting json values fro [Localized] strings
/// The folder containing json files is [assets/i18n] which is generated
/// by running the script 'flutter pub run localized:main -l [locale codes]'
///
class LocalizationService {
  /// A [LocalizationsDelegate] delegate
  /// Creates an instance of the localization delegate
  /// Requires [locales] as a parameter to create an instance.
  ///
  static LocalizationsDelegate<LocalizationService> delegate(
          List<Locale> locales) =>
      _LocalizationServiceDelegate(locales);

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

  /// A function for extracting the value out of JSON file
  /// Requires [key] as a parameter get the appropriate value.
  ///
  String translate(String key) => _localizedStrings[key];
}

/// A [_LocalizationServiceDelegate] delegate extending [LocalizationsDelegate]
///
class _LocalizationServiceDelegate
    extends LocalizationsDelegate<LocalizationService> {
  const _LocalizationServiceDelegate(this.locales);

  /// A list of desired localizations.
  ///
  final List<Locale> locales;

  @override
  bool isSupported(Locale locale) =>
      locales.map((e) => e.languageCode).contains(locale.languageCode);

  @override
  Future<LocalizationService> load(Locale locale) async {
    final localizations = LocalizationService(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_LocalizationServiceDelegate old) => false;
}
