import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart' show ArgParser;
import 'package:http/http.dart' as http;
import 'package:localized/constants.dart';
import 'package:translator/translator.dart';
import 'package:tuple/tuple.dart';

/// Supported translation providers
/// GoogleTest should be on the first place
///
const _providerList = [
  'GoogleTest',
  'Google',
  'Yandex',
  'Microsoft',
];
final Map<String, Function> _providerTranslateFunctionMap = {
  _providerList[0]: _translateGoogleTest,
  _providerList[1]: _translateGoogle,
  _providerList[2]: _translateYandex,
  _providerList[3]: _translateMicrosoft,
};
final Map<String, String> _providerDescriptionMap = {
  _providerList[0]: 'Google API through a back door',
  _providerList[1]: 'Google using API key',
  _providerList[2]: 'Yandex using folder ID and IAM token',
  _providerList[3]: 'Microsoft using endpoint, region, and key',
};

/// Main entry point for every [flutter pub run localized:main] script
/// Creates examples of localized files as well as localized strings
/// and translates them using different providers.
///
/// Translation supports Yandex, Google and Microsoft Translation API.
///
/// Based on provided [args] chooses between creation and translation.
/// Uses [ArgParser] to parse arguments.
///
/// Please choose only between creation [-c] and translation [-t].
/// Do not use both parameters in one call.
///
/// First step:
/// JSON files creation
/// Example of creation script:
/// {
///  "default_dir": {
///     "script": "flutter pub run localized:main -c -l en,de,ru"
///  },
///   "default_custom_dir": {
///     "script": "flutter pub run localized:main -c -l en,de,ru -d res/localizations"
///  }
/// }
///
/// Second step:
/// Existing strings in existing JSON file translation
/// Examples of translation scripts:
/// {
///  "google": {
///    "script": "flutter pub run localized:main -t -l ru,en,de -p Google -k YOUR_GOOGLE_KEY -n 25"
///  },
///  "yandex": {
///    "script": "flutter pub run localized:main -t -l ru,en,de -p Yandex -f YOUR_YANDEX_FOLDER -n 100 -i YOUR_YANDEX_KEY"
///  },
///  "microsoft": {
///    "script": "flutter pub run localized:main -t -l ru,en,de -p Microsoft -m YOUR_MICROSOFT_KEY -r YOUR_ZONE -n 100"
///  }
/// }
///
/// See [README.md] and usage for details
///
Future<void> main(List<String> args) async {
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
  parser.addOption('provider',
      abbr: 'p',
      defaultsTo: 'GoogleTest',
      allowed: _providerList,
      allowedHelp: _providerDescriptionMap,
      help: 'Provider of translation API');
  parser.addOption('number',
      abbr: 'n',
      defaultsTo: '1',
      help: 'The number of strings to translate in one request');

  /// Google special parameters
  ///
  parser.addOption('google_key', abbr: 'k', help: 'Google Project API key');

  /// Yandex special parameters
  ///
  parser.addOption('folder_id', abbr: 'f', help: 'Yandex Folder ID');
  parser.addOption('token', abbr: 'i', help: 'Yandex IAM token');

  /// Microsoft special parameters
  ///
  parser.addOption('ms_key', abbr: 'm', help: 'Microsoft key');
  parser.addOption('endpoint',
      abbr: 'e',
      help: 'Microsoft endpoint',
      defaultsTo: 'https://api.cognitive.microsofttranslator.com/');
  parser.addOption('region',
      abbr: 'r',
      help:
          'Microsoft multi-service or regional translator resource. It is optional when using a global translator resource',
      defaultsTo: 'global');

  /// Check the command: create an example or translate the strings
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
  final options = <String, String>{};
  if (parser.parse(args)['provider'] != null) {
    options['provider'] = parser.parse(args)['provider'];
  }
  if (parser.parse(args)['google_key'] != null) {
    options['google_key'] = parser.parse(args)['google_key'];
  }
  if (parser.parse(args)['number'] != null) {
    options['number'] = parser.parse(args)['number'];
  }
  if (parser.parse(args)['folder_id'] != null) {
    options['folder_id'] = parser.parse(args)['folder_id'];
  }
  if (parser.parse(args)['token'] != null) {
    options['token'] = parser.parse(args)['token'];
  }
  if (parser.parse(args)['ms_key'] != null) {
    options['ms_key'] = parser.parse(args)['ms_key'];
  }
  if (parser.parse(args)['endpoint'] != null) {
    options['endpoint'] = parser.parse(args)['endpoint'];
  }
  if (parser.parse(args)['region'] != null) {
    options['region'] = parser.parse(args)['region'];
  }

  /// translation from English is better
  ///
  langCodes.sort((a, b) => a == 'en'
      ? -1
      : b == 'en'
          ? 1
          : 0);

  /// creating examples or translating strings
  ///
  if (createFiles) {
    await _createLocalizedFiles(langCodes, dirPath);
  }
  if (translateFiles) {
    await _translateLocalizedFiles(langCodes, dirPath, options);
  }
}

