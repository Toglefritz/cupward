import 'package:flutter_bookoo_example/home/home_route.dart';
import 'package:material_ui/material_ui.dart';

/// The root of the example app, which exists to exercise `flutter_bookoo`.
class ExampleApp extends StatelessWidget {
  /// Creates the app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_bookoo example',
      theme: ThemeData(colorSchemeSeed: Colors.yellow[700]),
      home: const HomeRoute(),
    );
  }
}
