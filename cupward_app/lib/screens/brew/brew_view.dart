import 'package:material_ui/material_ui.dart';

import '../../theme/insets.dart';
import 'brew_controller.dart';
import 'components/brew_phase_indicator.dart';
import 'components/brew_step_heading.dart';
import 'components/recipe_summary_card.dart';

/// Layout for the brewing screen. Contains no logic.
///
/// The recipe summary card sits at the top of a content column of limited width, below an app bar with a back button,
/// and the phase indicator and the current step's heading follow it.
class BrewView extends StatelessWidget {
  /// Creates the view for [state].
  const BrewView(this.state, {super.key});

  /// The controller supplying data and callbacks.
  final BrewController state;

  /// The widest the content column grows on large windows.
  static const double _maxContentWidth = 760;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Insets.small, Insets.xSmall, Insets.small, Insets.large),
              children: <Widget>[
                RecipeSummaryCard(recipe: state.recipe),
                Padding(
                  padding: const EdgeInsets.only(top: Insets.medium),
                  child: BrewPhaseIndicator(phases: state.recipe.phases, currentIndex: state.currentPhaseIndex),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: Insets.large),
                  child: BrewStepHeading(phases: state.recipe.phases, currentIndex: state.currentPhaseIndex),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
