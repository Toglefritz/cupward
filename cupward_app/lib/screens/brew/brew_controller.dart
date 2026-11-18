import 'dart:async';

import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:material_ui/material_ui.dart';

import '../../components/app_snack_bars.dart';
import '../../l10n/app_localizations.dart';
import '../../models/brews/brew_record.dart';
import '../../models/recipes/brew_phase.dart';
import '../../models/recipes/brew_phase_kind.dart';
import '../../models/recipes/brew_recipe.dart';
import '../../services/brew/brew_recorder.dart';
import '../../services/brew/phase_advance_progress.dart';
import '../../services/brew/phase_advance_tracker.dart';
import '../../services/recipes/recipe_repository.dart';
import '../../services/scale/scale_connection_status.dart';
import '../../services/scale/scale_service.dart';
import '../feedback/feedback_route.dart';
import '../new_recipe/new_recipe_route.dart';
import 'brew_route.dart';
import 'brew_view.dart';
import 'components/scale_picker_sheet.dart';

/// State and behavior for [BrewRoute].
///
/// The scale connection belongs to the app-wide [ScaleService], so a scale connected during an earlier brew is still
/// connected here, and the screen opens straight to its readings. The controller rebuilds the screen whenever the
/// service notifies.
///
/// While a scale is connected, the controller also moves the brew along by itself. A `PhaseAdvanceTracker` follows the
/// readings for the current phase, and when the phase is finished the controller opens a short window, of
/// [advanceWindow], in which the screen offers to cancel. When the window ends the brew moves to the next phase.
/// Cancelling, or tapping the main button, hands the phase back to the user. Without a connected scale none of this
/// runs, and the button is the only way to advance.
///
/// The controller also records the brew with a [BrewRecorder]: when each phase began, and every scale reading from the
/// moment the user leaves preparation. When the user taps Done, the record is handed to the feedback screen, which
/// replaces this one.
///
/// The recipe menu also starts and ends demo mode, in which [ScaleService] simulates a connected scale. Starting it
/// starts the brew again, and each phase tells the simulated scale how much water to pour, so the demo brews the recipe
/// as a person with a real scale would, while the screen follows it exactly as it follows a real scale.
///
/// Creating a recipe from the recipe menu switches the screen to it: the brew starts again from the new recipe's first
/// step, the recipe becomes the chosen one in [RecipeRepository], and a brief message confirms it.
class BrewController extends State<BrewRoute> {
  /// The recipe being brewed. It starts as the route's recipe and changes when the user creates a new one.
  BrewRecipe get recipe => _recipe;
  late BrewRecipe _recipe = widget.recipe;

  /// The position of the current phase in the recipe's phases. A brew starts at its first phase.
  int currentPhaseIndex = 0;

  /// The kind of the current phase.
  BrewPhaseKind get currentPhaseKind => recipe.phases[currentPhaseIndex].kind;

  /// The service that connects to and reads from the scale.
  ScaleService get scale => widget.scaleService ?? ScaleService.instance;

  /// Whether a scale can be used here. Browsers cannot connect to one over Bluetooth, so on the web the brew is followed
  /// without scale readings, unless demo mode simulates a scale.
  bool get isScaleSupported => scale.status != ScaleConnectionStatus.unsupported;

  /// How long the screen offers to cancel before the brew moves to the next phase by itself.
  static const Duration advanceWindow = Duration(seconds: 3);

  /// How often the clock is checked while a rest or the cancel window is running, so the countdowns on screen stay
  /// current between scale readings.
  static const Duration _tickInterval = Duration(milliseconds: 200);

  /// The current time. Tests replace it through [BrewRoute.now] to move time without waiting.
  DateTime _now() => (widget.now ?? DateTime.now)();

  /// Follows the scale readings for the current phase, or null while the scale is not being followed, such as when it
  /// is disconnected.
  PhaseAdvanceTracker? _tracker;

  /// What the tracker last concluded about the current phase.
  PhaseAdvanceProgress _progress = PhaseAdvanceProgress.waiting;

  /// When the cancel window ends, or null when it is not open.
  DateTime? _windowEndsAt;

  /// Whether the user cancelled the automatic advance for the current phase. It is cleared when the phase changes.
  bool _isAutoAdvanceCancelled = false;

  /// Drives the countdowns while a rest or the cancel window is running, and is null the rest of the time.
  Timer? _ticker;

  /// Records the phases and scale readings of this brew.
  late BrewRecorder _recorder;

  /// The time left in the current phase's rest, such as after the bloom water is added, or null if it is not
  /// resting.
  Duration? get restRemaining => _isFollowing ? _progress.restRemaining : null;

