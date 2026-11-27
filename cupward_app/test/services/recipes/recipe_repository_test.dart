import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cupward/models/recipes/brew_method.dart';
import 'package:cupward/models/recipes/brew_recipe.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/models/recipes/recipe_ids.dart';
import 'package:cupward/services/auth/auth_service.dart';
import 'package:cupward/services/recipes/recipe_name_taken_exception.dart';
import 'package:cupward/services/recipes/recipe_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// An auth service that is already signed in as [userId], without Firebase.
class _SignedInAuth extends AuthService {
  /// Creates a service signed in as [userId].
  _SignedInAuth(this._userId);

  /// The user ID returned by [ensureSignedIn].
  final String _userId;

  @override
  String? get userId => _userId;

  @override
  Future<String> ensureSignedIn() async => _userId;
}

/// An auth service whose sign-in always fails, as on a first launch without a network.
class _OfflineAuth extends AuthService {
  @override
  Future<String> ensureSignedIn() async => throw Exception('offline');
}

/// Returns [recipe] with [coffeeGrams] instead of its own.
BrewRecipe _withCoffee(BrewRecipe recipe, double coffeeGrams) => BrewRecipe(
      id: recipe.id,
      name: recipe.name,
      method: recipe.method,
      profile: recipe.profile,
      coffeeGrams: coffeeGrams,
      waterGrams: recipe.waterGrams,
      brewTime: recipe.brewTime,
      yieldMilliliters: recipe.yieldMilliliters,
      phases: recipe.phases,
    );

