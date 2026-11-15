import 'package:material_ui/material_ui.dart';

import 'home_route.dart';
import 'home_view.dart';

/// Controller for the home screen.
class HomeController extends State<HomeRoute> {
  /// Handles a tap on the "Start a Brew" button.
  ///
  /// This is where a new brewing session begins. The app has no brewing screen yet, so the tap has no effect.
  void onStartBrewPressed() {}

  @override
  Widget build(BuildContext context) => HomeView(this);
}
