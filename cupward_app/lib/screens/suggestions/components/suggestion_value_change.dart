import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/feedback/recipe_suggestion.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';
import 'recipe_parameter_labels.dart';

/// A suggested recipe value against the current one, such as "20.0 g → 21.0 g".
///
/// The current value is in the secondary ink color and the suggested value in the serif display face, so the new value
/// is what the eye lands on. Screen readers announce it as a phrase, such as "Coffee, from 20.0 g to 21.0 g".
///
/// Show it only for suggestions where `RecipeSuggestion.hasValueChange` is true.
class SuggestionValueChange extends StatelessWidget {
  /// Creates the value change for [suggestion].
  const SuggestionValueChange({required this.suggestion, super.key});

  /// The suggestion whose values are shown.
  final RecipeSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final String current = RecipeParameterLabels.formatValue(suggestion.parameter, suggestion.currentValue!, strings);
    final String suggested =
        RecipeParameterLabels.formatValue(suggestion.parameter, suggestion.suggestedValue!, strings);

    return Semantics(
      label: strings.suggestionsValueChangeSemantics(
        RecipeParameterLabels.nameFor(suggestion.parameter, strings),
        current,
        suggested,
      ),
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Insets.xSmall,
        children: <Widget>[
          Text(current, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Icon(Icons.arrow_forward, size: 20, color: context.cupwardColors.accent),
          Text(suggested, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 34)),
        ],
      ),
    );
  }
}
