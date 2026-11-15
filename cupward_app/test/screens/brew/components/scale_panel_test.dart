import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/models/recipes/brew_phase_kind.dart';
import 'package:cupward/screens/brew/components/scale_battery_indicator.dart';
import 'package:cupward/screens/brew/components/scale_panel.dart';
import 'package:cupward/services/scale/scale_connection_status.dart';
import 'package:cupward/theme/cupward_colors.dart';
import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A reading of 18.4 g, pouring at 3.2 g/s, with an 82 percent battery.
const BookooScaleReading _reading = BookooScaleReading(
  elapsed: Duration.zero,
  weightGrams: 18.4,
  flowRateGramsPerSecond: 3.2,
  batteryPercent: 82,
  standbyTime: Duration(minutes: 5),
  beepLevel: 3,
  flowSmoothingEnabled: false,
);

/// Verifies what the scale panel shows for each connection status and brew phase, and that it fits on every screen
/// width. The panel is shown on its own, with the app's colors extension and English strings.
void main() {
  /// How many times each button was tapped in the current test.
  late int findScaleTaps;
  late int tareTaps;

  setUp(() {
    findScaleTaps = 0;
    tareTaps = 0;
  });

  /// Shows the panel for a scale in [status] with [reading], during a phase of [phaseKind], at the given [width].
  Future<void> showPanel(
    WidgetTester tester, {
    required ScaleConnectionStatus status,
    BookooScaleReading? reading,
    BrewPhaseKind phaseKind = BrewPhaseKind.prepare,
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
            padding: const EdgeInsets.all(16),
            child: ScalePanel(
              status: status,
              reading: reading,
              phaseKind: phaseKind,
              onFindScalePressed: () => findScaleTaps++,
              onTarePressed: () => tareTaps++,
            ),
          ),
        ),
      ),
    );
  }

  group('ScalePanel', () {
    /// Without a scale the user needs a way to connect one, and no weight is available.
    testWidgets('offers to find a scale when none is connected', (WidgetTester tester) async {
      // Act
      await showPanel(tester, status: ScaleConnectionStatus.disconnected);
      await tester.tap(find.text('Find scale'));

      // Assert
      expect(find.text('Scale'), findsOneWidget);
      expect(find.text('Not connected'), findsOneWidget);
      expect(find.text('–'), findsOneWidget);
      expect(findScaleTaps, 1);
    });

    /// A browser cannot use the scale, so the panel says so and offers nothing to tap.
    testWidgets('shows that scales are not available where unsupported', (WidgetTester tester) async {
      // Act
      await showPanel(tester, status: ScaleConnectionStatus.unsupported);

      // Assert
      expect(find.text('Not available'), findsOneWidget);
      expect(find.text('Find scale'), findsNothing);
    });

    /// While connecting, a second tap must not start another attempt.
    testWidgets('shows progress while connecting', (WidgetTester tester) async {
      // Act
      await showPanel(tester, status: ScaleConnectionStatus.connecting);

      // Assert
      expect(find.text('Connecting'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Find scale'), findsNothing);
    });

    /// Taring only makes sense while setting up, before any water is poured.
    testWidgets('offers Tare while preparing', (WidgetTester tester) async {
      // Act
      await showPanel(tester, status: ScaleConnectionStatus.connected, reading: _reading);
      await tester.tap(find.text('Tare'));

      // Assert
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('18.4 g'), findsOneWidget);
      expect(find.text('82%'), findsOneWidget);
      expect(find.text('Flow'), findsNothing);
      expect(tareTaps, 1);
    });

    /// While pouring, the rate replaces Tare, since zeroing the scale mid-pour would lose the brew's weight.
    testWidgets('shows the flow rate instead of Tare while water is poured', (WidgetTester tester) async {
      for (final BrewPhaseKind kind in <BrewPhaseKind>[BrewPhaseKind.bloom, BrewPhaseKind.pour]) {
        // Act
        await showPanel(tester, status: ScaleConnectionStatus.connected, reading: _reading, phaseKind: kind);

        // Assert
        expect(find.text('3.2 g/s'), findsOneWidget, reason: kind.name);
        expect(find.text('Flow'), findsOneWidget, reason: kind.name);
        expect(find.text('Tare'), findsNothing, reason: kind.name);
      }
    });

    /// Once the brew is done there is nothing left to tare or pour, so only the weight remains.
    testWidgets('shows only the weight once the brew is complete', (WidgetTester tester) async {
      // Act
      await showPanel(
        tester,
        status: ScaleConnectionStatus.connected,
        reading: _reading,
        phaseKind: BrewPhaseKind.complete,
      );

      // Assert
      expect(find.text('18.4 g'), findsOneWidget);
      expect(find.text('Tare'), findsNothing);
      expect(find.text('Flow'), findsNothing);
    });

    /// The first reading can take a moment to arrive after connecting, and the panel must not show a false zero.
    testWidgets('shows a dash before the first reading', (WidgetTester tester) async {
      // Act
      await showPanel(tester, status: ScaleConnectionStatus.connected, phaseKind: BrewPhaseKind.pour);

      // Assert
      expect(find.text('–'), findsNWidgets(2));
      expect(find.byType(ScaleBatteryIndicator), findsNothing);
    });

    /// Both layouts must fit without overflowing, with the widest action and the longest status.
    testWidgets('fits on narrow and wide screens', (WidgetTester tester) async {
      for (final double width in <double>[320, 360, 412, 768, 1024]) {
        await showPanel(tester, status: ScaleConnectionStatus.disconnected, width: width);
        expect(tester.takeException(), isNull, reason: 'disconnected at $width');

        await showPanel(tester, status: ScaleConnectionStatus.connected, reading: _reading, width: width);
        expect(tester.takeException(), isNull, reason: 'connected at $width');
      }
    });
  });

  group('ScaleBatteryIndicator', () {
    /// The icon must match the charge, and a nearly empty scale must stand out.
    test('picks an icon for the charge', () {
      expect(ScaleBatteryIndicator.iconFor(100), Icons.battery_full);
      expect(ScaleBatteryIndicator.iconFor(50), Icons.battery_4_bar);
      expect(ScaleBatteryIndicator.iconFor(15), Icons.battery_1_bar);
      expect(ScaleBatteryIndicator.iconFor(10), Icons.battery_alert);
    });
  });
}
