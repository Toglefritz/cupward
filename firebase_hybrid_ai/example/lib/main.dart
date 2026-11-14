import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'firebase_options.dart';

/// Initializes Firebase and starts the example app.
///
/// `firebase_options.dart` is generated per developer by the FlutterFire CLI and is not committed. See
/// FIREBASE_SETUP.md.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ExampleApp());
}