/// Verifies where recipes are stored, how unique names are enforced, and the fallback when Firestore is unreachable.
void main() {
  late FakeFirebaseFirestore firestore;
  late RecipeRepository repository;
  const BrewRecipe recipe = BuiltInRecipes.v60PourOver;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = RecipeRepository(firestore: firestore, auth: _SignedInAuth('alice'));
  });

  group('RecipeRepository', () {
    /// The security rules allow each user only their own documents, under this path.
    test('stores a recipe under the user, named by its ID', () async {
      // Act
      await repository.create(recipe);

      // Assert
      final DocumentSnapshot<Map<String, dynamic>> stored =
          await firestore.doc('users/alice/recipes/v60-pour-over').get();
      expect(stored.exists, isTrue);
      expect(stored.data()!['name'], 'V60 Pour Over');
      expect(stored.data()!['schemaVersion'], RecipeRepository.schemaVersion);
      expect(stored.data()!['createdAt'], isA<Timestamp>());
      expect(stored.data()!['updatedAt'], isA<Timestamp>());
    });

    /// A stored recipe reads back as the same recipe.
    test('reads back what it stored', () async {
      // Arrange
      await repository.create(recipe);

      // Act
      final BrewRecipe? fetched = await repository.fetch(recipe.id);

      // Assert
      expect(fetched?.toJson(), recipe.toJson());
      expect(await repository.fetch('missing'), isNull);
    });

    /// Each name may be used once, so a second recipe with the same name is refused.
    test('refuses a second recipe with the same name', () async {
      // Arrange
      await repository.create(recipe);

      // Act and assert
      await expectLater(repository.create(recipe), throwsA(isA<RecipeNameTakenException>()));
    });

    /// The document ID must be the one the name gives, or names would stop being unique.
    test('refuses a recipe whose ID does not match its name', () async {
      // Arrange
      final BrewRecipe mismatched = BrewRecipe(
        id: 'something-else',
        name: recipe.name,
        method: recipe.method,
        profile: recipe.profile,
        coffeeGrams: recipe.coffeeGrams,
        waterGrams: recipe.waterGrams,
        brewTime: recipe.brewTime,
        yieldMilliliters: recipe.yieldMilliliters,
        phases: recipe.phases,
      );

      // Act and assert
      expect(() => repository.create(mismatched), throwsArgumentError);
    });

    /// Changes to a recipe are kept, with its original creation time.
    test('updates a stored recipe', () async {
      // Arrange
      await repository.create(recipe);
      final Object? createdAt = (await firestore.doc('users/alice/recipes/v60-pour-over').get()).data()!['createdAt'];

      // Act
      await repository.update(_withCoffee(recipe, 21));

      // Assert
      final Map<String, dynamic> stored = (await firestore.doc('users/alice/recipes/v60-pour-over').get()).data()!;
      expect(stored['coffeeGrams'], 21);
      expect(stored['createdAt'], createdAt);
      expect((await repository.fetch(recipe.id))!.coffeeGrams, 21);
    });

    /// The first brew saves the built-in recipe as the user's own copy, and later brews use that copy.
    test('creates the user copy of a recipe once, then returns it', () async {
      // Act
      final BrewRecipe first = await repository.fetchOrCreate(recipe);
      await repository.update(_withCoffee(recipe, 21));
      final BrewRecipe second = await repository.fetchOrCreate(recipe);

      // Assert
      expect(first.coffeeGrams, 20);
      expect(second.coffeeGrams, 21);
    });

    /// Users do not see each other's recipes.
    test('keeps each user to their own recipes', () async {
      // Arrange
      await repository.create(recipe);
      final RecipeRepository bob = RecipeRepository(firestore: firestore, auth: _SignedInAuth('bob'));

      // Act and assert
      expect(await bob.fetch(recipe.id), isNull);
    });

    /// Without a network on a first launch, the user can still brew the recipe as it ships.
    test('falls back to the given recipe when Firestore cannot be reached', () async {
      // Arrange
      final RecipeRepository offline = RecipeRepository(firestore: firestore, auth: _OfflineAuth());

      // Act
      final BrewRecipe result = await offline.fetchOrCreate(recipe);

      // Assert
      expect(result, same(recipe));
    });

    /// After the user chooses a recipe, later brews load it instead of the built-in one.
    test('loads the chosen recipe', () async {
      // Arrange
      final BrewRecipe chosen = recipe.copyWith(id: 'house-blend', name: 'House Blend', coffeeGrams: 18);
      await repository.create(chosen);

      // Act
      final BrewRecipe before = await repository.fetchSelected(recipe);
      repository.select(chosen);
      final BrewRecipe after = await repository.fetchSelected(recipe);

      // Assert
      expect(before.id, recipe.id);
      expect(after.id, 'house-blend');
      expect(after.coffeeGrams, 18);
    });

    /// A chosen recipe that has gone falls back to the built-in recipe, so a brew can always start.
    test('falls back when the chosen recipe is gone', () async {
      // Arrange
      repository.select(recipe.copyWith(id: 'gone', name: 'Gone'));

      // Act
      final BrewRecipe result = await repository.fetchSelected(recipe);

      // Assert
      expect(result.id, recipe.id);
    });

    /// Version 1 documents have no method. They still load, and saving one writes the current version with a method.
    test('reads and upgrades a recipe stored without a method', () async {
      // Arrange
      final Map<String, dynamic> legacy = recipe.toJson()
        ..remove('method')
        ..['schemaVersion'] = 1;
      await firestore.doc('users/alice/recipes/v60-pour-over').set(legacy);
      // Act
      final BrewRecipe? fetched = await repository.fetch(recipe.id);
      await repository.update(fetched!);
      // Assert
      expect(fetched.method, BrewMethod.v60);
      final Map<String, dynamic> stored = (await firestore.doc('users/alice/recipes/v60-pour-over').get()).data()!;
      expect(stored['method'], 'v60');
      expect(stored['schemaVersion'], 2);
    });

    /// The recipe list screen shows the newest recipe first, so the one just created is easy to find.
    test('lists all of the user\'s recipes, the newest first', () async {
      // Arrange
      for (final (String name, int day) in <(String, int)>[('Old One', 1), ('New One', 3), ('Middle One', 2)]) {
        final BrewRecipe stored = recipe.copyWith(id: RecipeIds.fromName(name), name: name);
        await firestore.doc('users/alice/recipes/${stored.id}').set(<String, dynamic>{
          ...stored.toJson(),
          'createdAt': Timestamp.fromDate(DateTime.utc(2025, 1, day)),
        });
      }
      // Another user's recipe must not appear.
      await firestore.doc('users/bob/recipes/v60-pour-over').set(recipe.toJson());
      // Act
      final List<BrewRecipe> recipes = await repository.fetchAll();
      // Assert
      expect(recipes.map((BrewRecipe item) => item.name), <String>['New One', 'Middle One', 'Old One']);
    });

    /// A user with nothing stored has an empty list.
    test('lists nothing for a user without recipes', () async {
      expect(await repository.fetchAll(), isEmpty);
    });

    /// One document that cannot be read must not hide the user's other recipes.
    test('leaves out a stored recipe that cannot be read', () async {
      // Arrange
      await repository.create(recipe);
      await firestore.doc('users/alice/recipes/broken').set(<String, dynamic>{'name': 'Broken'});
      // Act
      final List<BrewRecipe> recipes = await repository.fetchAll();
      // Assert
      expect(recipes.map((BrewRecipe item) => item.id), <String>[recipe.id]);
    });

    /// The security rules list the exact fields and methods a recipe may have. If the app writes anything else, every
    /// save fails in production, so the two are compared here.
    test('writes only the fields and methods the security rules allow', () async {
      // Arrange
      final String rules = File('../cupward_cloud/firestore.rules').readAsStringSync();
      List<String> quoted(String source) =>
          RegExp("'([^']+)'").allMatches(source).map((RegExpMatch match) => match.group(1)!).toList();
      final String hasOnly = RegExp(r'hasOnly\(\[([^\]]*)\]').firstMatch(rules)!.group(1)!;
      final String methods = RegExp(r'recipe\.method in \[([^\]]*)\]').firstMatch(rules)!.group(1)!;
      final int version = int.parse(RegExp(r'recipe\.schemaVersion == (\d+)').firstMatch(rules)!.group(1)!);
      // Act
      await repository.create(recipe.copyWith(method: BrewMethod.cleverDripper));
      final Map<String, dynamic> stored = (await firestore.doc('users/alice/recipes/v60-pour-over').get()).data()!;
      // Assert
      expect(stored.keys.toSet(), quoted(hasOnly).toSet());
      expect(quoted(methods).toSet(), BrewMethod.values.map((BrewMethod method) => method.name).toSet());
      expect(version, RecipeRepository.schemaVersion);
    });
  });
}
