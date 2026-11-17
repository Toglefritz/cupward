import '../../../l10n/app_localizations.dart';
import '../../../models/recipes/brew_phase.dart';
import '../../../models/recipes/brew_phase_kind.dart';
import '../../../theme/brew_step_image.dart';

/// The display text and illustration for the phases of a brew: short names for the phase indicator, and a title, brief
/// instructions, and an image for the current step.
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
      case BrewPhaseKind.steep:
        return strings.brewPhaseSteep;
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
      case BrewPhaseKind.steep:
        return strings.brewStepTitleSteep;
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
      case BrewPhaseKind.steep:
        return strings.brewStepInstructionsSteep;
      case BrewPhaseKind.complete:
        return strings.brewStepInstructionsComplete;
    }
  }

  /// Returns the target line for the phase at [index] in [phases], such as "Target 160 g", or null if the phase has no
  /// target weight.
  ///
  /// The weight is the total on the scale, not the amount to add in this phase. A whole number of grams is shown
  /// without a decimal point.
  static String? targetFor(List<BrewPhase> phases, int index, AppLocalizations strings) {
    final double? target = phases[index].targetWeightGrams;
    if (target == null) {
      return null;
    }
    final String weight = target == target.roundToDouble() ? target.round().toString() : target.toStringAsFixed(1);
    return strings.brewStepTarget(weight);
  }

  /// Returns the label of the main action button for the phase at [index] in [phases]: "Continue" to start the brew,
  /// "Next step" during the bloom, pours, and steep, and "Done" at the end.
  static String actionLabelFor(List<BrewPhase> phases, int index, AppLocalizations strings) {
    switch (phases[index].kind) {
      case BrewPhaseKind.prepare:
        return strings.brewActionContinue;
      case BrewPhaseKind.bloom:
      case BrewPhaseKind.pour:
      case BrewPhaseKind.steep:
        return strings.brewActionNextStep;
      case BrewPhaseKind.complete:
        return strings.brewActionDone;
    }
  }

  /// Returns the illustration for the phase at [index] in [phases].
  ///
  /// Pours use the image for their position among the pours. There are images for three pours, so a recipe with more
  /// pours shows the third pour's image for the rest of them. There is no image of steeping yet, so a steep shows the
  /// bloom's, which also shows coffee resting in water.
  static BrewStepImage imageFor(List<BrewPhase> phases, int index) {
    switch (phases[index].kind) {
      case BrewPhaseKind.prepare:
        return BrewStepImage.prepare;
      case BrewPhaseKind.bloom:
      case BrewPhaseKind.steep:
        return BrewStepImage.bloom;
      case BrewPhaseKind.pour:
        switch (pourNumber(phases, index)) {
          case 1:
            return BrewStepImage.pour1;
          case 2:
            return BrewStepImage.pour2;
          default:
            return BrewStepImage.pour3;
        }
      case BrewPhaseKind.complete:
        return BrewStepImage.complete;
    }
  }

  /// Returns the position of the pour at [index] among the pours in [phases], starting at 1.
  ///
  /// Only pours are counted, so a bloom before the first pour does not shift the numbers.
  static int pourNumber(List<BrewPhase> phases, int index) =>
      phases.take(index + 1).where((BrewPhase phase) => phase.kind == BrewPhaseKind.pour).length;
}
