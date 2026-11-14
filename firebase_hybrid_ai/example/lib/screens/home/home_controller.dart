import 'dart:async';

import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:material_ui/material_ui.dart';

import 'home_route.dart';
import 'home_view.dart';

/// State and behavior for [HomeRoute].
///
/// Checks the on-device model status when the screen opens and again whenever the user asks, because the status
/// changes as a model downloads.
class HomeController extends State<HomeRoute> {
  /// The plugin entry point.
  final FirebaseHybridAi hybridAi = FirebaseHybridAi();

  /// The most recent successful result, or null before the first check completes.
  OnDeviceModelStatus? status;

  /// A description of the most recent failure, or null if the last check succeeded.
  String? errorMessage;

  /// Whether a check is currently running.
  bool isChecking = false;

  @override
  void initState() {
    super.initState();
    unawaited(onCheckPressed());
  }

  /// Reads the on-device model status and updates the screen with the result or the failure.
  Future<void> onCheckPressed() async {
    setState(() {
      isChecking = true;
      errorMessage = null;
    });

    try {
      final OnDeviceModelStatus result = await hybridAi.checkOnDeviceStatus();

      if (!mounted) {
        return;
      }

      setState(() => status = result);
    } on FirebaseHybridAiException catch (exception) {
      debugPrint('On-device status check failed: $exception');

      if (!mounted) {
        return;
      }

      setState(() => errorMessage = exception.message ?? exception.code);
    } finally {
      if (mounted) {
        setState(() => isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => HomeView(this);
}
