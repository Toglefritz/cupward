import 'dart:async';

import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:firebase_hybrid_ai_example/screens/home/home_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Verifies that the home screen shows the on-device model status, offers a download when the model is downloadable,
/// and shows the download's progress and outcome.
///
/// The plugin's platform implementation is replaced with a fake, so no Firebase or native code is involved.
void main() {
  late FirebaseHybridAiPlatform originalPlatform;

  setUp(() {
    originalPlatform = FirebaseHybridAiPlatform.instance;
  });

  tearDown(() {
    FirebaseHybridAiPlatform.instance = originalPlatform;
  });

  /// Opens the home screen on a surface tall enough to build the whole activity log, which sits below the figure.
  Future<void> openHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: HomeRoute()));
    await tester.pumpAndSettle();
  }

  group('status', () {
    /// The screen checks the status as soon as it opens, so the result must appear without any interaction.
    testWidgets('shows the model status and name after opening', (WidgetTester tester) async {
      // Arrange
      FirebaseHybridAiPlatform.instance = _FakePlatform(
        result: OnDeviceModelStatus(availability: OnDeviceModelAvailability.available, modelName: 'nano-v4-full'),
      );

      // Act
      await openHome(tester);

      // Assert
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('nano-v4-full'), findsOneWidget);
      expect(find.text('Check on-device model'), findsOneWidget);
    });

    /// Each check is recorded in the activity log, so the outcome is visible without reading the figure.
    testWidgets('records the result in the activity log', (WidgetTester tester) async {
      // Arrange
      FirebaseHybridAiPlatform.instance = _FakePlatform(
        result: OnDeviceModelStatus(availability: OnDeviceModelAvailability.downloadable),
      );

      // Act
      await openHome(tester);

      // Assert
      expect(find.text('Downloadable'), findsOneWidget);
      expect(find.text('On-device model (preview) is downloadable.'), findsOneWidget);
    });

    /// A failure must be shown to the user instead of leaving the screen blank or crashing the app.
    testWidgets('shows the error message when the check fails', (WidgetTester tester) async {
      // Arrange
      FirebaseHybridAiPlatform.instance = _FakePlatform(
        error: const FirebaseNotInitializedException(message: 'Firebase is not initialized.'),
      );

      // Act
      await openHome(tester);

      // Assert
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('Firebase is not initialized.'), findsOneWidget);
      expect(find.text('Check failed: Firebase is not initialized.'), findsOneWidget);
    });
  });

  group('category', () {
    /// The example targets Gemini Nano 4, which is offered as the preview release, so that is what it asks for first.
    testWidgets('checks the preview release when it opens', (WidgetTester tester) async {
      // Arrange
      final _FakePlatform platform = _FakePlatform(
        result: OnDeviceModelStatus(availability: OnDeviceModelAvailability.available),
      );
      FirebaseHybridAiPlatform.instance = platform;

      // Act
      await openHome(tester);

      // Assert
      expect(platform.categories, <OnDeviceModelCategory>[OnDeviceModelCategory.preview]);
      expect(find.text('Gemini Nano release'), findsOneWidget);
    });

    /// Availability differs between releases, so choosing another release must check that release, and the log must
    /// say which one was checked.
    testWidgets('checks the release the user selects', (WidgetTester tester) async {
      // Arrange
      final _FakePlatform platform = _FakePlatform(
        result: OnDeviceModelStatus(availability: OnDeviceModelAvailability.downloadable),
      );
      FirebaseHybridAiPlatform.instance = platform;
      await openHome(tester);

      // Act
      await tester.tap(find.text('Stable'));
      await tester.pumpAndSettle();

      // Assert
      expect(platform.categories, <OnDeviceModelCategory>[OnDeviceModelCategory.preview, OnDeviceModelCategory.stable]);
      expect(find.text('On-device model (stable) is downloadable.'), findsOneWidget);
    });

    /// A download must fetch the release that the screen is showing, not a different one.
    testWidgets('downloads the selected release', (WidgetTester tester) async {
      // Arrange
      final _FakePlatform platform = _FakePlatform(
        result: OnDeviceModelStatus(availability: OnDeviceModelAvailability.downloadable),
      );
      FirebaseHybridAiPlatform.instance = platform;
      await openHome(tester);
      await tester.tap(find.text('Fast'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Download model'));
      await tester.pump();

      // Assert
      expect(platform.categories.last, OnDeviceModelCategory.previewFast);
    });
  });

  group('download', () {
    /// A model that is not installed offers a download, and any other state does not.
    testWidgets('offers a download button only when the model is downloadable', (WidgetTester tester) async {
      // Arrange
      FirebaseHybridAiPlatform.instance = _FakePlatform(
        result: OnDeviceModelStatus(availability: OnDeviceModelAvailability.downloadable),
      );

      // Act
      await openHome(tester);

      // Assert
      expect(find.text('Download model'), findsOneWidget);
      expect(find.text('Check on-device model'), findsNothing);
    });

    /// Progress from the plugin must drive the bar, and the screen must check the status again when the download
    /// finishes, so that it shows the installed model.
    testWidgets('shows progress and then the installed model', (WidgetTester tester) async {
      // Arrange
      final _FakePlatform platform = _FakePlatform(
        result: OnDeviceModelStatus(availability: OnDeviceModelAvailability.downloadable),
      );
      FirebaseHybridAiPlatform.instance = platform;
      await openHome(tester);

      // Act: start the download and report half of it.
      await tester.tap(find.text('Download model'));
      await tester.pump();
      platform.progress.add(OnDeviceModelDownloadProgress(fraction: 0.5));
      await tester.pump();

      // Assert: the bar and the busy label reflect the progress.
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Downloading'), findsWidgets);

      // Act: finish the download. The model is installed by the time the status is read again.
      platform.result = OnDeviceModelStatus(availability: OnDeviceModelAvailability.available, modelName: 'nano-v4');
      platform.progress.add(OnDeviceModelDownloadProgress(fraction: 1));
      await platform.progress.close();
      await tester.pumpAndSettle();

      // Assert: the screen shows the installed model and logs the outcome.
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('nano-v4'), findsOneWidget);
      expect(find.text('Download finished.'), findsOneWidget);
      expect(find.text('50%'), findsNothing);
    });

    /// A failed download must be reported and must not leave the screen stuck in the downloading state.
    testWidgets('shows the error and offers the download again when it fails', (WidgetTester tester) async {
      // Arrange
      final _FakePlatform platform = _FakePlatform(
        result: OnDeviceModelStatus(availability: OnDeviceModelAvailability.downloadable),
      );
      FirebaseHybridAiPlatform.instance = platform;
      await openHome(tester);

      // Act
      await tester.tap(find.text('Download model'));
      await tester.pump();
      platform.progress.addError(const FirebaseHybridAiException(code: 'download-failed', message: 'No space left.'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Download failed: No space left.'), findsOneWidget);
      expect(find.text('Download model'), findsOneWidget);
    });
  });
}

/// A platform implementation with a settable status and a download stream the test controls.
class _FakePlatform extends FirebaseHybridAiPlatform {
  /// Creates a fake that returns [result], or throws [error] when one is given.
  new({this.result, this.error});

  /// The value returned by [checkOnDeviceStatus], when no [error] is set. Tests change it to simulate an installed
  /// model.
  OnDeviceModelStatus? result;

  /// The exception thrown by [checkOnDeviceStatus], if any.
  final Exception? error;

  /// The category of every call, in order, so tests can check which release the screen asked for.
  final List<OnDeviceModelCategory> categories = <OnDeviceModelCategory>[];

  /// The source of the events returned by [downloadOnDeviceModel].
  final StreamController<OnDeviceModelDownloadProgress> progress = StreamController<OnDeviceModelDownloadProgress>();

  @override
  Future<OnDeviceModelStatus> checkOnDeviceStatus({
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
  }) async {
    categories.add(category);

    if (error != null) {
      throw error!;
    }

    return result!;
  }

  @override
  Stream<OnDeviceModelDownloadProgress> downloadOnDeviceModel({
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
  }) {
    categories.add(category);

    return progress.stream;
  }
}
