import 'package:material_ui/material_ui.dart';
import 'home_controller.dart';

/// Landing screen shown when the app first loads.
///
/// [HomeController] coordinates initial setup before the UI becomes interactive: checking required permissions,
/// inspecting device state, and performing first-run configuration. Once initialization completes, the screen presents
/// a call-to-action button that starts a brewing session.
class HomeRoute extends StatefulWidget {
  /// Creates the home route widget.
  const HomeRoute({super.key});

  @override
  State<HomeRoute> createState() => HomeController();
}
