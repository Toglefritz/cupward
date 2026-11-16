import '../../../l10n/app_localizations.dart';
import '../../../models/brews/taste_attribute.dart';

/// The display text for each taste attribute: its name, and the words at the two ends of its slider.
///
/// The text is localized and kept out of the model, the same way `BrewPhaseLabels` names the phases of a brew.
abstract final class TasteAttributeLabels {
  /// Returns the name of [attribute], such as "Bitterness".
  static String nameFor(TasteAttribute attribute, AppLocalizations strings) {
    switch (attribute) {
      case TasteAttribute.intensity:
        return strings.tasteIntensity;
      case TasteAttribute.acidity:
        return strings.tasteAcidity;
      case TasteAttribute.sweetness:
        return strings.tasteSweetness;
      case TasteAttribute.bitterness:
        return strings.tasteBitterness;
      case TasteAttribute.body:
        return strings.tasteBody;
      case TasteAttribute.astringency:
        return strings.tasteAstringency;
      case TasteAttribute.overall:
        return strings.tasteOverall;
    }
  }

  /// Returns the word at the low end of the slider for [attribute], such as "Not bitter".
  static String lowFor(TasteAttribute attribute, AppLocalizations strings) {
    switch (attribute) {
      case TasteAttribute.intensity:
        return strings.tasteIntensityLow;
      case TasteAttribute.acidity:
        return strings.tasteAcidityLow;
      case TasteAttribute.sweetness:
        return strings.tasteSweetnessLow;
      case TasteAttribute.bitterness:
        return strings.tasteBitternessLow;
      case TasteAttribute.body:
        return strings.tasteBodyLow;
      case TasteAttribute.astringency:
        return strings.tasteAstringencyLow;
      case TasteAttribute.overall:
        return strings.tasteOverallLow;
    }
  }

  /// Returns the word at the high end of the slider for [attribute], such as "Very bitter".
  static String highFor(TasteAttribute attribute, AppLocalizations strings) {
    switch (attribute) {
      case TasteAttribute.intensity:
        return strings.tasteIntensityHigh;
      case TasteAttribute.acidity:
        return strings.tasteAcidityHigh;
      case TasteAttribute.sweetness:
        return strings.tasteSweetnessHigh;
      case TasteAttribute.bitterness:
        return strings.tasteBitternessHigh;
      case TasteAttribute.body:
        return strings.tasteBodyHigh;
      case TasteAttribute.astringency:
        return strings.tasteAstringencyHigh;
      case TasteAttribute.overall:
        return strings.tasteOverallHigh;
    }
  }
}
