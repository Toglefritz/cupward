import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';

/// The app's name, shown as a centered serif title over the home screen's photograph.
///
/// The title uses the theme's screen-title style, the display serif at 48, and scales down on very narrow screens so
/// that it always fits on one line. The top of the photograph is dark, so the title is drawn in the paper color, with a soft ink shadow that
/// keeps it legible over the lighter areas of the image.
class HomeTitle extends StatelessWidget {
  /// Creates the title.
  const HomeTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final ColorScheme colors = theme.colorScheme;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 256,
            height: 6,
            margin: const EdgeInsets.only(top: Insets.medium),
            decoration: BoxDecoration(
              border: Border.all(
                color: context.theme.colorScheme.primary,
                width: 6,
              ),
            ),
          ),
          Text(
            AppLocalizations.of(context)!.appTitle,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 72,
              color: colors.surface,
              shadows: <Shadow>[
                Shadow(color: colors.onSurface.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
