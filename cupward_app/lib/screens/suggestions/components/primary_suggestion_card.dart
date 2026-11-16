import 'package:material_ui/material_ui.dart';

import '../../../components/content_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/feedback/recipe_suggestion.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';
import 'suggestion_direction_chip.dart';
import 'suggestion_value_change.dart';

/// The one change to try in the next brew, shown as the screen's main card.
///
/// From top to bottom: a "TRY THIS NEXT" label in the copper accent, the change as a serif title, what it changes and
/// which way, the new recipe value against the current one when there is one, and otherwise how much to change it in
/// words. Below a rule, the reason and the expected effect follow under their own captions, and a closing note explains
/// why only one change is recommended.
class PrimarySuggestionCard extends StatelessWidget {
  /// Creates the card for [suggestion].
  const PrimarySuggestionCard({required this.suggestion, super.key});

  /// The change to try next.
  final RecipeSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final Color ruleColor = context.cupwardColors.cardBorder;
    final TextStyle? captionStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final TextStyle? bodyStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.4);

    return ContentCard(
      padding: const EdgeInsets.all(Insets.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(
            child: Text(
              strings.suggestionsPrimaryEyebrow,
              style: theme.textTheme.labelMedium?.copyWith(
                color: context.cupwardColors.accent,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.xSmall),
            child: Semantics(
              header: true,
              child: Text(suggestion.title, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 30, height: 1.1)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.xSmall),
            child: SuggestionDirectionChip(suggestion: suggestion),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.small),
            child: suggestion.hasValueChange
                ? SuggestionValueChange(suggestion: suggestion)
                : Text(suggestion.change, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          if (suggestion.hasValueChange)
            Padding(
              padding: const EdgeInsets.only(top: Insets.xxSmall),
              child: Text(
                suggestion.change,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Insets.small),
            child: Divider(color: ruleColor),
          ),
          Text(strings.suggestionsWhyLabel, style: captionStyle),
          Padding(
            padding: const EdgeInsets.only(top: Insets.xxSmall),
            child: Text(suggestion.rationale, style: bodyStyle),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.small),
            child: Text(strings.suggestionsEffectLabel, style: captionStyle),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.xxSmall),
            child: Text(suggestion.expectedEffect, style: bodyStyle),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.small),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: Insets.xSmall),
                    child: Text(
                      strings.suggestionsOneChangeNote,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