  /// The time left before the brew moves on by itself, or null if the cancel window is not open.
  Duration? get advanceRemaining {
    final DateTime? endsAt = _windowEndsAt;
    if (endsAt == null) {
      return null;
    }
    final Duration remaining = endsAt.difference(_now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Whether the scale is expected to end the current phase by itself, so the main button is only a manual override.
  ///
  /// This is false when no scale is connected, when the phase has nothing to measure, and after the user cancelled the
  /// automatic advance, because in each case the button is how the brew moves on.
  bool get isAdvancingAutomatically => _isFollowing;

  /// Whether the scale is being followed to advance the current phase.
  bool get _isFollowing => _tracker != null && scale.isConnected && !_isAutoAdvanceCancelled;

  @override
  void initState() {
    super.initState();
    scale.addListener(_onScaleChanged);
    _startBrew();
  }

  /// Starts brewing [recipe] from its first phase, with a new recording.
  void _startBrew() {
    // A new brew starts with an empty platter, on which the simulated brewer is soon set down.
    scale.resetDemo();
    currentPhaseIndex = 0;
    _recorder = BrewRecorder(recipe: recipe);
    _startPhase();

    // A brew normally starts when the user leaves preparation. A recipe without a preparation step starts at once.
    if (currentPhaseKind != BrewPhaseKind.prepare) {
      _recorder.start(_now(), recipe.phases[currentPhaseIndex]);
    }
  }

  /// Rebuilds the screen with the scale's latest state, and checks whether the phase is finished.
  void _onScaleChanged() {
    if (!mounted) {
      return;
    }
    final BookooScaleReading? reading = scale.reading;
    if (reading != null && scale.isConnected) {
      _recorder.addReading(reading, _now(), scaleName: scale.scaleName);
    }
    setState(() => _evaluate(reading));
  }

  /// Begins following the current phase with a new tracker, and forgets the state of the previous phase.
  void _startPhase() {
    // In demo mode, the simulated person at the kettle pours what the phase calls for, or waits if it calls for none.
    scale.simulatePourTo(recipe.phases[currentPhaseIndex].targetWeightGrams);
    _resetTracker();
    _windowEndsAt = null;
    _isAutoAdvanceCancelled = false;
    _stopTicker();
  }

  /// Replaces the tracker with a fresh one for the current phase, or with null if the phase has nothing to follow.
  void _resetTracker() {
    final PhaseAdvanceTracker tracker = PhaseAdvanceTracker(phase: recipe.phases[currentPhaseIndex]);
    _tracker = tracker.canAutoAdvance ? tracker : null;
    _progress = PhaseAdvanceProgress.waiting;
  }

  /// Feeds the tracker, opens or closes the cancel window, and advances when the window has ended.
  ///
  /// [reading] is a new scale reading, or null when only time has passed. Losing the scale closes the window, so the
  /// brew never advances on readings that stopped arriving.
  void _evaluate(BookooScaleReading? reading) {
    final PhaseAdvanceTracker? tracker = _tracker;
    if (tracker == null || _isAutoAdvanceCancelled || !scale.isConnected) {
      if (!scale.isConnected) {
        // Readings that came before the connection was lost say nothing about the weight after it returns.
        _resetTracker();
      }
      _windowEndsAt = null;
      _stopTicker();
      return;
    }

    final DateTime now = _now();
    _progress = tracker.update(now, reading: reading);

    if (!_progress.isReady) {
      // The pour started again, for example, so the window closes and the phase is followed again.
      _windowEndsAt = null;
    } else if (_windowEndsAt == null) {
      _windowEndsAt = now.add(advanceWindow);
    } else if (!now.isBefore(_windowEndsAt!)) {
      _advance();
      return;
    }

    if (_progress.restRemaining != null || _windowEndsAt != null) {
      _ticker ??= Timer.periodic(_tickInterval, (Timer _) => _onTick());
    } else {
      _stopTicker();
    }
  }

  /// Checks the clock between scale readings so rests and the cancel window end on time.
  void _onTick() {
    if (mounted) {
      setState(() => _evaluate(null));
    }
  }

  /// Stops the countdown timer.
  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Moves to the next phase, records it, and starts following it.
  ///
  /// Leaving preparation starts the recording, because the scale has just been tared and the brew begins.
  void _advance() {
    final bool isLeavingPreparation = currentPhaseKind == BrewPhaseKind.prepare;
    currentPhaseIndex++;

    final BrewPhase phase = recipe.phases[currentPhaseIndex];
    if (isLeavingPreparation && !_recorder.isRecording) {
      _recorder.start(_now(), phase);
    } else {
      _recorder.markPhase(phase, _now());
    }

    _startPhase();
  }

  /// Handles a tap on Cancel while the screen counts down to the next step.
  ///
  /// The phase stays as it is until the user taps the main button. Automatic advancing resumes in the next phase.
  void onCancelAdvancePressed() {
    setState(() {
      _isAutoAdvanceCancelled = true;
      _windowEndsAt = null;
      _stopTicker();
    });
  }

  /// Handles a tap on "Find scale" by starting a search and showing the scales it finds.
  ///
  /// If a search is already running, the sheet shows its results without restarting it. Closing the sheet without
  /// choosing a scale stops the search.
  Future<void> onFindScalePressed() async {
    unawaited(scale.startScan());

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => ScalePickerSheet(
        service: scale,
        onDeviceSelected: (ThemisUltraDevice device) => onScaleSelected(sheetContext, device),
        onSearchAgainPressed: onSearchAgainPressed,
      ),
    );

    await scale.stopScan();
  }

  /// Handles a tap on a scale in the sheet by connecting to it, and closes the sheet once connected.
  ///
  /// If the connection fails, the sheet stays open and shows why, so the user can try again.
  Future<void> onScaleSelected(BuildContext sheetContext, ThemisUltraDevice device) async {
    final bool connected = await scale.connect(device);

    if (connected && sheetContext.mounted) {
      Navigator.pop(sheetContext);
    }
  }

  /// Handles a tap on "Search again" in the sheet by starting a new search.
  void onSearchAgainPressed() {
    unawaited(scale.startScan());
  }

  /// Whether the current phase is the last one, so there is nothing after it to advance to.
  bool get isLastPhase => currentPhaseIndex == recipe.phases.length - 1;

  /// Handles a tap on the main action button at the bottom of the screen.
  ///
  /// This is also the manual route when the scale is not driving the brew, and it takes over from a countdown that
  /// is running. In the last phase this ends the brew and opens the feedback screen in place of this one, so going back
  /// from there returns to the home screen. In any other phase it moves to the next one. Leaving the preparation
  /// phase first tares the scale, so the weights in the later phases count water only. If the tare command fails, the
  /// brew stays in preparation and a message says so, because continuing with a wrong zero would make every target
  /// wrong. Without a connected scale there is nothing to tare, and the brew advances.
  Future<void> onActionPressed() async {
    if (isLastPhase) {
      final BrewRecord record = _recorder.finish(_now());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (BuildContext context) => FeedbackRoute(record: record)),
      );
      return;
    }
    if (currentPhaseKind == BrewPhaseKind.prepare && scale.isConnected) {
      final bool tared = await _tare();
      if (!tared || !mounted) {
        return;
      }
    }
    setState(_advance);
  }

  /// Handles "New recipe" in the recipe menu by opening the screen for creating a recipe. The brew stays as it is
  /// underneath, so going back returns to it.
  ///
  /// If a recipe was created, the screen switches to it and a brief message confirms it.
  Future<void> onNewRecipePressed() async {
    final BrewRecipe? created = await Navigator.push<BrewRecipe>(
      context,
      MaterialPageRoute<BrewRecipe>(
        builder: (BuildContext context) => NewRecipeRoute(generationService: widget.recipeGenerationService),
      ),
    );
    if (created == null || !mounted) {
      return;
    }

    (widget.recipeRepository ?? RecipeRepository.instance).select(created);
    setState(() {
      _recipe = created;
      _startBrew();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBars.confirmation(context, AppLocalizations.of(context)!.recipeCreatedMessage(created.name)),
    );
  }

  /// Handles "Start demo" and "End demo" in the recipe menu.
  ///
  /// Starting the demo replaces any real scale with a simulated one and starts the brew again from its first step, so
  /// the demo shows the whole brew, and a brief message says the readings are simulated. Ending it leaves the brew
  /// where it is, without a scale, so the user can finish it with the main button.
  Future<void> onDemoPressed() async {
    if (scale.isDemo) {
      scale.stopDemo();
      return;
    }
    await scale.startDemo();
    if (!mounted) {
      return;
    }
    setState(_startBrew);
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBars.confirmation(context, AppLocalizations.of(context)!.demoStartedMessage),
    );
  }

  /// Handles a tap on Tare by zeroing the scale, and briefly says so if the command could not be sent.
  Future<void> onTarePressed() async {
    await _tare();
  }

  /// Zeroes the scale and returns whether that worked. If the command could not be sent, a message says so briefly.
  Future<bool> _tare() async {
    try {
      await scale.tare();
      return true;
    } on ThemisException catch (error) {
      debugPrint('Tare failed: $error');

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(AppSnackBars.problem(context, AppLocalizations.of(context)!.scaleTareFailed));
      }
      return false;
    }
  }

  @override
  void dispose() {
    scale.removeListener(_onScaleChanged);
    _stopTicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BrewView(this);
}