/// Main function to translate.
/// Requires provider (Yandex, Google...) [options] to handle appropriately.
/// Will update the existing JSON files with updated translated strings
/// if there are empty keys.
///
Future<void> _translateLocalizedFiles(
    List<String> langCodes, String dirPath, Map<String, String> options) async {
  final provider = options['provider'];
  if (provider == null || !_providerList.contains(provider)) {
    stdout.writeln('No valid translation provider set. Exiting...');
    exit(0);
  }
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

  /// loading keys and strings to langStringMap for each language
  ///
  final langStringMap = <String, Map<String, String>>{};
  for (final lang in langCodes) {
    if (!_isSupported(lang)) {
      stdout.writeln('Language code $lang is not supported.');
      continue;
    }
    langStringMap[lang] = _loadStrings(lang, dirPath);
  }

  /// looking for and collecting strings that exist for one language, but don't for another
  /// we need such a strange structure to translate a bunch of strings at once,
  /// because this is much quicker
  /// Map of <targetLang, sourceLang> to List<key>>
  ///
  final toTranslateMap = <Tuple2<String, String>, List<String>>{};
  langStringMap.forEach((sourceLang, sourceStringMap) {
    sourceStringMap.forEach((sourceKey, sourceString) {
      langStringMap.forEach((targetLang, targetStringMap) {
        if (sourceLang != targetLang) {
          if (sourceStringMap[sourceKey].isNotEmpty &&
              (!targetStringMap.containsKey(sourceKey) ||
                  targetStringMap[sourceKey].isEmpty)) {
            final tuple = Tuple2(targetLang, sourceLang);
            if (toTranslateMap[tuple] == null) {
              toTranslateMap[tuple] = [];
            }
            toTranslateMap[tuple].add(sourceKey);
          }
        }
      });
    });
  });
  if (toTranslateMap.isEmpty) {
    stdout.writeln('No strings need to be translated. Exiting...');
    exit(0);
  }

  /// different functions and arguments for different providers
  ///
  provider.compareTo(_providerList[0]) == 0
      ? await _providerTranslateFunctionMap[provider](langStringMap, toTranslateMap)
      : await _batchTranslate(langStringMap, toTranslateMap, options);
  _updateContent(langStringMap, dirPath);
}

/// see https://github.com/gabrielpacheco23, thanks to Gabriel Pacheco
///
Future<void> _translateGoogleTest(Map<String, Map<String, String>> langStringMap,
    Map<Tuple2<String, String>, List<String>> toTranslateMap) async {
  final gtr = GoogleTranslator();
  await Future.forEach(toTranslateMap.entries, (toTranslate) async {
    final targetLang = toTranslate.key.item1;
    final sourceLang = toTranslate.key.item2;
    final keyList = toTranslate.value;
    await Future.forEach(keyList, (key) async {
      final sourceString = langStringMap[sourceLang][key];
      final translated =
          await gtr.translate(sourceString, from: sourceLang, to: targetLang);
      langStringMap[targetLang][key] = translated.text;
    });
  });
}

