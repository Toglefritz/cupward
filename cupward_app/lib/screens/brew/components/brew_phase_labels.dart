import '../../../l10n/app_localizations.dart';
import '../../../models/recipes/brew_phase.dart';
import '../../../models/recipes/brew_phase_kind.dart';

/// Names the phases of a brew for display, such as "Bloom" or "Pour 2".
///
/// Names come from each phase's kind and are localized, so recipes do not store display text for their phases. A pour
/// is numbered by its position among the recipe's pours, which is why the whole list of phases is needed.
abstract final class BrewPhaseLabels {
  /// Returns the display name of the phase at [index] in [phases].
  static String labelFor(List<BrewPhase> phases, int index, AppLocalizations strings) {
    switch (phases[index].kind) {
      case BrewPhaseKind.prepare:
        return strings.brewPhasePrepare;
      case BrewPhaseKind.bloom:
        return strings.brewPhaseBloom;
      case BrewPhaseKind.pour:
        final int pourNumber =
            phases.take(index + 1).where((BrewPhase phase) => phase.kind == BrewPhaseKind.pour).length;

        return strings.brewPhasePour(pourNumber);
      case BrewPhaseKind.complete:
        return strings.brewPhaseComplete;
    }
  }
}
