import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart' show ArgParser;
import 'package:translator/translator.dart';

void main(List<String> args) {
  final parser = ArgParser(allowTrailingOptions: true);
  parser.addFlag('create',
      abbr: 'c',
      help: 'Create sample localization files',
      defaultsTo: false,
      negatable: false);
  parser.addFlag('translate',
      abbr: 't',
      help: 'Translate localization files',
      defaultsTo: false,
      negatable: false);
  parser.addMultiOption('languageCodes', abbr: 'l', help: 'Language codes');
  parser.addOption('dirPath',
      abbr: 'd', defaultsTo: 'assets/i18n', help: 'i18n files directory');
  final createFiles = parser.parse(args)['create'];
  final translateFiles = parser.parse(args)['translate'];
  if ((createFiles && translateFiles) || (!createFiles && !translateFiles)) {
    stdout.writeln('${parser.usage}');
    stdout.writeln(
        'You have to choose between -create and -translate. Exiting...');
    exit(0);
  }
  final langCodes = parser.parse(args)['languageCodes'];
  final dirPath = parser.parse(args)['dirPath'];
  langCodes.sort((a, b) => a == 'en'
      ? -1
      : b == 'en'
          ? 1
          : 0);
  if (createFiles) {
    _createLocalizedFiles(langCodes, dirPath);
  }
  print(langCodes);
  if (translateFiles) {
    _translateLocalizedFiles(langCodes, dirPath);
  }
}

void _translateLocalizedFiles(List<String> langCodes, String dirPath) async {
  if (langCodes.length < 2) {
    stdout.writeln(
        'For translation you have to provide at least two langCodes. Exiting...');
    exit(0);
  }
  final directory = Directory(dirPath);
  if (!directory.existsSync()) {
    stdout.writeln('No directory found. Exiting...');
    exit(0);
  }
  final files = directory.listSync();
  if (files.isEmpty) {
    stdout.writeln('No localization files found. Exiting...');
    exit(0);
  }
  final oldLangStrMap = Map<String, Map<String, String>>();
  final newLangStrMap = Map<String, Map<String, String>>();
  for (final lang in langCodes) {
    if (!_isSupported(lang)) {
      stdout.writeln('Language code $lang is not supported.');
      continue;
    }
    oldLangStrMap[lang] = await _loadStrings(lang, dirPath);
  }
  final gtr = GoogleTranslator();
  bool updated = false;
  await Future.forEach(oldLangStrMap.entries, (oldLangStrOuterMap) async {
    final sourceLang = oldLangStrOuterMap.key;
    final sourceLangMap = oldLangStrOuterMap.value;
    await Future.forEach(sourceLangMap.entries, (sourceLangMapEntry) async {
      final sourceKey = sourceLangMapEntry.key;
      final sourceString = sourceLangMapEntry.value;
      await Future.forEach(oldLangStrMap.entries, (oldLangStrInnerMap) async {
        final targetLang = oldLangStrInnerMap.key;
        final targetLangMap = oldLangStrInnerMap.value;
        if (sourceLang != targetLang) {
          if (sourceLangMap[sourceKey].isNotEmpty &&
              !targetLangMap.containsKey(sourceKey)) {
            if (!newLangStrMap.containsKey(targetLang)) {
              newLangStrMap[targetLang] = Map();
            }
            updated = true;
            newLangStrMap[targetLang][sourceKey] = (await gtr
                    .translate(sourceString, from: sourceLang, to: targetLang))
                .text;
          }
        }
      });
    });
  });
  if (!updated) {
    stdout.writeln('No strings were translated. Exiting...');
    exit(0);
  }
  oldLangStrMap.forEach((lang, langMap) {
    if (newLangStrMap.containsKey(lang)) {
      oldLangStrMap[lang].addAll(newLangStrMap[lang]);
    }
  });
  _updateContent(oldLangStrMap, dirPath);
}

Future<Map<String, String>> _loadStrings(String lang, String dirPath) async {
  var localizedStrings = Map<String, String>();
  final file = File('$dirPath/$lang.json');
  if (!await file.exists()) {
    return localizedStrings;
  }
  final jsonString = await file.readAsString();
  if (jsonString.isEmpty) {
    return localizedStrings;
  }
  final Map<String, dynamic> jsonMap = json.decode(jsonString);
  localizedStrings = jsonMap.map((key, value) {
    return MapEntry(key, value.toString());
  });
  return localizedStrings;
}

