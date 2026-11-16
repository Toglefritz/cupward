import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';

/// A text field where the user says, in their own words, how they would like the next brew to taste.
///
/// The question sits above the field as a label, and an example fills the empty field as a hint. The field grows to a
/// few lines as the user writes, and a counter shows how much of [maxLength] is used. Its border uses the cards'
/// hairline color, and the theme's green while the field has focus. Screen readers announce the question with the field.
class TastingGoalField extends StatelessWidget {
  /// Creates a field that edits the text in [controller].
  const TastingGoalField({required this.controller, super.key});

  /// Holds the text of the field.
  final TextEditingController controller;

  /// The most characters the field accepts. Enough for a few sentences, and short enough to keep a prompt focused.
  static const int maxLength = 500;

  /// The corner radius of the field, matching the theme's buttons.
  static const double _cornerRadius = 10;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(_cornerRadius),
          borderSide: BorderSide(color: color, width: width),
        );

    // Merged so that screen readers announce the question with the field.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(strings.tastingGoalLabel, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Padding(
            padding: const EdgeInsets.only(top: Insets.xSmall),
            child: TextField(
              controller: controller,
              minLines: 3,
              maxLines: 6,
              maxLength: maxLength,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: strings.tastingGoalHint,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.all(Insets.small),
                enabledBorder: border(context.cupwardColors.cardBorder, 1),
                focusedBorder: border(theme.colorScheme.primary, 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
