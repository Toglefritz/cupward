import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/recipes/brew_phase.dart';
import '../models/brew_phase_status.dart';
import 'brew_phase_labels.dart';
import 'brew_phase_step.dart';

/// Shows the phases of a brew in a row and how far the user has come through them.
///
/// Each phase gets an equal share of the width. Phases before [currentIndex] are finished, the one at it is current,
/// and those after it are upcoming. Screen readers announce the indicator as one item, such as "Step 2 of 6, Bloom".
class BrewPhaseIndicator extends StatelessWidget {
  /// Creates the indicator for [phases], with the brew at the phase at [currentIndex].
  const BrewPhaseIndicator({required this.phases, required this.currentIndex, super.key})
      : assert(currentIndex >= 0, 'currentIndex must not be negative');

  /// The phases of the brew, in order.
  final List<BrewPhase> phases;

  /// The position of the current phase in [phases].
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      label: strings.brewPhaseProgress(
        currentIndex + 1,
        phases.length,
        BrewPhaseLabels.labelFor(phases, currentIndex, strings),
      ),
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int index = 0; index < phases.length; index++)
              Expanded(
                child: BrewPhaseStep(
                  label: BrewPhaseLabels.labelFor(phases, index, strings),
                  status: BrewPhaseStatus.of(index, currentIndex),
                  isFirst: index == 0,
                  isLast: index == phases.length - 1,
                  // A half of the line is reached once the brew is at or past the phase it leads to.
                  isLeadingLineReached: index <= currentIndex,
                  isTrailingLineReached: index < currentIndex,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
