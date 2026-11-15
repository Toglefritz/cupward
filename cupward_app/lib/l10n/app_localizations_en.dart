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

  @override
  String brewStepTarget(String weight) {
    return 'Target $weight g';
  }

  @override
  String get brewActionContinue => 'Continue';

  @override
  String get brewActionNextStep => 'Next step';

  @override
  String get brewActionDone => 'Done';

  @override
  String brewAdvanceCountdown(int seconds) {
    return 'Next step in $seconds';
  }

  @override
  String get brewAdvanceCancel => 'Cancel';

  @override
  String brewRestRemaining(String time) {
    return 'Rest $time';
  }

  @override
  String get scaleTitle => 'Scale';

  @override
  String get scaleStatusConnected => 'Connected';

  @override
  String get scaleStatusDisconnected => 'Not connected';

  @override
  String get scaleStatusScanning => 'Searching';

  @override
  String get scaleStatusConnecting => 'Connecting';

  @override
  String get scaleStatusUnsupported => 'Not available';

  @override
  String scaleBattery(int percent) {
    return '$percent%';
  }

  @override
  String scaleBatterySemantics(int percent) {
    return 'Scale battery $percent percent';
  }

  @override
  String scaleGrams(String grams) {
    return '$grams g';
  }

  @override
  String scaleFlowRate(String rate) {
    return '$rate g/s';
  }

  @override
  String get scaleFlowLabel => 'Flow';

  @override
  String get scaleNoReading => '–';

  @override
  String get buttonTare => 'Tare';

  @override
  String get buttonFindScale => 'Find scale';

  @override
  String get scalePickerTitle => 'Choose your scale';

  @override
  String get scalePickerSearching => 'Looking for BOOKOO scales. Make sure yours is on and nearby.';

  @override
  String get scalePickerNoneFound => 'No scales found. Wake your scale, then search again.';

  @override
  String scalePickerSignal(int rssi) {
    return 'Signal $rssi dBm';
  }

  @override
  String get buttonSearchAgain => 'Search again';

  @override
  String get scaleFailureBluetooth => 'Turn on Bluetooth and allow Cupward to use it, then try again.';

  @override
  String get scaleFailureConnection => 'Couldn\'t connect to the scale. Make sure it\'s on and nearby.';

  @override
  String get scaleFailureUnsupported => 'That device isn\'t a supported scale.';

  @override
  String get scaleFailureUnknown => 'Something went wrong with the scale. Try again.';

  @override
  String get scaleTareFailed => 'Couldn\'t tare the scale.';
}
