// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The title of the application, also shown as the large title on the home screen
  ///
  /// In en, this message translates to:
  /// **'Cupward'**
  String get appTitle;

  /// Label for the primary button at the bottom of the home screen that starts a new brewing session
  ///
  /// In en, this message translates to:
  /// **'Start a Brew'**
  String get buttonStartBrew;

  /// Caption under the coffee dose in the recipe summary card, such as under "20.0 g"
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get recipeCoffeeLabel;

  /// Caption under the water weight in the recipe summary card
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get recipeWaterLabel;

  /// Caption under the target brew time in the recipe summary card, such as under "3:00"
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get recipeBrewTimeLabel;

  /// Caption under the approximate amount of coffee the recipe makes in the recipe summary card
  ///
  /// In en, this message translates to:
  /// **'Yield'**
  String get recipeYieldLabel;

  /// A weight in grams in the recipe summary card, such as "20.0 g". The number is already formatted for the locale.
  ///
  /// In en, this message translates to:
  /// **'{grams} g'**
  String recipeGrams(String grams);

  /// The approximate amount of coffee a recipe makes, in milliliters, such as "~320 ml". The tilde marks it as an estimate.
  ///
  /// In en, this message translates to:
  /// **'~{milliliters} ml'**
  String recipeYieldMilliliters(String milliliters);

  /// Name of the phase of a brew in which the user sets up and tares the scale, shown in the phase indicator
  ///
  /// In en, this message translates to:
  /// **'Prepare'**
  String get brewPhasePrepare;

  /// Name of the first, small pour that wets the coffee grounds, shown in the phase indicator
  ///
  /// In en, this message translates to:
  /// **'Bloom'**
  String get brewPhaseBloom;

  /// Name of one of a recipe's pours, numbered in order, shown in the phase indicator, such as "Pour 2"
  ///
  /// In en, this message translates to:
  /// **'Pour {number}'**
  String brewPhasePour(int number);

  /// Name of the final phase of a brew, shown in the phase indicator
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get brewPhaseComplete;

  /// What screen readers announce for the phase indicator, such as "Step 2 of 6, Bloom"
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}, {phase}'**
  String brewPhaseProgress(int current, int total, String phase);

  /// Small, spaced capital label above the current step's title on the brewing screen, such as "STEP 1 OF 6". Written in capitals here because the design shows it that way.
  ///
  /// In en, this message translates to:
  /// **'STEP {current} OF {total}'**
  String brewStepCount(int current, int total);

  /// Large title of the setup step of a brew
  ///
  /// In en, this message translates to:
  /// **'Prepare to Brew'**
  String get brewStepTitlePrepare;

  /// Large title of the bloom step, the first small pour that wets the coffee grounds
  ///
  /// In en, this message translates to:
  /// **'Bloom'**
  String get brewStepTitleBloom;

  /// Large title of one of a recipe's pours, numbered in order, such as "Pour 2"
  ///
  /// In en, this message translates to:
  /// **'Pour {number}'**
  String brewStepTitlePour(int number);

  /// Large title of the final step of a brew, after the water has drained through
  ///
  /// In en, this message translates to:
  /// **'Enjoy Your Coffee'**
  String get brewStepTitleComplete;

  /// Short reminder under the title of the setup step. Kept brief because the user is brewing and has done it before.
  ///
  /// In en, this message translates to:
  /// **'Set up your brewer, place it on the scale, and tare.'**
  String get brewStepInstructionsPrepare;

  /// Short reminder under the title of the bloom step
  ///
  /// In en, this message translates to:
  /// **'Wet all the grounds with a little water, then let them rest.'**
  String get brewStepInstructionsBloom;

  /// Short reminder under the title of each pour step
  ///
  /// In en, this message translates to:
  /// **'Pour slowly and evenly to the next target.'**
  String get brewStepInstructionsPour;

  /// Short reminder under the title of the final step of a brew
  ///
  /// In en, this message translates to:
  /// **'Let it finish draining, then swirl and serve.'**
  String get brewStepInstructionsComplete;

  /// Line under the instructions of a step that has a weight target, such as "Target 160 g". The weight is the total on the scale, counting all the water poured so far.
  ///
  /// In en, this message translates to:
  /// **'Target {weight} g'**
  String brewStepTarget(String weight);

  /// Label of the main button at the bottom of the brewing screen during the setup step. Tapping it tares the scale and starts the brew.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get brewActionContinue;

  /// Label of the main button at the bottom of the brewing screen during the bloom and pours. Tapping it moves to the next step.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get brewActionNextStep;

  /// Label of the main button at the bottom of the brewing screen during the final step. Tapping it leaves the brewing screen.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get brewActionDone;

  /// Message above the main button while the brew is about to move to the next step by itself, such as "Next step in 3". The user can cancel until it reaches zero.
  ///
  /// In en, this message translates to:
  /// **'Next step in {seconds}'**
  String brewAdvanceCountdown(int seconds);

  /// Label of the button next to the countdown that stops the brew from moving to the next step by itself
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get brewAdvanceCancel;

  /// Message above the main button while the grounds rest after the bloom water is added, such as "Rest 0:32"
  ///
  /// In en, this message translates to:
  /// **'Rest {time}'**
  String brewRestRemaining(String time);

  /// Heading of the scale panel on the brewing screen
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get scaleTitle;

  /// Status in the scale panel while a scale is connected
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get scaleStatusConnected;

  /// Status in the scale panel while no scale is connected
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get scaleStatusDisconnected;

  /// Status in the scale panel while the app looks for nearby scales
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get scaleStatusScanning;

  /// Status in the scale panel while the app connects to the chosen scale
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get scaleStatusConnecting;

  /// Status in the scale panel on platforms that cannot use Bluetooth scales, such as a web browser
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get scaleStatusUnsupported;

  /// The scale's remaining battery charge, shown beside a battery icon, such as "82%"
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String scaleBattery(int percent);

  /// What screen readers announce for the scale's battery level
  ///
  /// In en, this message translates to:
  /// **'Scale battery {percent} percent'**
  String scaleBatterySemantics(int percent);

  /// The scale's live weight, such as "0.0 g". The number is already formatted.
  ///
  /// In en, this message translates to:
  /// **'{grams} g'**
  String scaleGrams(String grams);

  /// The rate at which water is being poured, in grams per second, such as "3.2 g/s"
  ///
  /// In en, this message translates to:
  /// **'{rate} g/s'**
  String scaleFlowRate(String rate);

  /// Caption under the pour rate in the scale panel
  ///
  /// In en, this message translates to:
  /// **'Flow'**
  String get scaleFlowLabel;

  /// Placeholder for a scale value when no scale is connected or no reading has arrived
  ///
  /// In en, this message translates to:
  /// **'–'**
  String get scaleNoReading;

  /// Label of the button that zeroes the scale, shown in the scale panel during setup
  ///
  /// In en, this message translates to:
  /// **'Tare'**
  String get buttonTare;

  /// Label of the button in the scale panel that starts looking for nearby BOOKOO scales
  ///
  /// In en, this message translates to:
  /// **'Find scale'**
  String get buttonFindScale;

  /// Title of the sheet that lists nearby BOOKOO scales
  ///
  /// In en, this message translates to:
  /// **'Choose your scale'**
  String get scalePickerTitle;

  /// Shown in the scale sheet while searching and nothing has been found yet
  ///
  /// In en, this message translates to:
  /// **'Looking for BOOKOO scales. Make sure yours is on and nearby.'**
  String get scalePickerSearching;

  /// Shown in the scale sheet when a search ended without finding a scale
  ///
  /// In en, this message translates to:
  /// **'No scales found. Wake your scale, then search again.'**
  String get scalePickerNoneFound;

  /// Signal strength of a nearby scale in the scale sheet, such as "Signal -58 dBm"
  ///
  /// In en, this message translates to:
  /// **'Signal {rssi} dBm'**
  String scalePickerSignal(int rssi);

  /// Button in the scale sheet that restarts the search for scales
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get buttonSearchAgain;

  /// Shown when the scale search failed because Bluetooth is off or not permitted
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth and allow Cupward to use it, then try again.'**
  String get scaleFailureBluetooth;

  /// Shown when connecting to the chosen scale failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect to the scale. Make sure it\'s on and nearby.'**
  String get scaleFailureConnection;

  /// Shown when the chosen device connected but is not a supported BOOKOO scale
  ///
  /// In en, this message translates to:
  /// **'That device isn\'t a supported scale.'**
  String get scaleFailureUnsupported;

  /// Shown for any other scale failure
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with the scale. Try again.'**
  String get scaleFailureUnknown;

  /// Shown briefly when the tare command could not be sent
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t tare the scale.'**
  String get scaleTareFailed;

  /// Heading of the home screen panel about the on-device AI model
  ///
  /// In en, this message translates to:
  /// **'On-device AI'**
  String get modelTitle;

  /// Status in the on-device AI panel while the app checks whether the device has an on-device model
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get modelStatusChecking;

  /// Status in the on-device AI panel when the on-device model is installed
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get modelStatusReady;

  /// Status in the on-device AI panel when the on-device model can be downloaded but is not installed
  ///
  /// In en, this message translates to:
  /// **'Not downloaded'**
  String get modelStatusDownloadable;

  /// Status in the on-device AI panel while the on-device model downloads
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get modelStatusDownloading;

  /// Status in the on-device AI panel when the device or browser cannot run an on-device model
  ///
  /// In en, this message translates to:
  /// **'Not supported'**
  String get modelStatusUnavailable;

  /// Status in the on-device AI panel when the check for the on-device model failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check'**
  String get modelStatusUnknown;

  /// Explanation in the on-device AI panel while checking
  ///
  /// In en, this message translates to:
  /// **'Checking whether brew feedback can run on this device.'**
  String get modelMessageChecking;

  /// Explanation in the on-device AI panel when the on-device model is installed
  ///
  /// In en, this message translates to:
  /// **'Brew feedback runs on this device, even offline.'**
  String get modelMessageReady;

  /// Explanation in the on-device AI panel when the model can be downloaded
  ///
  /// In en, this message translates to:
  /// **'Download the model for brew feedback on this device, even offline. Until then, it comes from the cloud.'**
  String get modelMessageDownloadable;

  /// Explanation in the on-device AI panel while the model downloads
  ///
  /// In en, this message translates to:
  /// **'Brew feedback comes from the cloud until the download finishes. You can start brewing now.'**
  String get modelMessageDownloading;

  /// Explanation in the on-device AI panel when the device cannot run an on-device model
  ///
  /// In en, this message translates to:
  /// **'This device can\'t run an on-device model, so brew feedback comes from the cloud.'**
  String get modelMessageUnavailable;

  /// Explanation in the on-device AI panel when the check failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for the on-device model. Brew feedback will come from the cloud.'**
  String get modelMessageUnknown;

  /// Shown in the on-device AI panel when a model download failed
  ///
  /// In en, this message translates to:
  /// **'The download didn\'t finish. Check your connection and try again.'**
  String get modelDownloadFailed;

  /// How much of the on-device model has downloaded, such as "42%"
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String modelDownloadProgress(int percent);

  /// What screen readers announce for the model download progress
  ///
  /// In en, this message translates to:
  /// **'Model download {percent} percent'**
  String modelDownloadProgressSemantics(int percent);

  /// Label of the button in the on-device AI panel that downloads the on-device model
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get buttonDownloadModel;

  /// Label of the button in the on-device AI panel that repeats a failed check
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get buttonTryAgain;

  /// Heading of the card on the feedback screen that summarizes the brew that just finished
  ///
  /// In en, this message translates to:
  /// **'Your brew'**
  String get brewSummaryTitle;

  /// Caption under the fastest pour rate of the brew
  ///
  /// In en, this message translates to:
  /// **'Peak flow'**
  String get brewSummaryPeakFlowLabel;

  /// The recipe target shown under a measured value, such as "Target 320 g"
  ///
  /// In en, this message translates to:
  /// **'Target {value}'**
  String brewSummaryTarget(String value);

  /// Shown in place of the weight chart when the brew had no scale readings
  ///
  /// In en, this message translates to:
  /// **'No scale was connected, so this brew has step times but no weights.'**
  String get brewSummaryNoReadings;

  /// What screen readers announce for the weight chart, such as "Weight over time. 318 g after 3:12."
  ///
  /// In en, this message translates to:
  /// **'Weight over time. {weight} after {time}.'**
  String brewSummaryChartSemantics(String weight, String time);

  /// Column heading for the step names in the brew summary table
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get brewSummaryStepHeader;

  /// Column heading for how long each step took in the brew summary table
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get brewSummaryTimeHeader;

  /// Column heading for the weight at the end of each step in the brew summary table
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get brewSummaryWeightHeader;

  /// Column heading for each step's target weight in the brew summary table
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get brewSummaryTargetHeader;

  /// Heading of the card on the feedback screen where the user describes how the brew tasted
  ///
  /// In en, this message translates to:
  /// **'Tasting notes'**
  String get tastingNotesTitle;

  /// Short explanation at the top of the tasting notes card
  ///
  /// In en, this message translates to:
  /// **'Rate what you tasted. Skip anything you\'re not sure about.'**
  String get tastingNotesIntro;

  /// Shown beside a taste slider that the user has not moved yet
  ///
  /// In en, this message translates to:
  /// **'Not rated'**
  String get tastingNotRated;

  /// What screen readers announce for a taste slider's value, such as "4 of 5"
  ///
  /// In en, this message translates to:
  /// **'{rating} of {max}'**
  String tastingRatingSemantics(int rating, int max);

  /// Name of the taste slider for how strong and concentrated the coffee tastes
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get tasteIntensity;

  /// Label at the low end of the taste slider for how strong and concentrated the coffee tastes
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get tasteIntensityLow;

  /// Label at the high end of the taste slider for how strong and concentrated the coffee tastes
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get tasteIntensityHigh;

  /// Name of the taste slider for how bright or sour the coffee tastes
  ///
  /// In en, this message translates to:
  /// **'Acidity'**
  String get tasteAcidity;

  /// Label at the low end of the taste slider for how bright or sour the coffee tastes
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get tasteAcidityLow;

  /// Label at the high end of the taste slider for how bright or sour the coffee tastes
  ///
  /// In en, this message translates to:
  /// **'Bright'**
  String get tasteAcidityHigh;

  /// Name of the taste slider for how sweet the coffee tastes
  ///
  /// In en, this message translates to:
  /// **'Sweetness'**
  String get tasteSweetness;

  /// Label at the low end of the taste slider for how sweet the coffee tastes
  ///
  /// In en, this message translates to:
  /// **'Not sweet'**
  String get tasteSweetnessLow;

  /// Label at the high end of the taste slider for how sweet the coffee tastes
  ///
  /// In en, this message translates to:
  /// **'Very sweet'**
  String get tasteSweetnessHigh;

  /// Name of the taste slider for how bitter the coffee tastes
  ///
  /// In en, this message translates to:
  /// **'Bitterness'**
  String get tasteBitterness;

  /// Label at the low end of the taste slider for how bitter the coffee tastes
  ///
  /// In en, this message translates to:
  /// **'Not bitter'**
  String get tasteBitternessLow;

  /// Label at the high end of the taste slider for how bitter the coffee tastes
  ///
  /// In en, this message translates to:
  /// **'Very bitter'**
  String get tasteBitternessHigh;

  /// Name of the taste slider for how heavy the coffee feels in the mouth
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get tasteBody;

  /// Label at the low end of the taste slider for how heavy the coffee feels in the mouth
  ///
  /// In en, this message translates to:
  /// **'Thin'**
  String get tasteBodyLow;

  /// Label at the high end of the taste slider for how heavy the coffee feels in the mouth
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get tasteBodyHigh;

  /// Name of the taste slider for how dry and puckering the finish feels
  ///
  /// In en, this message translates to:
  /// **'Astringency'**
  String get tasteAstringency;

  /// Label at the low end of the taste slider for how dry and puckering the finish feels
  ///
  /// In en, this message translates to:
  /// **'Smooth'**
  String get tasteAstringencyLow;

  /// Label at the high end of the taste slider for how dry and puckering the finish feels
  ///
  /// In en, this message translates to:
  /// **'Drying'**
  String get tasteAstringencyHigh;

  /// Name of the taste slider for how much the user enjoyed the coffee
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get tasteOverall;

  /// Label at the low end of the taste slider for how much the user enjoyed the coffee
  ///
  /// In en, this message translates to:
  /// **'Disliked'**
  String get tasteOverallLow;

  /// Label at the high end of the taste slider for how much the user enjoyed the coffee
  ///
  /// In en, this message translates to:
  /// **'Loved it'**
  String get tasteOverallHigh;

  /// Label of the text field where the user describes how they want the next brew to taste
  ///
  /// In en, this message translates to:
  /// **'What would you change next time?'**
  String get tastingGoalLabel;

  /// Hint text in the empty tasting goal field
  ///
  /// In en, this message translates to:
  /// **'For example: a little sweeter, with less bitterness.'**
  String get tastingGoalHint;

  /// Label of the button on the feedback screen that sends the brew and tasting notes to brew feedback
  ///
  /// In en, this message translates to:
  /// **'Get brew feedback'**
  String get buttonGetFeedback;

  /// Shown under the disabled feedback button until the user has filled in part of the tasting notes
  ///
  /// In en, this message translates to:
  /// **'Rate at least one thing, or say what you\'d change, to get feedback.'**
  String get feedbackNeedsNotes;

  /// Heading shown while brew feedback is being prepared
  ///
  /// In en, this message translates to:
  /// **'Tasting your brew'**
  String get suggestionsLoadingTitle;

  /// Explanation shown while brew feedback is being prepared
  ///
  /// In en, this message translates to:
  /// **'Reviewing your readings and tasting notes. This can take a few seconds.'**
  String get suggestionsLoadingMessage;

  /// Heading of the summary card on the brew feedback screen
  ///
  /// In en, this message translates to:
  /// **'Your next brew'**
  String get suggestionsTitle;

  /// Badge saying the feedback was produced by the AI model on the device
  ///
  /// In en, this message translates to:
  /// **'On-device AI'**
  String get suggestionsSourceOnDevice;

  /// Badge saying the feedback was produced by the AI model in the cloud
  ///
  /// In en, this message translates to:
  /// **'Cloud AI'**
  String get suggestionsSourceCloud;

  /// Small spaced label above the main suggested change
  ///
  /// In en, this message translates to:
  /// **'TRY THIS NEXT'**
  String get suggestionsPrimaryEyebrow;

  /// Caption above the reason for a suggested change
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get suggestionsWhyLabel;

  /// Caption above how the next cup should taste after a suggested change
  ///
  /// In en, this message translates to:
  /// **'What to expect'**
  String get suggestionsEffectLabel;

  /// Note under the main suggestion explaining why only one change is recommended
  ///
  /// In en, this message translates to:
  /// **'Change one thing at a time, so you can taste what it does.'**
  String get suggestionsOneChangeNote;

  /// Heading of the list of other changes to try in later brews
  ///
  /// In en, this message translates to:
  /// **'Ideas for later brews'**
  String get suggestionsAlternativesTitle;

  /// Heading shown when brew feedback could not be produced
  ///
  /// In en, this message translates to:
  /// **'No feedback yet'**
  String get suggestionsErrorTitle;

  /// Shown when the platform cannot run brew feedback
  ///
  /// In en, this message translates to:
  /// **'Brew feedback isn\'t available on this device yet.'**
  String get suggestionsFailureUnsupported;

  /// Shown when the brew feedback request failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get brew feedback. Check your connection and try again.'**
  String get suggestionsFailureRequest;

  /// Shown when the AI answer could not be read
  ///
  /// In en, this message translates to:
  /// **'The feedback didn\'t come back in a form Cupward could read. Try again.'**
  String get suggestionsFailureInvalid;

  /// Label of the button on the brew feedback screen that returns to the home screen
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get buttonFinish;

  /// What screen readers announce for a suggested value change, such as "Coffee, from 20 g to 21 g"
  ///
  /// In en, this message translates to:
  /// **'{parameter}, from {current} to {suggested}'**
  String suggestionsValueChangeSemantics(String parameter, String current, String suggested);

  /// Name of the brewing variable for how fine the coffee is ground, shown on a suggested change
  ///
  /// In en, this message translates to:
  /// **'Grind size'**
  String get parameterGrindSize;

  /// Name of the brewing variable for the weight of coffee, shown on a suggested change
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get parameterCoffeeDose;

  /// Name of the brewing variable for the total weight of water, shown on a suggested change
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get parameterWaterAmount;

  /// Name of the brewing variable for the weight of water in the bloom, shown on a suggested change
  ///
  /// In en, this message translates to:
  /// **'Bloom water'**
  String get parameterBloomWater;

  /// Name of the brewing variable for how long the bloom rests, shown on a suggested change
  ///
  /// In en, this message translates to:
  /// **'Bloom time'**
  String get parameterBloomTime;

  /// Name of the brewing variable for how quickly water is poured, shown on a suggested change
  ///
  /// In en, this message translates to:
  /// **'Pour rate'**
  String get parameterPourRate;

  /// Name of the brewing variable for the temperature of the water, shown on a suggested change
  ///
  /// In en, this message translates to:
  /// **'Water temperature'**
  String get parameterWaterTemperature;

  /// Name of the brewing variable for the total brew time, shown on a suggested change
  ///
  /// In en, this message translates to:
  /// **'Brew time'**
  String get parameterBrewTime;

  /// Name of the brewing variable for how long an immersion brew steeps, shown on a suggested change
  ///
  /// In en, this message translates to:
  /// **'Steep time'**
  String get parameterSteepTime;

  /// Which way a suggested change goes, for more of an amount
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get directionMore;

  /// Which way a suggested change goes, for less of an amount
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get directionLess;

  /// Which way a suggested change goes, for a finer grind
  ///
  /// In en, this message translates to:
  /// **'Finer'**
  String get directionFiner;

  /// Which way a suggested change goes, for a coarser grind
  ///
  /// In en, this message translates to:
  /// **'Coarser'**
  String get directionCoarser;

  /// Which way a suggested change goes, for a longer time
  ///
  /// In en, this message translates to:
  /// **'Longer'**
  String get directionLonger;

  /// Which way a suggested change goes, for a shorter time
  ///
  /// In en, this message translates to:
  /// **'Shorter'**
  String get directionShorter;

  /// Which way a suggested change goes, for a faster pour
  ///
  /// In en, this message translates to:
  /// **'Faster'**
  String get directionFaster;

  /// Which way a suggested change goes, for a slower pour
  ///
  /// In en, this message translates to:
  /// **'Slower'**
  String get directionSlower;

  /// Which way a suggested change goes, for hotter water
  ///
  /// In en, this message translates to:
  /// **'Hotter'**
  String get directionHotter;

  /// Which way a suggested change goes, for cooler water
  ///
  /// In en, this message translates to:
  /// **'Cooler'**
  String get directionCooler;

  /// Label of the button on a suggested change that saves the change to the recipe that was just brewed
  ///
  /// In en, this message translates to:
  /// **'Update my recipe'**
  String get buttonApplySuggestion;

  /// Shown on a suggested change after it was saved to the recipe
  ///
  /// In en, this message translates to:
  /// **'Saved to your recipe'**
  String get suggestionApplied;

  /// Brief confirmation after a suggested change is saved, such as "Recipe updated: Coffee 21.0 g"
  ///
  /// In en, this message translates to:
  /// **'Recipe updated: {parameter} {value}'**
  String suggestionAppliedMessage(String parameter, String value);

  /// Brief message when saving a suggested change to the recipe failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your recipe. Try again.'**
  String get suggestionApplyFailed;

  /// Tooltip and screen reader label of the menu button in the corner of the recipe card on the brewing screen
  ///
  /// In en, this message translates to:
  /// **'Recipe options'**
  String get recipeMenuTooltip;

  /// Menu item that opens the screen for creating a new recipe
  ///
  /// In en, this message translates to:
  /// **'New recipe'**
  String get recipeMenuNewRecipe;

  /// Tooltip and screen reader label of the menu button in the corner of the title card on the new recipe screen
  ///
  /// In en, this message translates to:
  /// **'Recipe creation options'**
  String get newRecipeMenuTooltip;

  /// Label of the switch in the new recipe menu that keeps the request on the device's own AI model, rather than also allowing the cloud model
  ///
  /// In en, this message translates to:
  /// **'Local AI only'**
  String get newRecipeMenuLocalOnly;

  /// Title of the screen for creating a new recipe
  ///
  /// In en, this message translates to:
  /// **'New Recipe'**
  String get newRecipeTitle;

  /// Short explanation under the title of the new recipe screen
  ///
  /// In en, this message translates to:
  /// **'Pick how you\'ll brew, then tell Cupward how you like your coffee.'**
  String get newRecipeIntro;

  /// Heading of the list of brewing methods on the new recipe screen
  ///
  /// In en, this message translates to:
  /// **'Brewing method'**
  String get newRecipeMethodTitle;

  /// Heading of the taste preferences section on the new recipe screen
  ///
  /// In en, this message translates to:
  /// **'Your taste'**
  String get newRecipeTasteTitle;

  /// Label of the text field for taste preferences on the new recipe screen
  ///
  /// In en, this message translates to:
  /// **'How do you like your coffee?'**
  String get newRecipePreferencesLabel;

  /// Hint text in the empty taste preferences field
  ///
  /// In en, this message translates to:
  /// **'For example: a strong cup from a medium-dark roast, about 350 ml, with more body than brightness.'**
  String get newRecipePreferencesHint;

  /// Caption above the tappable topics that start a line in the taste preferences field
  ///
  /// In en, this message translates to:
  /// **'Things you might mention'**
  String get newRecipeTopicsLabel;

  /// A topic chip under the taste preferences field; tapping it starts a line about strength
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get newRecipeTopicStrength;

  /// A topic chip under the taste preferences field; tapping it starts a line about roast
  ///
  /// In en, this message translates to:
  /// **'Roast'**
  String get newRecipeTopicRoast;

  /// A topic chip under the taste preferences field; tapping it starts a line about cup size
  ///
  /// In en, this message translates to:
  /// **'Cup size'**
  String get newRecipeTopicCupSize;

  /// A topic chip under the taste preferences field; tapping it starts a line about body or clean
  ///
  /// In en, this message translates to:
  /// **'Body or clean'**
  String get newRecipeTopicBody;

  /// A topic chip under the taste preferences field; tapping it starts a line about sweetness
  ///
  /// In en, this message translates to:
  /// **'Sweetness'**
  String get newRecipeTopicSweetness;

  /// A topic chip under the taste preferences field; tapping it starts a line about acidity
  ///
  /// In en, this message translates to:
  /// **'Acidity'**
  String get newRecipeTopicAcidity;

  /// Label of the button that creates a recipe from the chosen method and taste preferences
  ///
  /// In en, this message translates to:
  /// **'Create recipe'**
  String get buttonCreateRecipe;

  /// Shown under the disabled create button until the form is filled in
  ///
  /// In en, this message translates to:
  /// **'Pick a brewing method and describe your taste to continue.'**
  String get newRecipeNeedsInput;

  /// Typical brew time on a brewing method card, such as "About 3 min"
  ///
  /// In en, this message translates to:
  /// **'About {minutes} min'**
  String brewMethodTime(String minutes);

  /// What screen readers announce for the chosen brewing method
  ///
  /// In en, this message translates to:
  /// **'{method}, selected'**
  String brewMethodSelectedSemantics(String method);

  /// Name of the V60 brewing method
  ///
  /// In en, this message translates to:
  /// **'V60'**
  String get brewMethodV60;

  /// One-line description of the V60 brewing method on its card
  ///
  /// In en, this message translates to:
  /// **'Cone dripper for a bright, clean cup.'**
  String get brewMethodV60Description;

  /// Name of the Kalita Wave brewing method
  ///
  /// In en, this message translates to:
  /// **'Kalita Wave'**
  String get brewMethodKalitaWave;

  /// One-line description of the Kalita Wave brewing method on its card
  ///
  /// In en, this message translates to:
  /// **'Flat-bottom dripper for an even, sweet cup.'**
  String get brewMethodKalitaWaveDescription;

  /// Name of the Chemex brewing method
  ///
  /// In en, this message translates to:
  /// **'Chemex'**
  String get brewMethodChemex;

  /// One-line description of the Chemex brewing method on its card
  ///
  /// In en, this message translates to:
  /// **'Thick filter for a very clean, delicate cup.'**
  String get brewMethodChemexDescription;

  /// Name of the French press brewing method
  ///
  /// In en, this message translates to:
  /// **'French press'**
  String get brewMethodFrenchPress;

  /// One-line description of the French press brewing method on its card
  ///
  /// In en, this message translates to:
  /// **'Full immersion for a rich, heavy cup.'**
  String get brewMethodFrenchPressDescription;

  /// Name of the AeroPress brewing method
  ///
  /// In en, this message translates to:
  /// **'AeroPress'**
  String get brewMethodAeroPress;

  /// One-line description of the AeroPress brewing method on its card
  ///
  /// In en, this message translates to:
  /// **'A short steep, pressed, for a concentrated cup.'**
  String get brewMethodAeroPressDescription;

  /// Name of the Clever Dripper brewing method
  ///
  /// In en, this message translates to:
  /// **'Clever Dripper'**
  String get brewMethodCleverDripper;

  /// One-line description of the Clever Dripper brewing method on its card
  ///
  /// In en, this message translates to:
  /// **'Steep, then drain, for a forgiving, balanced cup.'**
  String get brewMethodCleverDripperDescription;

  /// Short name of the steeping phase in the phase indicator, used by immersion methods such as the French press
  ///
  /// In en, this message translates to:
  /// **'Steep'**
  String get brewPhaseSteep;

  /// Large title of the steeping step
  ///
  /// In en, this message translates to:
  /// **'Steep'**
  String get brewStepTitleSteep;

  /// One-sentence instructions for the steeping step
  ///
  /// In en, this message translates to:
  /// **'Let the coffee steep, then press or drain it.'**
  String get brewStepInstructionsSteep;

  /// Heading shown while a new recipe is being created
  ///
  /// In en, this message translates to:
  /// **'Creating your recipe'**
  String get newRecipeCreatingTitle;

  /// Explanation shown while a new recipe is being created
  ///
  /// In en, this message translates to:
  /// **'Building a {method} recipe around your taste. This can take a few seconds.'**
  String newRecipeCreatingMessage(String method);

  /// Heading shown when a new recipe could not be created
  ///
  /// In en, this message translates to:
  /// **'No recipe yet'**
  String get newRecipeErrorTitle;

  /// Shown when the platform cannot create recipes with AI
  ///
  /// In en, this message translates to:
  /// **'Creating recipes isn\'t available on this device yet.'**
  String get newRecipeFailureUnsupported;

  /// Shown when the request to create a recipe failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create a recipe. Check your connection and try again.'**
  String get newRecipeFailureRequest;

  /// Shown when the AI answer could not be turned into a recipe
  ///
  /// In en, this message translates to:
  /// **'The recipe didn\'t come back in a form Cupward could use. Try again.'**
  String get newRecipeFailureInvalid;

  /// Shown when the new recipe could not be saved
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the new recipe. Check your connection and try again.'**
  String get newRecipeFailureSave;

  /// Shown when the new recipe's name and every numbered version of it are already used
  ///
  /// In en, this message translates to:
  /// **'You already have recipes with this name. Try again for a different one.'**
  String get newRecipeFailureNameTaken;

  /// Label of the button that returns from a failed recipe request to the form
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get buttonEditRequest;

  /// Brief confirmation on the brewing screen after a new recipe was created, such as "Bold Morning Kalita is ready to brew"
  ///
  /// In en, this message translates to:
  /// **'{name} is ready to brew'**
  String recipeCreatedMessage(String name);

  /// Menu item on the brewing screen that opens the list of the user's recipes, offered only before the brew starts
  ///
  /// In en, this message translates to:
  /// **'Change recipe'**
  String get buttonChangeRecipe;

  /// Title of the screen that lists the user's recipes so they can choose the one to brew
  ///
  /// In en, this message translates to:
  /// **'Choose a recipe'**
  String get recipePickerTitle;

  /// Short explanation under the title of the recipe list screen
  ///
  /// In en, this message translates to:
  /// **'Pick the recipe you want to brew. You can\'t change it once the brew has started.'**
  String get recipePickerIntro;

  /// Tooltip and screen reader label of the button that closes the recipe list screen without choosing a recipe
  ///
  /// In en, this message translates to:
  /// **'Close without changing the recipe'**
  String get recipePickerCloseTooltip;

  /// Screen reader label of the check mark on the recipe that is already on the brewing screen
  ///
  /// In en, this message translates to:
  /// **'Current recipe'**
  String get recipePickerCurrent;

  /// Heading of the card shown while the user's recipes load
  ///
  /// In en, this message translates to:
  /// **'Finding your recipes'**
  String get recipePickerLoadingTitle;

  /// Message of the card shown while the user's recipes load
  ///
  /// In en, this message translates to:
  /// **'This only takes a moment.'**
  String get recipePickerLoadingMessage;

  /// Heading of the card shown when the user's recipes could not be loaded
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your recipes'**
  String get recipePickerErrorTitle;

  /// Message of the card shown when the user's recipes could not be loaded
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get recipePickerErrorMessage;

  /// Brief confirmation on the brewing screen after the user chose a different recipe, such as "Now brewing Sweet Press"
  ///
  /// In en, this message translates to:
  /// **'Now brewing {name}'**
  String recipeSelectedMessage(String name);

  /// Menu item on the brewing screen that starts demo mode, in which scale readings are simulated so the app can be tried without a scale
  ///
  /// In en, this message translates to:
  /// **'Start demo'**
  String get recipeMenuStartDemo;

  /// Menu item on the brewing screen that ends demo mode
  ///
  /// In en, this message translates to:
  /// **'End demo'**
  String get recipeMenuEndDemo;

  /// Brief confirmation on the brewing screen after demo mode starts
  ///
  /// In en, this message translates to:
  /// **'Demo started. The scale readings are simulated.'**
  String get demoStartedMessage;

  /// Short tag beside the scale panel's heading in demo mode. Shown in capitals
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get scaleDemoBadge;

  /// Screen reader label of the demo tag in the scale panel
  ///
  /// In en, this message translates to:
  /// **'Demo mode, simulated scale'**
  String get scaleDemoSemanticLabel;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError('AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
