import '../../../l10n/app_localizations.dart';
import '../../../models/recipes/brew_method.dart';

/// The display text for each brewing method: its name, a one-line description of the cup it tends to give, and its
/// typical brew time.
abstract final class BrewMethodLabels {
  /// Returns the name of [method], such as "French press".
  static String nameFor(BrewMethod method, AppLocalizations strings) {
    switch (method) {
      case BrewMethod.v60:
        return strings.brewMethodV60;
      case BrewMethod.kalitaWave:
        return strings.brewMethodKalitaWave;
      case BrewMethod.chemex:
        return strings.brewMethodChemex;
      case BrewMethod.frenchPress:
        return strings.brewMethodFrenchPress;
      case BrewMethod.aeroPress:
        return strings.brewMethodAeroPress;
      case BrewMethod.cleverDripper:
        return strings.brewMethodCleverDripper;
    }
  }

  /// Returns the one-line description of [method].
  static String descriptionFor(BrewMethod method, AppLocalizations strings) {
    switch (method) {
      case BrewMethod.v60:
        return strings.brewMethodV60Description;
      case BrewMethod.kalitaWave:
        return strings.brewMethodKalitaWaveDescription;
      case BrewMethod.chemex:
        return strings.brewMethodChemexDescription;
      case BrewMethod.frenchPress:
        return strings.brewMethodFrenchPressDescription;
      case BrewMethod.aeroPress:
        return strings.brewMethodAeroPressDescription;
      case BrewMethod.cleverDripper:
        return strings.brewMethodCleverDripperDescription;
    }
  }

  /// Returns the typical brew time of [method], such as "About 3½ min". Times are given to the nearest half minute.
  static String timeFor(BrewMethod method, AppLocalizations strings) {
    final int halfMinutes = (method.typicalBrewTime.inSeconds / 30).round();
    final String minutes = '${halfMinutes ~/ 2}${halfMinutes.isOdd ? '½' : ''}';
    return strings.brewMethodTime(minutes);
  }
}