/// [langStringMap] is a map of a language to <key, string>
/// [toTranslateMap] is a map of <targetLang, sourceLang> to List<key>> - strings to translate
///
Future<void> _batchTranslate(
    Map<String, Map<String, String>> langStringMap,
    Map<Tuple2<String, String>, List<String>> toTranslateMap,
    Map<String, String> options) async {
  final numStringsAtOnce = int.parse(options['number']);
  final provider = options['provider'];
  await Future.forEach(toTranslateMap.entries, (toTranslate) async {
    final targetLang = toTranslate.key.item1;
    final sourceLang = toTranslate.key.item2;
    final keyList = toTranslate.value;
    final stringInOutList = <String>[];
    var num = 0;
    for (var key in keyList) {
      if (langStringMap[targetLang][key] != null &&
          langStringMap[targetLang][key].isNotEmpty) {
        continue;
      }
      stringInOutList.add(langStringMap[sourceLang][key]);
      ++num;
      if (num > 0 && num % numStringsAtOnce == 0) {
        await _providerTranslateFunctionMap[provider](
            stringInOutList, sourceLang, targetLang, options);
        for (var index = 0; index < stringInOutList.length; index++) {
          langStringMap[targetLang]
                  [keyList[num - stringInOutList.length + index]] =
              stringInOutList[index];
        }
        stringInOutList.clear();
      }
    }
    if (stringInOutList.isNotEmpty) {
      await _providerTranslateFunctionMap[provider](
          stringInOutList, sourceLang, targetLang, options);
      for (var index = 0; index < stringInOutList.length; index++) {
        langStringMap[targetLang]
                [keyList[num - stringInOutList.length + index]] =
            stringInOutList[index];
      }
    }
  });
}

/// Google Translate
/// https://cloud.google.com/translate/docs/quickstarts
/// [langStringMap] is a map of a language to <key, string>
/// [toTranslateMap] is a map of <targetLang, sourceLang> to List<key>> - strings to translate
///
Future<void> _translateGoogle(List<String> stringInOutList, String sourceLang,
    String targetLang, Map<String, String> options) async {
  final googleProjectKey = options['google_key'];
  if (googleProjectKey == null) {
    stdout.writeln('No Google project key provided. Exiting...');
    exit(0);
  }
  const baseUrl = 'translation.googleapis.com';
  const path = 'language/translate/v2';
  // It's impossible to add several equal query parameters using the 'parameters' map
  var query =
      'format=text&target=$targetLang&source=$sourceLang&key=$googleProjectKey';
  stringInOutList.forEach((text) => query += '&q=$text');
  try {
    final url = Uri.https(baseUrl, path).replace(query: query);
    final data = await http.get(url);
    if (data.statusCode != 200) {
      throw http.ClientException('Error ${data.statusCode}: ${data.body}', url);
    }
    stringInOutList.clear();
    final mapList = jsonDecode(data.body)['data']['translations'];
    mapList.forEach((map) {
      stringInOutList.add(map['translatedText']);
    });
  } catch (e) {
    stdout.writeln(
        'Cannot translate some strings from $sourceLang to $targetLang. An exception occurs:\n$e');
    stringInOutList.clear();
  }
}

/// Yandex Translate
/// https://yandex.com/dev/translate/doc/dg/concepts/about.html/
/// [langStringMap] is a map of a language to <key, string>
/// [toTranslateMap] is a map of <targetLang, sourceLang> to List<key>> - strings to translate
///
Future<void> _translateYandex(List<String> stringInOutList, String sourceLang,
    String targetLang, Map<String, String> options) async {
  final yandexFolderID = options['folder_id'];
  final yandexIAMToken = options['token'];
  if (yandexFolderID == null || yandexIAMToken == null) {
    stdout.writeln('No Yandex Folder ID or IAM token provided. Exiting...');
    exit(0);
  }
  const url = 'https://translate.api.cloud.yandex.net/translate/v2/translate';
  final headers = {
    'Content-type': 'application/json',
    'Authorization': 'Bearer ' + yandexIAMToken,
  };
  try {
    final body = json.encode({
      'sourceLanguageCode': sourceLang,
      'format': 'PLAIN_TEXT',
      'folder_id': yandexFolderID,
      'texts': stringInOutList,
      'targetLanguageCode': targetLang
    });
    final data = await http.post(url, body: body, headers: headers);
    if (data.statusCode != 200) {
      throw http.ClientException('Error ${data.statusCode}: ${data.body}');
    }
    stringInOutList.clear();

    /// Yandex doesn't set encoding, so decode data we have to update the header manually
    ///
    data.headers['content-type'] = 'application/json; charset=UTF-8';
    final mapList = jsonDecode(data.body)['translations'];
    mapList.forEach((map) => stringInOutList.add(map['text']));
  } catch (e) {
    stdout.writeln(
        'Cannot translate some strings from $sourceLang to $targetLang. An exception occurs:\n$e');
    stringInOutList.clear();
  }
}

