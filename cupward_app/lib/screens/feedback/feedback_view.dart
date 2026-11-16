import 'package:material_ui/material_ui.dart';

import '../../components/recipe_summary_card.dart';
import '../../theme/insets.dart';
import 'components/brew_summary_card.dart';
import 'feedback_controller.dart';

/// Layout for the feedback screen. Contains no logic.
///
/// It uses the brewing screen's layout: a scrolling content column of limited width, with the recipe summary card at
/// the top for reference and the summary of the brew below it.
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
              padding: const EdgeInsets.fromLTRB(Insets.small, Insets.xSmall, Insets.small, Insets.small),
              children: <Widget>[
                RecipeSummaryCard(recipe: state.record.recipe),
                Padding(
                  padding: const EdgeInsets.only(top: Insets.small),
                  child: BrewSummaryCard(record: state.record),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
