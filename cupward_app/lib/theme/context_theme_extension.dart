import 'package:material_ui/material_ui.dart';

import 'cupward_colors.dart';

/// Shortcuts for reading the theme from a [BuildContext].
extension ContextThemeExtension on BuildContext {
  /// The nearest [ThemeData], equivalent to `Theme.of(context)`.
  ThemeData get theme => Theme.of(this);

  /// The app-specific [CupwardColors] registered on the current theme.
  CupwardColors get cupwardColors => theme.extension<CupwardColors>()!;
}
