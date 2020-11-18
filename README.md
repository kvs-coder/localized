# localized

String extensions for localization and a translation utility

## Features
- A script for creating your json localization files (see [Localization](#localization))
- A **String** extension function _localized_
- A translation utility (see [Translation](#translation))

## Getting Started

- Go inside pubspec.yaml file
- Add this to your package's pubspec.yaml file: 
``` Dart
dependencies:
     localized: ^2.0.3
```
- Get dependencies

``` shell
flutter pub get
``` 

## How to use

### Localization
The package generates assets with i18n empty content as JSON files for future localized strings.

First think about the localization you want to use and run the script (as an example EN, DE, RU are provided)
specifying the localizations in a line separated with commas

``` shell
flutter pub run localized:main -c -l en,de,ru
``` 

(see list of [Parameters](#parameters))

As a result this will be added to the project tree:

``` shell
- assets
    - i18n
        - de.json
        - en.json
        - ru.json
``` 

In addition, you can specify the directory where the files
will be created

``` shell
flutter pub run localized:main -c -l en,de,ru -d res/localizations
``` 

(see list of [Parameters](#parameters))

For now the result this will:

``` shell
- res
    - localizations
        - de.json
        - en.json
        - ru.json
``` 

Next step is to add these assets in a <b>pubspec.yaml</b> file

``` Dart
flutter:
  assets:
    - assets/i18n/
```

Or your custom:

``` Dart
flutter:
  assets:
    - res/localizations/
```

Next is to do some coding

- Import the library 
``` Dart
import 'package:localized/localized.dart';
```
- Create a set of Locales
``` Dart
  final locales = [
    Locale('de', 'DE'),
    Locale('en', 'EN'),
    Locale('ru', 'RU'),
  ];
```
- In your <i>MateralApp</i> widget set the created <i>supportedLocales</i> with the created set
``` Dart
    supportedLocales: locales,
```
- In your <i>MateralApp</i> widget set the list of <i>localizationsDelegates</i> 
``` Dart
    localizationsDelegates: [
      LocalizationService.delegate(locales),
    ],
```

Result:

``` Dart
class MyApp extends StatelessWidget {
  final locales = [
    // TODO: add new lang in array
    Locale('de', 'DE'),
    Locale('en', 'EN'),
    Locale('ru', 'RU'),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      supportedLocales: locales,
      localizationsDelegates: [
        LocalizationService.delegate(locales: locales),
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}
```

The settings finished, next is to try to localise strings.
``` Dart
    appBar: AppBar(
      title: Text('title'.localized(context)), // Home page (en), Startseite (de), Домашняя страница (ru)
    ),
```

Depending on the localization currently installed on the phone or the simulator, the appropriate value for the string will be called.
For instance if the current localization is en-EN, then <b>en.json</b> file will be used.

Here is the full example

``` Dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:localized/localized.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final locales = [
    // TODO: add new lang in array
    Locale('de', 'DE'),
    Locale('en', 'EN'),
    Locale('ru', 'RU'),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      supportedLocales: locales,
      localizationsDelegates: [
        LocalizationService.delegate(locales: locales),
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('title'.localized(context)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'amount_of_clicks'.localized(context),
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'increase'.localized(context),
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
```

### Translation

This library supports translation of every string in your localized json files.
The APIs:
- Google Cloud Translator
- Yandex Translator
- Microsoft Translator

When you have created your json files, you may want to translate all your strings to desired languages.

The translation utility will check for existing keys in json files and if there is no translation for that key
the utility will handle this.

For Google:

``` shell
flutter pub run localized:main -t -l ru,en,de -p Google -k YOUR_GOOGLE_API_KEY -n MAXIMUM_BUFFER_NUMBER 
```

For Yandex:

``` shell
flutter pub run localized:main -t -l ru,en,de -p Yandex -f YOUR_YANDEX_FOLDER_ID -n MAXIMUM_BUFFER_NUMBER -i YOUR_YANDEX_IAM_TOKEN
```

For Microsoft:

``` shell
flutter pub run localized:main -t -l ru,en,de -p Microsoft -m YOUR_MICROSOFT_KEY -r YOUR_REGION -n 100
```

(see list of [Parameters](#parameters))

Please pay attention to MAXIMUM_BUFFER_NUMBER parameter. This parameter shows how many strings are allowed to be translated in one request.
By default, the parameter value is set to 1 and generally it will take much longer time for the translation.

The known limits are:
- Google: 25 strings limit
- Yandex: 100 string limit
- Microsoft: 100 string limit

#### Parameters

General:

- **-c** Create sample localization files
- **-t** Translate localization files
- **-l** Language codes
- **-d** i18n files directory. ("assets/i18n" by default)
- **-p** Provider of translation API
- **-n** The number of strings to translate in one request ("1" by default)

Google **only**:

- **-k** Google Project API key

Yandex **only**:

- **-f** Yandex Folder ID
- **-i** Yandex IAM token

Microsoft **only**:

- **-m** Microsoft key
- **-e** Microsoft endpoint. ("https://api.cognitive.microsofttranslator.com/" by default)
- **-r** Microsoft multi-service or regional translator resource. It is optional when using a global translator resource. ("global" by default)

## License
Under <a href=https://github.com/VictorKachalov/localized/blob/master/LICENSE>MIT License</a>
