import 'package:material_ui/material_ui.dart';
import 'home_route.dart';
import 'home_view.dart';

/// Controller for the home screen.
class HomeController extends State<HomeRoute> {
  @override
  Widget build(BuildContext context) => HomeView(this);
}
