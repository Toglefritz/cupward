import 'package:material_ui/material_ui.dart';

import '../../../components/content_card.dart';
import '../../../models/feedback/recipe_suggestion.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';
import 'suggestion_direction_chip.dart';
import 'suggestion_value_change.dart';

/// A smaller card for a change to try in a later brew.
///
/// It shows what the change is, what it changes and which way, how much, and why, in that order. It leaves out the
/// expected effect and the captions of the main suggestion, so it reads as secondary to it.
class AlternativeSuggestionCard extends StatelessWidget {
  /// Creates the card for [suggestion].
  const AlternativeSuggestionCard({required this.suggestion, super.key});

  /// The change described.
  final RecipeSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;

    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(suggestion.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          Padding(
            padding: const EdgeInsets.only(top: Insets.xxSmall),
            child: SuggestionDirectionChip(suggestion: suggestion),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.xSmall),
            child: suggestion.hasValueChange
                ? SuggestionValueChange(suggestion: suggestion)
                : Text(suggestion.change, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.xSmall),
            child: Text(
              suggestion.rationale,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
