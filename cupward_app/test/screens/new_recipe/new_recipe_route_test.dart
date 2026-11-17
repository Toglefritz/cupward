import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/models/recipes/brew_method.dart';
import 'package:cupward/models/recipes/new_recipe_request.dart';
import 'package:cupward/screens/new_recipe/components/brew_method_card.dart';
import 'package:cupward/screens/new_recipe/new_recipe_controller.dart';
import 'package:cupward/screens/new_recipe/new_recipe_route.dart';
import 'package:cupward/theme/cupward_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The screen's own scrolling list, rather than the one inside the text field.
final Finder _page = find.byType(Scrollable).first;

/// Verifies the new recipe form: choosing a method, describing a taste, and when a recipe can be created.
void main() {
  /// Shows the screen at the given [width].
  Future<void> showScreen(WidgetTester tester, {double width = 412}) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const NewRecipeRoute(),
      ),
    );
  }

  /// The controller of the screen.
  NewRecipeController controller(WidgetTester tester) => tester.state<NewRecipeController>(find.byType(NewRecipeRoute));

  /// The "Create recipe" button.
  FilledButton createButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Create recipe'));

  group('NewRecipeRoute', () {
    /// Every method is offered as a card, none chosen at first.
    testWidgets('offers every brewing method', (WidgetTester tester) async {
      // Act
      await showScreen(tester);

      // Assert
      expect(find.text('New Recipe'), findsOneWidget);
      expect(find.byType(BrewMethodCard), findsNWidgets(BrewMethod.values.length));
      expect(find.text('French press'), findsOneWidget);
      expect(find.text('About 4½ min'), findsOneWidget);
      expect(controller(tester).selectedMethod, isNull);
    });

    /// Only one method is chosen at a time.
    testWidgets('chooses one method at a time', (WidgetTester tester) async {
      // Arrange
      await showScreen(tester);

      // Act
      await tester.tap(find.text('Chemex'));
      await tester.pump();
      await tester.tap(find.text('AeroPress'));
      await tester.pump();

      // Assert
      expect(controller(tester).selectedMethod, BrewMethod.aeroPress);
      final Iterable<BrewMethodCard> selected = tester
          .widgetList<BrewMethodCard>(find.byType(BrewMethodCard))
          .where((BrewMethodCard card) => card.isSelected);
      expect(selected.single.method, BrewMethod.aeroPress);
    });

    /// A recipe needs both a method and a description of the user's taste.
    testWidgets('enables Create once a method and a taste are given', (WidgetTester tester) async {
      // Arrange
      await showScreen(tester);
      await tester.scrollUntilVisible(find.text('Create recipe'), 300, scrollable: _page);

      // Assert
      expect(createButton(tester).onPressed, isNull);
      expect(find.textContaining('Pick a brewing method'), findsOneWidget);

      // Act: a taste alone is not enough.
      await tester.enterText(find.byType(TextField), 'Strong and full-bodied.');
      await tester.pump();

      // Assert
      expect(createButton(tester).onPressed, isNull);

      // Act
      await tester.scrollUntilVisible(find.text('V60'), -300, scrollable: _page);
      await tester.tap(find.text('V60'));
      await tester.pump();

      // Assert
      expect(createButton(tester).onPressed, isNotNull);
      expect(find.textContaining('Pick a brewing method'), findsNothing);
      expect(
        controller(tester).request,
        const NewRecipeRequest(method: BrewMethod.v60, preferences: 'Strong and full-bodied.'),
      );
    });

    /// Topic chips start a line about each topic, so the user knows what is useful to mention.
    testWidgets('starts a line for a tapped topic', (WidgetTester tester) async {
      // Arrange
      await showScreen(tester);
      await tester.scrollUntilVisible(find.text('Roast'), 300, scrollable: _page);

      // Act
      await tester.tap(find.text('Roast'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '${controller(tester).preferencesController.text}medium');
      await tester.tap(find.text('Cup size'));
      await tester.pump();

      // Assert
      expect(controller(tester).preferencesController.text, 'Roast: medium\nCup size: ');
      expect(controller(tester).preferencesFocus.hasFocus, isTrue);
    });

    /// The grid has two columns on phones and three on wider screens, and fits without overflowing.
    testWidgets('fits on narrow and wide screens', (WidgetTester tester) async {
      for (final double width in <double>[320, 412, 768, 1024]) {
        await showScreen(tester, width: width);
        await tester.tap(find.text('Kalita Wave'));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'width $width');
      }
    });
  });

  group('NewRecipeRequest', () {
    /// The request is what the recipe is built from, so it must survive conversion to JSON and back.
    test('converts to JSON and back, trimming the preferences', () {
      const NewRecipeRequest request = NewRecipeRequest(method: BrewMethod.frenchPress, preferences: '  Rich.  ');

      expect(request.toJson(), <String, dynamic>{'method': 'frenchPress', 'preferences': 'Rich.'});
      expect(
        NewRecipeRequest.fromJson(request.toJson()),
        const NewRecipeRequest(method: BrewMethod.frenchPress, preferences: 'Rich.'),
      );
      const Map<String, dynamic> unknown = <String, dynamic>{'method': 'siphon', 'preferences': ''};
      expect(() => NewRecipeRequest.fromJson(unknown), throwsFormatException);
    });
  });
}
