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
}
