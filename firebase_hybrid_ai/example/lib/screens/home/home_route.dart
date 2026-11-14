import 'package:material_ui/material_ui.dart';

import 'home_controller.dart';

/// The only screen of the example app. It reports the state of the on-device model.
class HomeRoute extends StatefulWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  State<HomeRoute> createState() => HomeController();
}
