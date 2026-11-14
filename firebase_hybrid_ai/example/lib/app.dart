import 'package:material_ui/material_ui.dart';

import 'screens/home/home_route.dart';
import 'theme/app_theme.dart';

/// The root widget of the example app.
class ExampleApp extends StatelessWidget {
  /// Creates the root widget.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Hybrid AI',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const HomeRoute(),
    );
  }
}
