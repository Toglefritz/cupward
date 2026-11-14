import 'package:flutter/widgets.dart';

import 'home_controller.dart';

/// The only screen of the example app: scan, connect, and inspect a scale.
class HomeRoute extends StatefulWidget {
  /// Creates the route.
  const HomeRoute({super.key});

  @override
  State<HomeRoute> createState() => HomeController();
}