void _updateContent(Map<String, Map<String, String>> langStrMap, dirPath) {
  Future.forEach(langStrMap.entries, (langStrMapEntry) async {
    final jsonStr = json.encode(langStrMapEntry.value);
    await File('$dirPath/${langStrMapEntry.key}.json')
        .create(recursive: true)
        .then((file) {
      stdout.writeln('Rewriting file: ${file.path}');
      file.writeAsString(jsonStr);
    });
  });
}

bool _isSupported(String locale) => kSupportedLanguages.contains(locale);

void _createLocalizedFiles(List<String> langCodes, String dirPath) {
  if (langCodes.isEmpty) {
    stdout.writeln(
        'To create files you need to provide at least one language code. Exiting...');
    exit(0);
  }
  final directory = Directory(dirPath);
  if (!directory.existsSync()) {
    _createContent(directory, langCodes, dirPath);
  } else {
    _rewrite(directory, langCodes, dirPath);
  }
}

void _rewrite(Directory directory, List<String> langCodes, String dirPath) {
  stdout.writeln(
      'The assets with i18n exist. Do you want to override it? [Y/N]:');
  final line =
      stdin.readLineSync(encoding: Encoding.getByName('utf-8')).toLowerCase();
  switch (line) {
    case 'y':
      _createContent(directory, langCodes, dirPath);
      break;
    case 'n':
      exit(0);
      break;
    default:
      _rewrite(directory, langCodes, dirPath);
      break;
  }
}

void _createContent(
    Directory directory, List<String> langCodes, String dirPath) {
  directory.create(recursive: true).then((directory) {
    for (final lang in langCodes) {
      if (!_isSupported(lang)) {
        stdout.writeln('Language code $lang is not supported.');
        continue;
      }
      final file = File('$dirPath/$lang.json');
      stdout.writeln('Creating file: ${file.path}');
      file.create(recursive: true).then((file) => file.writeAsString(
          '{\n  "title": "value",\n  "amount_of_clicks": "value",\n  "increase": "value"\n}'));
    }
  });
}

final Set<String> kSupportedLanguages = HashSet<String>.from(const <String>[
  'af', // Afrikaans
  'am', // Amharic
  'ar', // Arabic
  'as', // Assamese
  'az', // Azerbaijani
  'be', // Belarusian
  'bg', // Bulgarian
  'bn', // Bengali Bangla
  'bs', // Bosnian
  'ca', // Catalan Valencian
  'cs', // Czech
  'da', // Danish
  'de', // German
  'el', // Modern Greek
  'en', // English
  'es', // Spanish Castilian
  'et', // Estonian
  'eu', // Basque
  'fa', // Persian
  'fi', // Finnish
  'fil', // Filipino Pilipino
  'fr', // French
  'gl', // Galician
  'gsw', // Swiss German Alemannic Alsatian
  'gu', // Gujarati
  'he', // Hebrew
  'hi', // Hindi
  'hr', // Croatian
  'hu', // Hungarian
  'hy', // Armenian
  'id', // Indonesian
  'is', // Icelandic
  'it', // Italian
  'ja', // Japanese
  'ka', // Georgian
  'kk', // Kazakh
  'km', // Khmer Central Khmer
  'kn', // Kannada
  'ko', // Korean
  'ky', // Kirghiz Kyrgyz
  'lo', // Lao
  'lt', // Lithuanian
  'lv', // Latvian
  'mk', // Macedonian
  'ml', // Malayalam
  'mn', // Mongolian
  'mr', // Marathi
  'ms', // Malay
  'my', // Burmese
  'nb', // Norwegian Bokmål
  'ne', // Nepali
  'nl', // Dutch Flemish
  'no', // Norwegian
  'or', // Oriya
  'pa', // Panjabi Punjabi
  'pl', // Polish
  'ps', // Pushto Pashto
  'pt', // Portuguese
  'ro', // Romanian Moldavian Moldovan
  'ru', // Russian
  'si', // Sinhala Sinhalese
  'sk', // Slovak
  'sl', // Slovenian
  'sq', // Albanian
  'sr', // Serbian
  'sv', // Swedish
  'sw', // Swahili
  'ta', // Tamil
  'te', // Telugu
  'th', // Thai
  'tl', // Tagalog
  'tr', // Turkish
  'uk', // Ukrainian
  'ur', // Urdu
  'uz', // Uzbek
  'vi', // Vietnamese
  'zh', // Chinese
  'zu', // Zulu
]);
