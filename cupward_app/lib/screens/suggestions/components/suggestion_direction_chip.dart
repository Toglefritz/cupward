import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/feedback/change_direction.dart';
import '../../../models/feedback/recipe_suggestion.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';
import 'recipe_parameter_labels.dart';

/// A small label naming what a suggestion changes and which way, such as "Grind size · Finer", with an arrow.
///
/// It uses the copper accent, so the variable being changed stands out from the explanation around it.
class SuggestionDirectionChip extends StatelessWidget {
  /// Creates a chip for [suggestion].
  const SuggestionDirectionChip({required this.suggestion, super.key});

  /// The suggestion described.
  final RecipeSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final Color accent = context.cupwardColors.accent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          suggestion.direction == ChangeDirection.increase ? Icons.arrow_upward : Icons.arrow_downward,
          size: 16,
          color: accent,
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(left: Insets.xxSmall),
            child: Text(
              '${RecipeParameterLabels.nameFor(suggestion.parameter, strings)} · '
              '${RecipeParameterLabels.directionFor(suggestion.parameter, suggestion.direction, strings)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: accent, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
