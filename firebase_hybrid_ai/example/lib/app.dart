import 'package:material_ui/material_ui.dart';

import 'screens/home/home_route.dart';

/// The root widget of the example app.
class ExampleApp extends StatelessWidget {
  /// Creates the root widget.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Hybrid AI',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)), useMaterial3: true),
      home: const HomeRoute(),
    );
  }
}
