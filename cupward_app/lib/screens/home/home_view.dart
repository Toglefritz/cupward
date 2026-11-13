import 'package:material_ui/material_ui.dart';
import 'home_controller.dart';

/// View for the home screen.
class HomeView extends StatelessWidget {
  /// Creates the home view with the required controller.
  const HomeView(this.state, {super.key});

  /// Controller instance that manages state and business logic for this view.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/golden_morning.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
