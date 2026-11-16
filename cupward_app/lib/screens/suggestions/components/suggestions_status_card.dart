import 'package:material_ui/material_ui.dart';

import '../../../components/content_card.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';

/// A card for the brew feedback screen while there is no feedback to show: either a progress indicator while it is
/// prepared, or a message with an action when it could not be.
///
/// The [title] is a serif heading and the [message] a sentence of running text below it. A spinner shows while
/// [isBusy] is true, and the [action], such as a Try again button, follows the message when one is given.
class SuggestionsStatusCard extends StatelessWidget {
  /// Creates a card with [title] and [message].
  const SuggestionsStatusCard({
    required this.title,
    required this.message,
    this.isBusy = false,
    this.action,
    super.key,
  });

  /// The heading of the card.
  final String title;

  /// One or two sentences about what is happening.
  final String message;

  /// Whether to show a spinner, while feedback is being prepared.
  final bool isBusy;

  /// A button below the message, or null for none.
  final Widget? action;

  /// The size of the spinner.
  static const double _spinnerSize = 28;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final Widget? actionWidget = action;

    return ContentCard(
      padding: const EdgeInsets.all(Insets.medium),
      child: Column(
        children: <Widget>[
          if (isBusy)
            const Padding(
              padding: EdgeInsets.only(bottom: Insets.small),
              child: SizedBox.square(dimension: _spinnerSize, child: CircularProgressIndicator(strokeWidth: 3)),
            ),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 26),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.xSmall),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
            ),
          ),
          if (actionWidget != null) Padding(padding: const EdgeInsets.only(top: Insets.small), child: actionWidget),
        ],
      ),
    );
  }
}
