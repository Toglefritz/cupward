import 'dart:async';

import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/screens/brew/components/scale_picker_sheet.dart';
import 'package:cupward/services/scale/scale_service.dart';
import 'package:cupward/theme/cupward_colors.dart';
import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A client whose scan the test drives, and whose connections always fail.
class _FakeClient implements ThemisUltraClient {
  /// The scan stream returned by [scan].
  final StreamController<ThemisUltraDevice> scanController = StreamController<ThemisUltraDevice>();

  @override
  Stream<ThemisUltraDevice> scan({Duration timeout = const Duration(seconds: 15)}) => scanController.stream;

  @override
  Future<ThemisUltra> connect(ThemisUltraDevice device) async => throw const ThemisConnectionException('timed out');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Verifies what the scale sheet shows while searching, after finding scales, and after a failure.
void main() {
  late _FakeClient client;
  late ScaleService service;
  late List<ThemisUltraDevice> selected;
  late int searchAgainTaps;

  setUp(() {
    client = _FakeClient();
    service = ScaleService(client: client, isSupported: true);
    selected = <ThemisUltraDevice>[];
    searchAgainTaps = 0;
  });

  tearDown(() => service.dispose());

  /// Shows the sheet's content for [service].
  Future<void> showSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ScalePickerSheet(
            service: service,
            onDeviceSelected: selected.add,
            onSearchAgainPressed: () => searchAgainTaps++,
          ),
        ),
      ),
    );
  }

  group('ScalePickerSheet', () {
    /// Before anything is found, the user needs to know the app is looking and what to check.
    testWidgets('explains the search while nothing is found', (WidgetTester tester) async {
      // Arrange
      await service.startScan();

      // Act
      await showSheet(tester);

      // Assert
      expect(find.text('Choose your scale'), findsOneWidget);
      expect(find.textContaining('Looking for BOOKOO scales'), findsOneWidget);
      expect(find.text('Search again'), findsNothing);
    });

    /// Found scales appear as they arrive, strongest signal first, and tapping one chooses it.
    testWidgets('lists found scales and reports a tap', (WidgetTester tester) async {
      // Arrange
      await service.startScan();
      await showSheet(tester);

      // Act
      client.scanController
        ..add(const ThemisUltraDevice(name: 'BOOKOO_SC far', address: 'A', rssi: -80))
        ..add(const ThemisUltraDevice(name: 'BOOKOO_SC near', address: 'B', rssi: -50));
      await tester.pump();
      await tester.tap(find.text('BOOKOO_SC near'));

      // Assert
      expect(find.text('Signal -50 dBm'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('BOOKOO_SC near')).dy,
        lessThan(tester.getTopLeft(find.text('BOOKOO_SC far')).dy),
      );
      expect(selected.single.address, 'B');
    });

    /// A search that found nothing must say so and let the user try again.
    testWidgets('offers to search again when nothing was found', (WidgetTester tester) async {
      // Arrange
      await service.startScan();
      await showSheet(tester);

      // Act
      await client.scanController.close();
      await tester.pump();
      await tester.tap(find.text('Search again'));

      // Assert
      expect(find.textContaining('No scales found'), findsOneWidget);
      expect(searchAgainTaps, 1);
    });

    /// A failed connection must explain itself in words the user can act on.
    testWidgets('shows why a connection failed', (WidgetTester tester) async {
      // Arrange
      await showSheet(tester);

      // Act
      await service.connect(const ThemisUltraDevice(name: 'BOOKOO_SC', address: 'A', rssi: -60));
      await tester.pump();

      // Assert
      expect(find.textContaining("Couldn't connect to the scale"), findsOneWidget);
    });
  });
}
