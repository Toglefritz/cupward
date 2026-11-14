import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'firebase_options.dart';

/// Initializes Firebase and App Check, and starts the example app.
///
/// `firebase_options.dart` is generated per developer by the FlutterFire CLI and is not committed. See
/// FIREBASE_SETUP.md.
///
/// Firebase AI Logic rejects cloud requests that do not carry an App Check token, so App Check is activated here.
/// Debug builds use the debug providers, whose tokens must be registered in the Firebase console. The token is
/// printed to the console on first launch. Requests that only use the on-device model never contact Firebase, so they
/// work without a registered token.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
      providerApple: const AppleDebugProvider(),
      providerWeb: WebDebugProvider(),
    );
  } else {
    // Release builds use the default attestation providers. On the web this needs a reCAPTCHA provider, so a web
    // release build must pass its own `providerWeb` here.
    await FirebaseAppCheck.instance.activate();
  }

  runApp(const ExampleApp());
}