/// Microsoft Translate
/// https://docs.microsoft.com/en-us/azure/cognitive-services/translator/
/// [langStringMap] is a map of a language to <key, string>
/// [toTranslateMap] is a map of <targetLang, sourceLang> to List<key>> - strings to translate
///
Future<void> _translateMicrosoft(List<String> stringInOutList, String sourceLang,
    String targetLang, Map<String, String> options) async {
  final msEndpoint = options['endpoint'];
  final msKey = options['ms_key'];
  final msRegion = options['region'];
  if (msEndpoint == null || msKey == null) {
    stdout.writeln('No Microsoft endpoint or key provided. Exiting...');
    exit(0);
  }
  final url = msEndpoint +
      '/translate?api-version=3.0&from=' +
      sourceLang +
      '&to=' +
      targetLang;
  final headers = {
    'Ocp-Apim-Subscription-Key': msKey,
    'Content-type': 'application/json',
    'Ocp-Apim-Subscription-Region': msRegion,
  };
  try {
    var bodyMap = <Map>[];
    stringInOutList.forEach((str) => bodyMap.add({'text': str}));
    final body = json.encode(bodyMap);
    final data = await http.post(url, body: body, headers: headers);
    if (data.statusCode != 200) {
      throw http.ClientException('Error ${data.statusCode}: ${data.body}');
    }
    stringInOutList.clear();
    final mapList = jsonDecode(data.body);
    mapList
        .forEach((map) => stringInOutList.add(map['translations'][0]['text']));
  } catch (e) {
    stdout.writeln(
        'Cannot translate some strings from $sourceLang to $targetLang. An exception occurs:\n$e');
    stringInOutList.clear();
  }
}

/// Loading of strings from language files
///
Map<String, String> _loadStrings(String lang, String dirPath) {
  var localizedStrings = <String, String>{};
  try {
    final file = File('$dirPath/$lang.json');
    if (!file.existsSync()) {
      return localizedStrings;
    }
    final jsonString = file.readAsStringSync();
    if (jsonString.isEmpty) {
      return localizedStrings;
    }
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
  } catch (e) {
    stdout.writeln(
        'Cannot load strings from $dirPath/$lang.json file. An exception occurs:\n$e.');
  }
  return localizedStrings;
}

/// Writing translated files with updated strings from [langStrMap]
///
Future<void> _updateContent(
    Map<String, Map<String, String>> langStrMap, dirPath) async {
  await Future.forEach(langStrMap.entries, (langStrMapEntry) async {
    try {
      final fileName = '$dirPath/${langStrMapEntry.key}.json';
      final file = await File(fileName).create(recursive: true);
      stdout.writeln('Rewriting file: ${file.path}');
      final writtenFiled =
          await file.writeAsString(json.encode(langStrMapEntry.value));
      stdout.writeln('File rewriting finished: ${writtenFiled.path}');
    } catch (e) {
      stdout.writeln(
          'Cannot update $dirPath/${langStrMapEntry.key}.json file. An exception occurs:\n$e.');
    }
  });
}

/// Checks for supporting selected [locale]
///
bool _isSupported(String locale) => kSupportedLanguages.contains(locale);

/// Creates localized files based on existence of the directory
/// in path [dirPath]
/// Also check for [langCodes]. Will exit with code [0] if no
/// lang codes were found.
///
void _createLocalizedFiles(List<String> langCodes, String dirPath) {
  if (langCodes.isEmpty) {
    stdout.writeln(
        'To create files you need to provide at least one language code. Exiting...');
    exit(0);
  }
  final directory = Directory(dirPath);
  !directory.existsSync()
      ? _createContent(directory, langCodes, dirPath)
      : _rewrite(directory, langCodes, dirPath);
}

/// The command awaits for the user input [Y/N]
/// If "Y" is typed the whole localization folder will be rewritten
/// If "N" is typed the function exits with [0] code.
/// If another character is typed, the function will call
/// itself recursively and will await for a valid input.
///
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

/// For every element in [langCodes] creates a [directory] with JSON files
/// in provided directory path [dirPath] and populates them
/// with dummy data
///
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
