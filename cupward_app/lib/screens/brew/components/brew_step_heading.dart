import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/recipes/brew_phase.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';
import 'brew_phase_labels.dart';

/// The text for the current step of a brew: a count such as "STEP 1 OF 6", a large serif title, and a one-sentence
/// reminder of what to do.
///
/// The three lines are centered. The count uses the spaced label style in the copper accent, the title uses the
/// theme's screen-title face at a size that leaves room for the rest of the step on a phone screen, and the instructions use running text in the secondary ink color. The title is marked
/// as a heading for screen readers. The count repeats what the phase indicator already announces, so it is left out of
/// the announcement.
class BrewStepHeading extends StatelessWidget {
  /// Creates the heading for the phase at [currentIndex] in [phases].
  const BrewStepHeading({required this.phases, required this.currentIndex, super.key});

  /// The phases of the brew, in order.
  final List<BrewPhase> phases;

  /// The position of the current phase in [phases].
  final int currentIndex;

  /// The widest the instructions grow, so that they wrap into short lines on wide screens instead of one long one.
  static const double _maxInstructionsWidth = 440;

  /// The size of the title. It is smaller than the theme's screen-title size, because the brewing screen fits the
  /// recipe, the step, and the scale readings on one phone screen.
  static const double _titleFontSize = 40;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;

    return Column(
      children: <Widget>[
        ExcludeSemantics(
          child: Text(
            strings.brewStepCount(currentIndex + 1, phases.length),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.cupwardColors.accent,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.xxSmall),
          child: Semantics(
            header: true,
            child: Text(
              BrewPhaseLabels.titleFor(phases, currentIndex, strings),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge?.copyWith(fontSize: _titleFontSize),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.xSmall),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxInstructionsWidth),
            child: Text(
              BrewPhaseLabels.instructionsFor(phases, currentIndex, strings),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
