import 'package:material_ui/material_ui.dart';

import '../../../components/content_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/recipes/new_recipe_request.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';

/// A card where the user describes how they like their coffee, in their own words.
///
/// The question sits above a text field whose hint gives an example covering strength, roast, cup size, and body.
/// Below the field, a row of topic chips, such as "Roast" and "Cup size", suggests what to mention. Tapping a topic
/// calls [onTopicPressed] with its label, which the screen uses to start a line about it.
class TastePreferencesField extends StatelessWidget {
  /// Creates the field, editing the text in [controller].
  const TastePreferencesField({
    required this.controller,
    required this.focusNode,
    required this.onTopicPressed,
    super.key,
  });

  /// Holds the text of the field.
  final TextEditingController controller;

  /// The field's focus, so a topic tap can return the keyboard to it.
  final FocusNode focusNode;

  /// Called with the label of the topic the user tapped.
  final ValueChanged<String> onTopicPressed;

  /// The corner radius of the field, matching the theme's buttons.
  static const double _fieldCornerRadius = 10;

  /// Returns the topics the user might mention, in order.
  static List<String> topicsFor(AppLocalizations strings) => <String>[
        strings.newRecipeTopicStrength,
        strings.newRecipeTopicRoast,
        strings.newRecipeTopicCupSize,
        strings.newRecipeTopicBody,
        strings.newRecipeTopicSweetness,
        strings.newRecipeTopicAcidity,
      ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final Color hairline = context.cupwardColors.cardBorder;

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(_fieldCornerRadius),
          borderSide: BorderSide(color: color, width: width),
        );

    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  strings.newRecipePreferencesLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: Insets.xSmall),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: NewRecipeRequest.maxPreferencesLength,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: strings.newRecipePreferencesHint,
                      hintMaxLines: 4,
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.all(Insets.small),
                      enabledBorder: border(hairline, 1),
                      focusedBorder: border(theme.colorScheme.primary, 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.xxSmall),
            child: Text(
              strings.newRecipeTopicsLabel,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.xSmall),
            child: Wrap(
              spacing: Insets.xSmall,
              runSpacing: Insets.xSmall,
              children: <Widget>[
                for (final String topic in topicsFor(strings))
                  ActionChip(
                    avatar: Icon(Icons.add, size: 16, color: context.cupwardColors.accent),
                    label: Text(topic),
                    labelStyle: theme.textTheme.bodyMedium,
                    backgroundColor: theme.colorScheme.surface,
                    side: BorderSide(color: hairline),
                    shape: const StadiumBorder(),
                    onPressed: () => onTopicPressed(topic),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
