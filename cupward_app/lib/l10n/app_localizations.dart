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
