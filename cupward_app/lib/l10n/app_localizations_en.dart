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

  @override
  String get modelTitle => 'On-device AI';

  @override
  String get modelStatusChecking => 'Checking';

  @override
  String get modelStatusReady => 'Ready';

  @override
  String get modelStatusDownloadable => 'Not downloaded';

  @override
  String get modelStatusDownloading => 'Downloading';

  @override
  String get modelStatusUnavailable => 'Not supported';

  @override
  String get modelStatusUnknown => 'Couldn\'t check';

  @override
  String get modelMessageChecking => 'Checking whether brew feedback can run on this device.';

  @override
  String get modelMessageReady => 'Brew feedback runs on this device, even offline.';

  @override
  String get modelMessageDownloadable =>
      'Download the model for brew feedback on this device, even offline. Until then, it comes from the cloud.';

  @override
  String get modelMessageDownloading =>
      'Brew feedback comes from the cloud until the download finishes. You can start brewing now.';

  @override
  String get modelMessageUnavailable =>
      'This device can\'t run an on-device model, so brew feedback comes from the cloud.';

  @override
  String get modelMessageUnknown => 'Couldn\'t check for the on-device model. Brew feedback will come from the cloud.';

  @override
  String get modelDownloadFailed => 'The download didn\'t finish. Check your connection and try again.';

  @override
  String modelDownloadProgress(int percent) {
    return '$percent%';
  }

  @override
  String modelDownloadProgressSemantics(int percent) {
    return 'Model download $percent percent';
  }

  @override
  String get buttonDownloadModel => 'Download';

  @override
  String get buttonTryAgain => 'Try again';

  @override
  String get brewSummaryTitle => 'Your brew';

  @override
  String get brewSummaryPeakFlowLabel => 'Peak flow';

  @override
  String brewSummaryTarget(String value) {
    return 'Target $value';
  }

  @override
  String get brewSummaryNoReadings => 'No scale was connected, so this brew has step times but no weights.';

  @override
  String brewSummaryChartSemantics(String weight, String time) {
    return 'Weight over time. $weight after $time.';
  }

  @override
  String get brewSummaryStepHeader => 'Step';

  @override
  String get brewSummaryTimeHeader => 'Time';

  @override
  String get brewSummaryWeightHeader => 'Weight';

  @override
  String get brewSummaryTargetHeader => 'Target';

  @override
  String get tastingNotesTitle => 'Tasting notes';

  @override
  String get tastingNotesIntro => 'Rate what you tasted. Skip anything you\'re not sure about.';

  @override
  String get tastingNotRated => 'Not rated';

  @override
  String tastingRatingSemantics(int rating, int max) {
    return '$rating of $max';
  }

  @override
  String get tasteIntensity => 'Intensity';

  @override
  String get tasteIntensityLow => 'Weak';

  @override
  String get tasteIntensityHigh => 'Strong';

  @override
  String get tasteAcidity => 'Acidity';

  @override
  String get tasteAcidityLow => 'Flat';

  @override
  String get tasteAcidityHigh => 'Bright';

  @override
  String get tasteSweetness => 'Sweetness';

  @override
  String get tasteSweetnessLow => 'Not sweet';

  @override
  String get tasteSweetnessHigh => 'Very sweet';

  @override
  String get tasteBitterness => 'Bitterness';

  @override
  String get tasteBitternessLow => 'Not bitter';

  @override
  String get tasteBitternessHigh => 'Very bitter';

  @override
  String get tasteBody => 'Body';

  @override
  String get tasteBodyLow => 'Thin';

  @override
  String get tasteBodyHigh => 'Heavy';

  @override
  String get tasteAstringency => 'Astringency';

  @override
  String get tasteAstringencyLow => 'Smooth';

  @override
  String get tasteAstringencyHigh => 'Drying';

  @override
  String get tasteOverall => 'Overall';

  @override
  String get tasteOverallLow => 'Disliked';

  @override
  String get tasteOverallHigh => 'Loved it';

  @override
  String get tastingGoalLabel => 'What would you change next time?';

  @override
  String get tastingGoalHint => 'For example: a little sweeter, with less bitterness.';

  @override
  String get buttonGetFeedback => 'Get brew feedback';

  @override
  String get feedbackNeedsNotes => 'Rate at least one thing, or say what you\'d change, to get feedback.';

  @override
  String get suggestionsLoadingTitle => 'Tasting your brew';

  @override
  String get suggestionsLoadingMessage => 'Reviewing your readings and tasting notes. This can take a few seconds.';

  @override
  String get suggestionsTitle => 'Your next brew';

  @override
  String get suggestionsSourceOnDevice => 'On-device AI';

  @override
  String get suggestionsSourceCloud => 'Cloud AI';

  @override
  String get suggestionsPrimaryEyebrow => 'TRY THIS NEXT';

  @override
  String get suggestionsWhyLabel => 'Why';

  @override
  String get suggestionsEffectLabel => 'What to expect';

  @override
  String get suggestionsOneChangeNote => 'Change one thing at a time, so you can taste what it does.';

  @override
  String get suggestionsAlternativesTitle => 'Ideas for later brews';

  @override
  String get suggestionsErrorTitle => 'No feedback yet';

  @override
  String get suggestionsFailureUnsupported => 'Brew feedback isn\'t available on this device yet.';

  @override
  String get suggestionsFailureRequest => 'Couldn\'t get brew feedback. Check your connection and try again.';

  @override
  String get suggestionsFailureInvalid => 'The feedback didn\'t come back in a form Cupward could read. Try again.';

  @override
  String get buttonFinish => 'Done';

  @override
  String suggestionsValueChangeSemantics(String parameter, String current, String suggested) {
    return '$parameter, from $current to $suggested';
  }

  @override
  String get parameterGrindSize => 'Grind size';

  @override
  String get parameterCoffeeDose => 'Coffee';

  @override
  String get parameterWaterAmount => 'Water';

  @override
  String get parameterBloomWater => 'Bloom water';

  @override
  String get parameterBloomTime => 'Bloom time';

  @override
  String get parameterPourRate => 'Pour rate';

  @override
  String get parameterWaterTemperature => 'Water temperature';

  @override
  String get parameterBrewTime => 'Brew time';

  @override
  String get directionMore => 'More';

  @override
  String get directionLess => 'Less';

  @override
  String get directionFiner => 'Finer';

  @override
  String get directionCoarser => 'Coarser';

  @override
  String get directionLonger => 'Longer';

  @override
  String get directionShorter => 'Shorter';

  @override
  String get directionFaster => 'Faster';

  @override
  String get directionSlower => 'Slower';

  @override
  String get directionHotter => 'Hotter';

  @override
  String get directionCooler => 'Cooler';

  @override
  String get buttonApplySuggestion => 'Update my recipe';

  @override
  String get suggestionApplied => 'Saved to your recipe';

  @override
  String suggestionAppliedMessage(String parameter, String value) {
    return 'Recipe updated: $parameter $value';
  }

  @override
  String get suggestionApplyFailed => 'Couldn\'t update your recipe. Try again.';

  @override
  String get recipeMenuTooltip => 'Recipe options';

  @override
  String get recipeMenuNewRecipe => 'New recipe';

  @override
  String get newRecipeTitle => 'New Recipe';

  @override
  String get newRecipeIntro => 'Pick how you\'ll brew, then tell Cupward how you like your coffee.';

  @override
  String get newRecipeMethodTitle => 'Brewing method';

  @override
  String get newRecipeTasteTitle => 'Your taste';

  @override
  String get newRecipePreferencesLabel => 'How do you like your coffee?';

  @override
  String get newRecipePreferencesHint =>
      'For example: a strong cup from a medium-dark roast, about 350 ml, with more body than brightness.';

  @override
  String get newRecipeTopicsLabel => 'Things you might mention';

  @override
  String get newRecipeTopicStrength => 'Strength';

  @override
  String get newRecipeTopicRoast => 'Roast';

  @override
  String get newRecipeTopicCupSize => 'Cup size';

  @override
  String get newRecipeTopicBody => 'Body or clean';

  @override
  String get newRecipeTopicSweetness => 'Sweetness';

  @override
  String get newRecipeTopicAcidity => 'Acidity';

  @override
  String get buttonCreateRecipe => 'Create recipe';

  @override
  String get newRecipeNeedsInput => 'Pick a brewing method and describe your taste to continue.';

  @override
  String brewMethodTime(String minutes) {
    return 'About $minutes min';
  }

  @override
  String brewMethodSelectedSemantics(String method) {
    return '$method, selected';
  }

  @override
  String get brewMethodV60 => 'V60';

  @override
  String get brewMethodV60Description => 'Cone dripper for a bright, clean cup.';

  @override
  String get brewMethodKalitaWave => 'Kalita Wave';

  @override
  String get brewMethodKalitaWaveDescription => 'Flat-bottom dripper for an even, sweet cup.';

  @override
  String get brewMethodChemex => 'Chemex';

  @override
  String get brewMethodChemexDescription => 'Thick filter for a very clean, delicate cup.';

  @override
  String get brewMethodFrenchPress => 'French press';

  @override
  String get brewMethodFrenchPressDescription => 'Full immersion for a rich, heavy cup.';

  @override
  String get brewMethodAeroPress => 'AeroPress';

  @override
  String get brewMethodAeroPressDescription => 'A short steep, pressed, for a concentrated cup.';

  @override
  String get brewMethodCleverDripper => 'Clever Dripper';

  @override
  String get brewMethodCleverDripperDescription => 'Steep, then drain, for a forgiving, balanced cup.';
}
