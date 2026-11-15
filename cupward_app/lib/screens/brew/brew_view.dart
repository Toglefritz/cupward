import 'package:material_ui/material_ui.dart';

import '../../theme/insets.dart';
import 'brew_controller.dart';
import 'components/brew_phase_indicator.dart';
import 'components/brew_phase_labels.dart';
import 'components/brew_step_heading.dart';
import 'components/brew_step_illustration.dart';
import 'components/recipe_summary_card.dart';
import 'components/scale_panel.dart';

/// Layout for the brewing screen. Contains no logic.
///
/// The recipe summary card sits at the top of a content column of limited width, and the phase indicator, the current step's heading, its illustration, and the scale panel follow it. The scale
/// panel is left out on platforms that cannot use a scale, such as the web.
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Insets.small, Insets.xSmall, Insets.small, Insets.small),
              children: <Widget>[
                RecipeSummaryCard(recipe: state.recipe),
                Padding(
                  padding: const EdgeInsets.only(top: Insets.small),
                  child: BrewPhaseIndicator(phases: state.recipe.phases, currentIndex: state.currentPhaseIndex),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: Insets.small),
                  child: BrewStepHeading(phases: state.recipe.phases, currentIndex: state.currentPhaseIndex),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: Insets.xSmall),
                  child: BrewStepIllustration(
                    image: BrewPhaseLabels.imageFor(state.recipe.phases, state.currentPhaseIndex),
                  ),
                ),
                if (state.isScaleSupported)
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.small),
                    child: ScalePanel(
                      status: state.scale.status,
                      reading: state.scale.reading,
                      phaseKind: state.currentPhaseKind,
                      onFindScalePressed: state.onFindScalePressed,
                      onTarePressed: state.onTarePressed,
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
