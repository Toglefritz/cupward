import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cupward/models/recipes/brew_recipe.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
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
  });
}
