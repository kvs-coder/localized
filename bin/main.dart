import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart' show ArgParser;
//import 'package:flutter_localizations/flutter_localizations.dart';

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

  if (createFiles) _createLocalizedFiles(langCodes, dirPath);
  if (translateFiles) _translateLocalizedFiles(langCodes, dirPath);
}

Future<void> _translateLocalizedFiles(
    List<String> langCodes, String dirPath) async {
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

  Map<String, Map<String, String>> existingLangStrings = Map();
  Map<String, Map<String, String>> newLangStrings = Map();

  for (final lang in langCodes) {
    if (!_isSupported(lang)) {
      stdout.writeln('Language code $lang is not supported.');
      continue;
    }
    existingLangStrings[lang] = await _loadStrings(lang, dirPath);
  }

  var updated = false;
  existingLangStrings.forEach((sourceLang, sourceLangMap) {
    sourceLangMap.forEach((sourceKey, sourceValue) {
      existingLangStrings.forEach((targetLang, targetLangMap) {
        if (sourceLang != targetLang) {
          if (!targetLangMap.containsKey(sourceKey)) {
            if (!newLangStrings.containsKey(targetLang)) {
              newLangStrings[targetLang] = Map();
            }
            updated = true;
            newLangStrings[targetLang][sourceKey] =
                _translate(sourceValue, sourceLang, targetLang);
          }
        }
      });
    });
  });

  if (!updated) {
    stdout.writeln('No strings were translated. Exiting...');
    exit(0);
  }

  existingLangStrings.forEach((lang, langMap) {
    if (newLangStrings.containsKey(lang)) {
      existingLangStrings[lang].addAll(newLangStrings[lang]);
    }
  });

  _updateContent(existingLangStrings, dirPath);
}

String _translate(String sourceValue, String sourceLang, String targetLang) {
  return sourceValue;
}

Future<Map<String, String>> _loadStrings(String lang, String dirPath) async {
  Map<String, dynamic> jsonMap = await File('$dirPath/$lang.json')
      .readAsString()
      .then((jsonString) => json.decode(jsonString));
  Map<String, String> localizedStrings = Map();
  localizedStrings = jsonMap.map((key, value) {
    return MapEntry(key, value.toString());
  });
  return localizedStrings;
}

void _updateContent(Map<String, Map<String, String>> langMap, dirPath) {
  langMap.forEach((lang, strMap) {
    String jsonStr = json.encode(strMap);
    File('$dirPath/$lang.json').create(recursive: true).then((file) {
      stdout.writeln('Rewriting file: ${file.path}');
      file.writeAsString(jsonStr);
    });
  });
}

bool _isSupported(String locale) =>
    true /*(Platform.isIOS
    ? kCupertinoSupportedLanguages.contains(locale)
    : kMaterialSupportedLanguages.contains(locale))*/
    ;

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
  var line =
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
  directory.create(recursive: true).then((Directory directory) {
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
