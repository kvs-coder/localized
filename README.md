# localized

String extensions for localization

## Getting Started

- Go inside pubspec.yaml file
- Add this to your package's pubspec.yaml file: 
``` Dart
dependencies:
     localized: ^1.0.2
```
- Get dependencies

``` shell
flutter pub get
``` 

## How to use

The package generates assets with i18n empty content as JSON files for future localized strings.

First think about the localization you want to use and run the script (as an example EN, DE, RU are provided)
specifying the localizations in a line separated with commas

``` shell
flutter pub run localized:main -l en,de,ru
``` 

As a result this will be added to the project tree:

``` shell
- assets
    - i18n
        - de.json
        - en.json
        - ru.json
``` 

A generated assets folder with i18n folder inside and generated JSON files.

Next step is to add these assets in a <b>pubspec.yaml</b> file

``` Dart
flutter:
  assets:
    - assets/i18n/
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
        LocalizationService.delegate(locales),
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
        LocalizationService.delegate(locales),
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

Under <a href=https://github.com/VictorKachalov/localized/blob/master/LICENSE>MIT License</a>
