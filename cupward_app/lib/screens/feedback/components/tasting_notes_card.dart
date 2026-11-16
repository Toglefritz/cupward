import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/brews/taste_attribute.dart';
import '../../../models/brews/tasting_notes.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';
import 'taste_slider.dart';
import 'tasting_goal_field.dart';

/// A card where the user describes how the brew tasted and how they want the next one to taste.
///
/// Under a "Tasting notes" heading and a one-line explanation, there is a slider for each `TasteAttribute`, in the
/// order the enum lists them, with "Overall" last. A text field for the user's goal for the next brew follows a rule.
/// Every part is optional.
///
/// The card matches the brew summary card above it: a cream surface with a hairline border and rounded corners.
class TastingNotesCard extends StatelessWidget {
  /// Creates a card showing the ratings in [notes], with the goal edited through [goalController].
  const TastingNotesCard({
    required this.notes,
    required this.goalController,
    required this.onRatingChanged,
    super.key,
  });

  /// The ratings so far. Only its ratings are read here, because the goal lives in [goalController].
  final TastingNotes notes;

  /// Holds the text of the goal field.
  final TextEditingController goalController;

  /// Called with an attribute and its new rating when the user moves a slider.
  final void Function(TasteAttribute attribute, int rating) onRatingChanged;

  /// The corner radius of the card, matching the other cards.
  static const double _cornerRadius = 16;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final Color ruleColor = context.cupwardColors.cardBorder;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cupwardColors.cardSurface,
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: Border.all(color: ruleColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.medium, vertical: Insets.small),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(strings.tastingNotesTitle, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 26)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: Insets.xxSmall),
              child: Text(
                strings.tastingNotesIntro,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Insets.small),
              child: Divider(color: ruleColor),
            ),
            for (final TasteAttribute attribute in TasteAttribute.values)
              Padding(
                padding: const EdgeInsets.only(bottom: Insets.small),
                child: TasteSlider(
                  attribute: attribute,
                  rating: notes.ratings[attribute],
                  onChanged: (int rating) => onRatingChanged(attribute, rating),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.small),
              child: Divider(color: ruleColor),
            ),
            TastingGoalField(controller: goalController),
          ],
        ),
      ),
    );
  }
}
