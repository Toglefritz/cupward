import 'package:material_ui/material_ui.dart';

import '../theme/context_theme_extension.dart';
import '../theme/insets.dart';
import 'content_card.dart';

/// Builds the app's short messages, shown with `ScaffoldMessenger.showSnackBar`.
///
/// Each message is drawn as one of the app's cream cards, floating above the content: a hairline border, rounded
/// corners, and the cards' soft shadow. The SnackBar itself is transparent, because Material draws a SnackBar's shadow
/// in black, which reads as a dark ring around a cream card. An icon comes before the message: a green check for a
/// confirmation, and the error color's warning for a problem. Confirmations are brief, because they only acknowledge
/// something the user can already see.
abstract final class AppSnackBars {
  /// How long a confirmation stays on screen.
  static const Duration confirmationDuration = Duration(seconds: 3);

  /// How long a problem stays on screen, a little longer so it can be read.
  static const Duration problemDuration = Duration(seconds: 5);

  /// Returns a SnackBar confirming [message], such as that a recipe was created.
  static SnackBar confirmation(BuildContext context, String message) {
    return _snackBar(
      duration: confirmationDuration,
      content: _content(context, icon: Icons.check_circle, color: context.cupwardColors.success, message: message),
    );
  }

  /// Returns a SnackBar reporting the problem in [message], such as that a save failed.
  static SnackBar problem(BuildContext context, String message) {
    return _snackBar(
      duration: problemDuration,
      content: _content(context, icon: Icons.error_outline, color: context.theme.colorScheme.error, message: message),
    );
  }

  /// A transparent floating SnackBar that shows [content] for [duration].
  static SnackBar _snackBar({required Duration duration, required Widget content}) {
    return SnackBar(
      duration: duration,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.none,
      shape: const RoundedRectangleBorder(),
      content: content,
    );
  }

  /// The icon and message, side by side in a card.
  static Widget _content(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return ContentCard(
      padding: const EdgeInsets.symmetric(horizontal: Insets.small, vertical: Insets.small),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: color),
          const SizedBox(width: Insets.xSmall),
          Expanded(child: Text(message, style: context.theme.snackBarTheme.contentTextStyle)),
        ],
      ),
    );
  }
}
