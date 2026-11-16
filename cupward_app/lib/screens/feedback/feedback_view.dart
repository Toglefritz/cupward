import 'package:material_ui/material_ui.dart';

import '../../components/recipe_summary_card.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/context_theme_extension.dart';
import '../../theme/insets.dart';
import 'components/brew_summary_card.dart';
import 'components/tasting_notes_card.dart';
import 'feedback_controller.dart';

/// Layout for the feedback screen. Contains no logic.
///
/// It uses the brewing screen's layout: a scrolling content column of limited width. The recipe summary card sits at the
/// top for reference, the summary of the brew below it, then the tasting notes form, and the button that asks for brew
/// feedback at the end. The button is disabled, with a note saying why, until the user has filled in part of the form. Dragging the list hides the
/// keyboard, so the user can scroll back up to the summary while writing.
class FeedbackView extends StatelessWidget {
  /// Creates the view for [state].
  const FeedbackView(this.state, {super.key});

  /// The controller supplying data and callbacks.
  final FeedbackController state;

  /// The widest the content column grows on large windows, matching the brewing screen.
  static const double _maxContentWidth = 760;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(Insets.small, Insets.xSmall, Insets.small, Insets.small),
              children: <Widget>[
                RecipeSummaryCard(recipe: state.record.recipe),
                Padding(
                  padding: const EdgeInsets.only(top: Insets.small),
                  child: BrewSummaryCard(record: state.record),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: Insets.small),
                  child: TastingNotesCard(
                    notes: state.tastingNotes,
                    goalController: state.goalController,
                    onRatingChanged: state.onRatingChanged,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: Insets.medium),
                  child: FilledButton(
                    onPressed: state.canRequestFeedback ? state.onGetFeedbackPressed : null,
                    child: Text(AppLocalizations.of(context)!.buttonGetFeedback),
                  ),
                ),
                if (!state.canRequestFeedback)
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.xSmall),
                    child: Text(
                      AppLocalizations.of(context)!.feedbackNeedsNotes,
                      textAlign: TextAlign.center,
                      style: context.theme.textTheme.bodySmall?.copyWith(
                        color: context.theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
