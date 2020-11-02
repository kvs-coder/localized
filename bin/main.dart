import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

void main(List<String> args) {
  final parser = ArgParser(allowTrailingOptions: true);
  parser.addMultiOption('localization', abbr: 'l', help: 'Localization codes');
  parser.addOption('dirPath', abbr: 'd', defaultsTo: 'assets/i18n', help:'i18n files directory, \'assets/i18n\' by default');
  final argResults = parser.parse(args)['localization'];
  if( argResults.isEmpty ) {
    stdout.writeln(
      'You need to provide at leat one locale. Exiting...');
    exit(0);
  }
  final dirPath = parser.parse(args)['dirPath'];
  final directory = Directory(dirPath);
  if (!directory.existsSync()) {
    _createContent(directory, argResults, dirPath);
  } else {
    _rewrite(directory, argResults, dirPath);
  }
}

void _rewrite(Directory directory, List<String> argResults, String dirPath) {
  stdout.writeln(
      'The assets with i18n exist. Do you want to override it? [Y/N]:');
  var line =
      stdin.readLineSync(encoding: Encoding.getByName('utf-8')).toLowerCase();
  switch (line) {
    case 'y':
      _createContent(directory, argResults, dirPath);
      break;
    case 'n':
      exit(0);
      break;
    default:
      _rewrite(directory, argResults, dirPath);
      break;
  }
}

void _createContent(
    Directory directory, List<String> argResults, String dirPath) {
  directory.create(recursive: true).then((Directory directory) {
    for (final argument in argResults) {
      final file = File('$dirPath/$argument.json');
      stdout.writeln('Creating file: ${file.path}');
      file.create(recursive: true).then((file) => file.writeAsString(
          '{\n  "title": "value",\n  "amount_of_clicks": "value",\n  "increase": "value"\n}'));
    }
  });
}
