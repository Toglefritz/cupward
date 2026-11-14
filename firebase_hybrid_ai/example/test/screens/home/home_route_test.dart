import 'dart:async';

import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:firebase_hybrid_ai_example/screens/home/home_route.dart';
import 'package:firebase_hybrid_ai_example/screens/home/models/structured_sample.dart';
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
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: HomeRoute()));
    await tester.pumpAndSettle();
  }

  /// Turns the "Stream the response" switch off, for tests of the whole-response path.
  Future<void> turnStreamingOff(WidgetTester tester) async {
    await tester.tap(find.byType(Switch));
    await tester.pump();
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

  group('prompt', () {
    /// A platform that is ready to answer, so that these tests only vary the request and the response.
    _FakePlatform readyPlatform({TextGenerationResult? generation, Exception? generationError}) {
      return _FakePlatform(
        result: OnDeviceModelStatus(availability: OnDeviceModelAvailability.available, modelName: 'nano-v4-full'),
        generation: generation ?? TextGenerationResult(text: 'African or European?', source: InferenceSource.onDevice),
        generationError: generationError,
      );
    }

    /// Nothing can be sent without text, so the button must wait for the user to type or pick a sample.
    testWidgets('disables the send button until there is a prompt', (WidgetTester tester) async {
      // Arrange
      FirebaseHybridAiPlatform.instance = readyPlatform();
      await openHome(tester);

      // Assert: no text yet.
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send prompt')).onPressed, isNull);

      // Act
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      // Assert
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send prompt')).onPressed, isNotNull);
    });

    /// A sample prompt is a shortcut for typing, so it must land in the field where the user can still edit it.
    testWidgets('fills the text field from a sample prompt', (WidgetTester tester) async {
      // Arrange
      FirebaseHybridAiPlatform.instance = readyPlatform();
      await openHome(tester);

      // Act
      await tester.tap(find.text('What is the airspeed velocity of an unladen swallow?'));
      await tester.pump();

      // Assert
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, startsWith('What is the airspeed'));
    });

    /// The response and its source must both be visible, because the source says where the prompt was processed.
    testWidgets('shows an on-device response with its source', (WidgetTester tester) async {
      // Arrange
      final _FakePlatform platform = readyPlatform();
      FirebaseHybridAiPlatform.instance = platform;
      await openHome(tester);
      await turnStreamingOff(tester);

      // Act
      await tester.enterText(find.byType(TextField), 'What is the airspeed velocity of an unladen swallow?');
      await tester.pump();
      await tester.tap(find.text('Send prompt'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('African or European?'), findsOneWidget);
      expect(find.text('On-device'), findsOneWidget);
      expect(platform.prompts, <String>['What is the airspeed velocity of an unladen swallow?']);
    });

    /// A cloud response must be labeled as such, so that nobody mistakes it for a private, on-device answer.
    testWidgets('labels a cloud response as cloud', (WidgetTester tester) async {
      // Arrange
      FirebaseHybridAiPlatform.instance = readyPlatform(
        generation: TextGenerationResult(text: 'From the cloud', source: InferenceSource.inCloud),
      );
      await openHome(tester);
      await turnStreamingOff(tester);

      // Act
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      await tester.tap(find.text('Send prompt'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Cloud'), findsOneWidget);
      expect(find.text('From the cloud'), findsOneWidget);
    });

    /// The chosen routing mode and model release decide where the prompt goes, so both must reach the plugin.
    testWidgets('sends the selected mode and model release', (WidgetTester tester) async {
      // Arrange
      final _FakePlatform platform = readyPlatform();
      FirebaseHybridAiPlatform.instance = platform;
      await openHome(tester);
      await turnStreamingOff(tester);

      // Act
      await tester.tap(find.text('Cloud only'));
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      await tester.tap(find.text('Send prompt'));
      await tester.pumpAndSettle();

      // Assert
      expect(platform.modes, <InferenceMode>[InferenceMode.onlyInCloud]);
      expect(platform.generationCategories, <OnDeviceModelCategory>[OnDeviceModelCategory.preview]);
    });

    /// A failed request must be explained on screen and must leave the screen ready for another attempt.
    testWidgets('shows the error when generation fails', (WidgetTester tester) async {
      // Arrange
      FirebaseHybridAiPlatform.instance = readyPlatform(
        generationError: const OnDeviceModelUnavailableException(message: 'The model is not installed.'),
      );
      await openHome(tester);
      await turnStreamingOff(tester);

      // Act
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      await tester.tap(find.text('Send prompt'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('The model is not installed.'), findsOneWidget);
      expect(find.text('Generation failed: The model is not installed.'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send prompt')).onPressed, isNotNull);
    });
  });

  group('streaming', () {
    /// A platform that is ready to answer, with chunks that the test releases one at a time.
    _FakePlatform readyPlatform() {
      return _FakePlatform(
        result: OnDeviceModelStatus(availability: OnDeviceModelAvailability.available, modelName: 'nano-v4-full'),
      );
    }

    /// Types a prompt and taps the send button.
    Future<void> sendPrompt(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField), 'Tell me a story');
      await tester.pump();
      await tester.tap(find.text('Send prompt'));
      await tester.pump();
    }

    /// Streaming is the default, so the response must grow on screen as chunks arrive, and the source and the time
    /// to the first chunk must be shown.
    testWidgets('shows the response growing as chunks arrive', (WidgetTester tester) async {
      // Arrange
      final _FakePlatform platform = readyPlatform();
      FirebaseHybridAiPlatform.instance = platform;
      await openHome(tester);

      // Act
      await sendPrompt(tester);
      platform.chunks.add(TextGenerationChunk(text: 'Once ', source: InferenceSource.onDevice));
      await tester.pump();

      // Assert: the first words are visible while the request is still running, with a way to stop it.
      expect(find.text('Once '), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);

      // Act
      platform.chunks.add(TextGenerationChunk(text: 'upon a time', source: InferenceSource.onDevice));
      await tester.pump();

      // Assert: later chunks are appended to the text.
      expect(find.text('Once upon a time'), findsOneWidget);

      // Act
      await platform.chunks.close();
      await tester.pumpAndSettle();

      // Assert: the request is over, and the screen reports both timings.
      expect(find.text('Send prompt'), findsOneWidget);
      expect(find.text('On-device'), findsOneWidget);
      expect(find.textContaining('first chunk'), findsOneWidget);
      expect(find.textContaining('total'), findsOneWidget);
      expect(platform.streamedPrompts, <String>['Tell me a story']);
    });

    /// Stopping must cancel the subscription, because that is what tells the host to stop generating, and the words
    /// that already arrived must stay.
    testWidgets('stops the generation and keeps the text that arrived', (WidgetTester tester) async {
      // Arrange
      final _FakePlatform platform = readyPlatform();
      FirebaseHybridAiPlatform.instance = platform;
      await openHome(tester);
      await sendPrompt(tester);
      platform.chunks.add(TextGenerationChunk(text: 'Partial', source: InferenceSource.onDevice));
      await tester.pump();

      // Act
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      // Assert
      expect(platform.wasCancelled, isTrue);
      expect(find.text('Partial'), findsOneWidget);
      expect(find.text('Send prompt'), findsOneWidget);
      expect(find.text('Stopped by the user.'), findsOneWidget);
    });

    /// A failure partway through must keep the text that arrived and explain the failure after it.
    testWidgets('shows the error after the text that arrived when the stream fails', (WidgetTester tester) async {
      // Arrange
      final _FakePlatform platform = readyPlatform();
      FirebaseHybridAiPlatform.instance = platform;
      await openHome(tester);
      await sendPrompt(tester);
      platform.chunks.add(TextGenerationChunk(text: 'Partial', source: InferenceSource.inCloud));
      await tester.pump();

      // Act
      platform.chunks.addError(const FirebaseHybridAiException(code: 'generation-failed', message: 'Connection lost.'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Partial'), findsOneWidget);
      expect(find.text('Connection lost.'), findsOneWidget);
      expect(find.text('Send prompt'), findsOneWidget);
    });

    /// The switch chooses the path, so turning it off must use the single-response call.
    testWidgets('uses the single-response call when streaming is off', (WidgetTester tester) async {
      // Arrange
      final _FakePlatform platform = _FakePlatform(
        result: OnDeviceModelStatus(availability: OnDeviceModelAvailability.available),
        generation: TextGenerationResult(text: 'Whole', source: InferenceSource.onDevice),
      );
      FirebaseHybridAiPlatform.instance = platform;
      await openHome(tester);
      await turnStreamingOff(tester);

      // Act
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      await tester.tap(find.text('Send prompt'));
      await tester.pumpAndSettle();

      // Assert
      expect(platform.prompts, <String>['Hello']);
      expect(platform.streamedPrompts, isEmpty);
      expect(find.text('Whole'), findsOneWidget);
    });
  });

  group('structured', () {
    /// A platform that is ready, and that answers structured requests with [result].
    _FakePlatform readyPlatform(StructuredGenerationResult result) {
      return _FakePlatform(
        result: OnDeviceModelStatus(availability: OnDeviceModelAvailability.available, modelName: 'nano-v4-full'),
        structured: result,
      );
    }

    /// A conforming result for the animal fact sample, as on-device inference without enforcement would produce it.
    const StructuredGenerationResult animalResult = StructuredGenerationResult(
      text: '{"animal": "Sea otter", "category": "behavior", "fact": "Sea otters hold hands while they sleep."}',
      data: <String, Object?>{
        'animal': 'Sea otter',
        'category': 'behavior',
        'fact': 'Sea otters hold hands while they sleep.',
      },
      source: InferenceSource.onDevice,
      isSchemaEnforced: false,
      violations: <String>[],
    );

    /// Choosing structured prompts must load the first sample's prompt and show its schema. Streaming does not apply.
    testWidgets('shows the sample prompt and its schema, and hides streaming', (WidgetTester tester) async {
      // Arrange
      FirebaseHybridAiPlatform.instance = readyPlatform(animalResult);
      await openHome(tester);

      // Act
      await tester.tap(find.text('Structured (JSON)'));
      await tester.pump();

      // Assert
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, StructuredSample.animalFact.prompt);
      expect(find.text('Animal fact'), findsOneWidget);
      expect(find.text('Recipe idea'), findsOneWidget);
      expect(find.text('Review sentiment'), findsOneWidget);
      expect(find.textContaining('"category"'), findsOneWidget);
      expect(find.text('Stream the response'), findsNothing);
    });

    /// The selected sample's schema and the chosen routing must reach the plugin, and the result must be shown with
    /// both of its flags: where the schema came from and whether the output matched.
    testWidgets('sends the schema and shows the fields with both flags', (WidgetTester tester) async {
      // Arrange
      final _FakePlatform platform = readyPlatform(animalResult);
      FirebaseHybridAiPlatform.instance = platform;
      await openHome(tester);
      await tester.tap(find.text('Structured (JSON)'));
      await tester.pump();

      // Act
      await tester.tap(find.text('Send prompt'));
      await tester.pumpAndSettle();

      // Assert
      expect(platform.structuredSchemas.single, same(StructuredSample.animalFact.schema));
      expect(platform.structuredPrompts.single, StructuredSample.animalFact.prompt);
      expect(find.text('Sea otters hold hands while they sleep.'), findsOneWidget);
      expect(find.text('Schema described in the prompt'), findsOneWidget);
      expect(find.text('Matches the schema'), findsOneWidget);
      expect(find.text('On-device'), findsOneWidget);
    });

    /// A response that does not match must say so and list each problem, so the user can see what went wrong.
    testWidgets('lists the problems of a response that does not match', (WidgetTester tester) async {
      // Arrange
      FirebaseHybridAiPlatform.instance = readyPlatform(
        const StructuredGenerationResult(
          text: '{"animal": "Sea otter", "category": "cuteness"}',
          data: <String, Object?>{'animal': 'Sea otter', 'category': 'cuteness'},
          source: InferenceSource.inCloud,
          isSchemaEnforced: true,
          violations: <String>[r'$.category must be one of habitat, diet, but is "cuteness".', r'$.fact is required.'],
        ),
      );
      await openHome(tester);
      await tester.tap(find.text('Structured (JSON)'));
      await tester.pump();

      // Act
      await tester.tap(find.text('Send prompt'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Does not match the schema'), findsOneWidget);
      expect(find.text('Schema enforced by the platform'), findsOneWidget);
      expect(find.text(r'$.fact is required.'), findsOneWidget);
    });

    /// Each sample pairs a prompt with a schema, so choosing another sample must change both.
    testWidgets('sends the schema of the sample that the user chooses', (WidgetTester tester) async {
      // Arrange
      final _FakePlatform platform = readyPlatform(animalResult);
      FirebaseHybridAiPlatform.instance = platform;
      await openHome(tester);
      await tester.tap(find.text('Structured (JSON)'));
      await tester.pump();

      // Act
      await tester.tap(find.text('Recipe idea'));
      await tester.pump();
      await tester.tap(find.text('Send prompt'));
      await tester.pumpAndSettle();

      // Assert
      expect(platform.structuredPrompts.single, StructuredSample.recipeIdea.prompt);
      expect(platform.structuredSchemas.single, same(StructuredSample.recipeIdea.schema));
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
  new({this.result, this.error, this.generation, this.generationError, this.structured});

  /// The value returned by [generateStructured].
  final StructuredGenerationResult? structured;

  /// The prompt and schema of every [generateStructured] call, in order.
  final List<String> structuredPrompts = <String>[];
  final List<ResponseSchema> structuredSchemas = <ResponseSchema>[];

  /// The value returned by [checkOnDeviceStatus], when no [error] is set. Tests change it to simulate an installed
  /// model.
  OnDeviceModelStatus? result;

  /// The exception thrown by [checkOnDeviceStatus], if any.
  final Exception? error;

  /// The value returned by [generateText], when no [generationError] is set.
  final TextGenerationResult? generation;

  /// The exception thrown by [generateText], if any.
  final Exception? generationError;

  /// The prompt, mode, and category of every [generateText] call, in order.
  final List<String> prompts = <String>[];
  final List<InferenceMode> modes = <InferenceMode>[];
  final List<OnDeviceModelCategory> generationCategories = <OnDeviceModelCategory>[];

  /// The prompts of the [generateTextStream] calls, in order.
  final List<String> streamedPrompts = <String>[];

  /// The source of the chunks that [generateTextStream] returns. Tests add chunks to it, and close it to end the
  /// stream.
  late final StreamController<TextGenerationChunk> chunks = StreamController<TextGenerationChunk>(
    onCancel: () => wasCancelled = true,
  );

  /// Whether a listener cancelled the stream of [chunks].
  bool wasCancelled = false;

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

  @override
  Future<TextGenerationResult> generateText(
    String prompt, {
    InferenceMode mode = InferenceMode.preferOnDevice,
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
    String cloudModel = FirebaseHybridAi.defaultCloudModel,
  }) async {
    prompts.add(prompt);
    modes.add(mode);
    generationCategories.add(category);

    if (generationError != null) {
      throw generationError!;
    }

    return generation!;
  }

  @override
  Stream<TextGenerationChunk> generateTextStream(
    String prompt, {
    InferenceMode mode = InferenceMode.preferOnDevice,
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
    String cloudModel = FirebaseHybridAi.defaultCloudModel,
  }) {
    streamedPrompts.add(prompt);
    modes.add(mode);
    generationCategories.add(category);

    return chunks.stream;
  }

  @override
  Future<StructuredGenerationResult> generateStructured(
    String prompt, {
    required ResponseSchema schema,
    InferenceMode mode = InferenceMode.preferOnDevice,
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
    String cloudModel = FirebaseHybridAi.defaultCloudModel,
  }) async {
    structuredPrompts.add(prompt);
    structuredSchemas.add(schema);
    modes.add(mode);

    return structured!;
  }
}
