import 'dart:async';

import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../models/recipes/brew_phase_kind.dart';
import '../../models/recipes/brew_recipe.dart';
import '../../services/scale/scale_connection_status.dart';
import '../../services/scale/scale_service.dart';
import 'brew_route.dart';
import 'brew_view.dart';
import 'components/scale_picker_sheet.dart';

/// State and behavior for [BrewRoute].
///
/// The scale connection belongs to the app-wide [ScaleService], so a scale connected during an earlier brew is still
/// connected here, and the screen opens straight to its readings. The controller rebuilds the screen whenever the
/// service notifies.
class BrewController extends State<BrewRoute> {
  /// The recipe being brewed.
  BrewRecipe get recipe => widget.recipe;

  /// The position of the current phase in the recipe's phases. A brew starts at its first phase.
  int currentPhaseIndex = 0;

  /// The kind of the current phase.
  BrewPhaseKind get currentPhaseKind => recipe.phases[currentPhaseIndex].kind;

  /// The service that connects to and reads from the scale.
  ScaleService get scale => widget.scaleService ?? ScaleService.instance;

  /// Whether this platform can use a scale. Browsers cannot connect to one over Bluetooth, so on the web the brew is
  /// followed without scale readings.
  bool get isScaleSupported => scale.status != ScaleConnectionStatus.unsupported;

  @override
  void initState() {
    super.initState();
    scale.addListener(_onScaleChanged);
  }

  /// Rebuilds the screen with the scale's latest state.
  void _onScaleChanged() {
    if (mounted) {
      setState(() {});
    }
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
  /// In the last phase this leaves the screen. In any other phase it moves to the next one. Leaving the preparation
  /// phase first tares the scale, so the weights in the later phases count water only. If the tare command fails, the
  /// brew stays in preparation and a message says so, because continuing with a wrong zero would make every target
  /// wrong. Without a connected scale there is nothing to tare, and the brew advances.
  Future<void> onActionPressed() async {
    if (isLastPhase) {
      Navigator.pop(context);
      return;
    }
    if (currentPhaseKind == BrewPhaseKind.prepare && scale.isConnected) {
      final bool tared = await _tare();
      if (!tared || !mounted) {
        return;
      }
    }
    setState(() => currentPhaseIndex++);
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
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.scaleTareFailed)));
      }
      return false;
    }
  }

  @override
  void dispose() {
    scale.removeListener(_onScaleChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BrewView(this);
}
