import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/screens/home/components/on_device_model_panel.dart';
import 'package:cupward/services/on_device_model/on_device_model_state.dart';
import 'package:cupward/theme/cupward_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Verifies what the on-device AI panel shows in each state, and that it fits on every screen width. The panel is shown
/// on its own, with the app's colors extension and English strings.
void main() {
  late int downloadTaps;
  late int tryAgainTaps;

  setUp(() {
    downloadTaps = 0;
    tryAgainTaps = 0;
  });

  /// Shows the panel for [state] at the given [width].
  Future<void> showPanel(
    WidgetTester tester,
    OnDeviceModelState state, {
    double? progress,
    bool didDownloadFail = false,
    double width = 412,
  }) async {
    tester.view.physicalSize = Size(width, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(28),
            child: Align(
              alignment: Alignment.topCenter,
              child: OnDeviceModelPanel(
                state: state,
                downloadProgress: progress,
                didDownloadFail: didDownloadFail,
                onDownloadPressed: () => downloadTaps++,
                onTryAgainPressed: () => tryAgainTaps++,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('OnDeviceModelPanel', () {
    /// A model that can be downloaded is the one case where the user has something to do.
    testWidgets('offers a download when the model can be downloaded', (WidgetTester tester) async {
      // Act
      await showPanel(tester, OnDeviceModelState.downloadable);
      await tester.tap(find.text('Download'));

      // Assert
      expect(find.text('On-device AI'), findsOneWidget);
      expect(find.text('Not downloaded'), findsOneWidget);
      expect(downloadTaps, 1);
    });

    /// While downloading, the user sees how far it has come and that they can brew in the meantime.
    testWidgets('shows progress while downloading', (WidgetTester tester) async {
      // Act
      await showPanel(tester, OnDeviceModelState.downloading, progress: 0.42);

      // Assert
      expect(find.text('Downloading'), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Download'), findsNothing);
    });

    /// A download started outside the app reports no progress, so no percentage can be shown.
    testWidgets('shows a moving bar when progress is unknown', (WidgetTester tester) async {
      // Act
      await showPanel(tester, OnDeviceModelState.downloading);

      // Assert
      expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, isNull);
      expect(find.textContaining('%'), findsNothing);
    });

    /// A failed download must say so, and still offer the download.
    testWidgets('explains a failed download', (WidgetTester tester) async {
      // Act
      await showPanel(tester, OnDeviceModelState.downloadable, didDownloadFail: true);

      // Assert
      expect(find.textContaining("The download didn't finish"), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
    });

    /// Once the model is ready, or when it can never be, there is nothing to do.
    testWidgets('offers no action when ready or unsupported', (WidgetTester tester) async {
      for (final OnDeviceModelState state in <OnDeviceModelState>[
        OnDeviceModelState.available,
        OnDeviceModelState.unavailable,
        OnDeviceModelState.checking,
      ]) {
        await showPanel(tester, state);
        expect(find.byType(InkWell), findsNothing, reason: state.name);
      }
    });

    /// A failed check can be repeated.
    testWidgets('offers to check again after a failed check', (WidgetTester tester) async {
      // Act
      await showPanel(tester, OnDeviceModelState.unknown);
      await tester.tap(find.text('Try again'));

      // Assert
      expect(find.text("Couldn't check"), findsOneWidget);
      expect(tryAgainTaps, 1);
    });

    /// The longest message and the action must fit without overflowing on the narrowest and widest screens.
    testWidgets('fits on narrow and wide screens', (WidgetTester tester) async {
      for (final double width in <double>[320, 412, 768]) {
        for (final OnDeviceModelState state in OnDeviceModelState.values) {
          await showPanel(tester, state, progress: 0.5, width: width);
          expect(tester.takeException(), isNull, reason: '${state.name} at $width');
        }
      }
    });
  });
}
