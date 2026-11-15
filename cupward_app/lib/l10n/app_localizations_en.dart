// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cupward';

  @override
  String get buttonStartBrew => 'Start a Brew';

  @override
  String get recipeCoffeeLabel => 'Coffee';

  @override
  String get recipeWaterLabel => 'Water';

  @override
  String get recipeBrewTimeLabel => 'Time';

  @override
  String get recipeYieldLabel => 'Yield';

  @override
  String recipeGrams(String grams) {
    return '$grams g';
  }

  @override
  String recipeYieldMilliliters(String milliliters) {
    return '~$milliliters ml';
  }

  @override
  String get brewPhasePrepare => 'Prepare';

  @override
  String get brewPhaseBloom => 'Bloom';

  @override
  String brewPhasePour(int number) {
    return 'Pour $number';
  }

  @override
  String get brewPhaseComplete => 'Complete';

  @override
  String brewPhaseProgress(int current, int total, String phase) {
    return 'Step $current of $total, $phase';
  }

  @override
  String brewStepCount(int current, int total) {
    return 'STEP $current OF $total';
  }

  @override
  String get brewStepTitlePrepare => 'Prepare to Brew';

  @override
  String get brewStepTitleBloom => 'Bloom';

  @override
  String brewStepTitlePour(int number) {
    return 'Pour $number';
  }

  @override
  String get brewStepTitleComplete => 'Enjoy Your Coffee';

  @override
  String get brewStepInstructionsPrepare => 'Set up your brewer, place it on the scale, and tare.';

  @override
  String get brewStepInstructionsBloom => 'Wet all the grounds with a little water, then let them rest.';

  @override
  String get brewStepInstructionsPour => 'Pour slowly and evenly to the next target.';

  @override
  String get brewStepInstructionsComplete => 'Let it finish draining, then swirl and serve.';
}
