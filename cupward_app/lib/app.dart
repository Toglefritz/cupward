/// Root application widget for the cupward Flutter application.
///
/// This file contains the main application widget that configures the Flutter app with Material Design theming and sets
/// up the initial route to the home screen following MVC architecture patterns.
library;

import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';
import 'screens/home/home_route.dart';
import 'theme/cupward_colors.dart';

part 'theme/app_theme.dart';

/// Root application widget that configures the Flutter app.
///
/// This widget serves as the top-level container for the entire application and is responsible for:
/// * Setting up the app's theme
/// * Configuring the app title and debug settings
/// * Defining the initial route (home screen)
///
/// The widget follows the StatelessWidget pattern as it contains no mutable state and serves purely as a configuration
/// container.
class Cupward extends StatelessWidget {
  /// Creates the root application widget.
  const Cupward({super.key});

  /// Builds the widget tree for the root application.
  ///
  /// Returns a [MaterialApp] configured with:
  /// * App title derived from the project name
  /// * The theme from [_AppTheme]
  /// * Home route pointing to the main screen
  /// * Debug banner disabled for cleaner presentation
  /// * Localization support for multiple languages
  ///
  /// The [MaterialApp] provides the foundation for Material Design components and navigation throughout the
  /// application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cupward',
      debugShowCheckedModeBanner: false,

      // The app has a single, light theme.
      theme: _AppTheme.light,
      home: const HomeRoute(),

      // Localizations
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
