import '../../../l10n/app_localizations.dart';
import '../../../models/recipes/brew_phase.dart';
import '../../../models/recipes/brew_phase_kind.dart';

/// The display text for the phases of a brew: short names for the phase indicator, and a title and brief instructions
/// for the current step.
///
/// The text comes from each phase's kind and is localized, so recipes do not store display text for their phases. A
/// pour is numbered by its position among the recipe's pours, which is why the whole list of phases is needed.
///
/// Instructions are deliberately one short sentence. The user is in the middle of brewing and has usually brewed
/// before, so they serve as a reminder rather than a lesson.
abstract final class BrewPhaseLabels {
  /// Returns the short name of the phase at [index] in [phases], as shown in the phase indicator, such as "Pour 2".
  static String labelFor(List<BrewPhase> phases, int index, AppLocalizations strings) {
    switch (phases[index].kind) {
      case BrewPhaseKind.prepare:
        return strings.brewPhasePrepare;
      case BrewPhaseKind.bloom:
        return strings.brewPhaseBloom;
      case BrewPhaseKind.pour:
        return strings.brewPhasePour(pourNumber(phases, index));
      case BrewPhaseKind.complete:
        return strings.brewPhaseComplete;
    }
  }

  /// Returns the large title of the phase at [index] in [phases], such as "Prepare to Brew".
  static String titleFor(List<BrewPhase> phases, int index, AppLocalizations strings) {
    switch (phases[index].kind) {
      case BrewPhaseKind.prepare:
        return strings.brewStepTitlePrepare;
      case BrewPhaseKind.bloom:
        return strings.brewStepTitleBloom;
      case BrewPhaseKind.pour:
        return strings.brewStepTitlePour(pourNumber(phases, index));
      case BrewPhaseKind.complete:
        return strings.brewStepTitleComplete;
    }
  }

  /// Returns the brief instructions for the phase at [index] in [phases].
  static String instructionsFor(List<BrewPhase> phases, int index, AppLocalizations strings) {
    switch (phases[index].kind) {
      case BrewPhaseKind.prepare:
        return strings.brewStepInstructionsPrepare;
      case BrewPhaseKind.bloom:
        return strings.brewStepInstructionsBloom;
      case BrewPhaseKind.pour:
        return strings.brewStepInstructionsPour;
      case BrewPhaseKind.complete:
        return strings.brewStepInstructionsComplete;
    }
  }

  /// Returns the position of the pour at [index] among the pours in [phases], starting at 1.
  ///
  /// Only pours are counted, so a bloom before the first pour does not shift the numbers.
  static int pourNumber(List<BrewPhase> phases, int index) =>
      phases.take(index + 1).where((BrewPhase phase) => phase.kind == BrewPhaseKind.pour).length;
}
