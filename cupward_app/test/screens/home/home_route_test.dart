import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/screens/home/home_route.dart';
import 'package:cupward/services/on_device_model/on_device_model_service.dart';
import 'package:cupward/services/on_device_model/on_device_model_state.dart';
import 'package:cupward/theme/cupward_colors.dart';
import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/on_device_model/fake_hybrid_ai.dart';

/// Verifies that the home screen checks for the on-device model when it appears and starts a download from the panel.
void main() {
  late FakeHybridAi hybridAi;
  late OnDeviceModelService service;

  setUp(() {
    hybridAi = FakeHybridAi();
    service = OnDeviceModelService(hybridAi: hybridAi, isSupported: true);
  });

  tearDown(() => service.dispose());

  /// Shows the home screen with [service].
  Future<void> showHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeRoute(modelService: service),
      ),
    );
  }

  group('HomeRoute', () {
    /// The check runs before the first brew, so the user learns about the model up front.
    testWidgets('checks for the model when it appears', (WidgetTester tester) async {
      // Act
      await showHome(tester);
      await tester.pump();

      // Assert
      expect(hybridAi.checkCount, 1);
      expect(find.text('Not downloaded'), findsOneWidget);
      expect(find.text('Start a Brew'), findsOneWidget);
    });

    /// Coming back to the home screen must not repeat a check that already finished.
    testWidgets('does not check again on a later visit', (WidgetTester tester) async {
      // Arrange
      await service.checkStatus();

      // Act
      await showHome(tester);
      await tester.pump();

      // Assert
      expect(hybridAi.checkCount, 1);
    });

    /// Tapping Download starts the download and the panel follows its progress.
    testWidgets('downloads the model from the panel', (WidgetTester tester) async {
      // Arrange
      await showHome(tester);
      await tester.pump();

      // Act
      await tester.tap(find.text('Download'));
      hybridAi.downloadController.add(OnDeviceModelDownloadProgress(fraction: 0.25));
      await tester.pump();

      // Assert
      expect(hybridAi.downloadCount, 1);
      expect(service.state, OnDeviceModelState.downloading);
      expect(find.text('25%'), findsOneWidget);
    });
  });
}
