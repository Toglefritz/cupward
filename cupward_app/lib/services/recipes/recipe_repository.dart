import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/recipes/brew_recipe.dart';
import '../../models/recipes/recipe_ids.dart';
import '../auth/auth_service.dart';
import 'recipe_name_taken_exception.dart';

/// Stores the user's brew recipes in Cloud Firestore, straight from the app.
///
/// Each recipe is a document at `users/{userId}/recipes/{recipeId}`, where the user ID comes from the anonymous
/// sign-in in [AuthService] and the recipe ID is derived from the recipe's name by `RecipeIds`. Because the document
/// ID comes from the name, each of a user's recipes has a unique name. The document holds the recipe's JSON form,
/// plus:
///
/// * `schemaVersion`, the version of that form, so later versions of the app can read older documents.
/// * `createdAt` and `updatedAt`, set by the server.
///
/// Firestore's security rules, in `cupward_cloud/firestore.rules`, let each user read and write only their own
/// recipes, and check each recipe's shape and values, so the app needs no server code of its own. Firestore keeps a
/// copy of what it has read on the device, so recipes also load offline once they have been loaded before.
///
/// The repository also remembers which recipe the user chose to brew, in [selectedRecipeId], for as long as the app
/// runs.
class RecipeRepository {
  /// Creates a repository.
  ///
  /// [firestore] defaults to `FirebaseFirestore.instance`, and [auth] to `AuthService.instance`. Tests supply both.
  RecipeRepository({FirebaseFirestore? firestore, AuthService? auth})
      : _firestoreOverride = firestore,
        _auth = auth ?? AuthService.instance;

  /// The repository that the app shares.
  static final RecipeRepository instance = RecipeRepository();

  /// The version of the stored document's form.
  static const int schemaVersion = 1;

  /// The Firestore instance supplied by a test, or null to use the app's.
  final FirebaseFirestore? _firestoreOverride;

  /// Signs the user in before any request.
  final AuthService _auth;

  /// The ID of the recipe the user chose to brew, or null to brew the built-in recipe.
  String? get selectedRecipeId => _selectedRecipeId;
  String? _selectedRecipeId;

  /// Chooses [recipe] as the one to brew.
  void select(BrewRecipe recipe) => _selectedRecipeId = recipe.id;

  /// Returns the recipe the user chose to brew, or the user's copy of [fallback] if they have not chosen one, or if the
  /// chosen one can no longer be found.
  ///
  /// Like [fetchOrCreate], this returns [fallback] itself if the request fails.
  Future<BrewRecipe> fetchSelected(BrewRecipe fallback) async {
    final String? selected = _selectedRecipeId;
    if (selected == null || selected == fallback.id) {
      return await fetchOrCreate(fallback);
    }
    try {
      return await fetch(selected) ?? await fetchOrCreate(fallback);
    } on Object catch (error) {
      debugPrint('Could not load the chosen recipe $selected, so ${fallback.id} is used: $error');
      return fallback;
    }
  }

  /// The Firestore instance, read when first needed so that creating the repository does not require Firebase.
  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;

  /// Returns the user's recipe with [recipeId], or null if they have none with that ID.
  ///
  /// Throws a [FormatException] if the stored document cannot be read as a recipe, and rethrows Firestore and sign-in
  /// failures.
  Future<BrewRecipe?> fetch(String recipeId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await (await _recipeDocument(recipeId)).get();
    final Map<String, dynamic>? data = snapshot.data();

    return data == null ? null : BrewRecipe.fromJson(data);
  }

  /// Returns the user's copy of [recipe], saving [recipe] as their copy first if they have none.
  ///
  /// This is how a built-in recipe becomes the user's own, so that later changes to it are kept. If the request fails,
  /// for example on a first launch without a network, [recipe] itself is returned so the user can still brew.
  Future<BrewRecipe> fetchOrCreate(BrewRecipe recipe) async {
    try {
      final BrewRecipe? stored = await fetch(recipe.id);
      if (stored != null) {
        return stored;
      }
      await create(recipe);

      return recipe;
    } on RecipeNameTakenException {
      // Another install of the same account created it in the meantime, so that copy is the user's.
      return await fetch(recipe.id) ?? recipe;
    } on Object catch (error) {
      debugPrint('Could not load the stored recipe, so ${recipe.id} is used as it ships: $error');
      return recipe;
    }
  }

  /// Saves [recipe] as a new recipe.
  ///
  /// Throws a [RecipeNameTakenException] if the user already has a recipe whose name gives the same ID. The check and
  /// the write happen in one transaction, so two creations with the same name cannot both succeed. Throws an
  /// [ArgumentError] if the recipe's ID is not the one its name gives.
  Future<void> create(BrewRecipe recipe) async {
    _checkId(recipe);
    final DocumentReference<Map<String, dynamic>> document = await _recipeDocument(recipe.id);

    await _firestore.runTransaction<void>((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> existing = await transaction.get(document);
      if (existing.exists) {
        throw RecipeNameTakenException(name: recipe.name, recipeId: recipe.id);
      }
      transaction.set(document, <String, dynamic>{
        ..._fields(recipe),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Saves the changes to [recipe], an existing recipe, keeping when it was created.
  ///
  /// Throws an [ArgumentError] if the recipe's ID is not the one its name gives. A change of name gives a new ID, so
  /// renaming is a [create] of the renamed recipe followed by a delete of the old one.
  Future<void> update(BrewRecipe recipe) async {
    _checkId(recipe);
    await (await _recipeDocument(recipe.id)).update(_fields(recipe));
  }

  /// The document for the signed-in user's recipe with [recipeId], signing in first if needed.
  Future<DocumentReference<Map<String, dynamic>>> _recipeDocument(String recipeId) async {
    final String userId = await _auth.ensureSignedIn();

    return _firestore.collection('users').doc(userId).collection('recipes').doc(recipeId);
  }

  /// The fields written for [recipe], other than `createdAt`.
  static Map<String, dynamic> _fields(BrewRecipe recipe) => <String, dynamic>{
        ...recipe.toJson(),
        'schemaVersion': schemaVersion,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Throws an [ArgumentError] unless [recipe]'s ID is the one its name gives.
  static void _checkId(BrewRecipe recipe) {
    final String expected = RecipeIds.fromName(recipe.name);

    if (recipe.id != expected) {
      throw ArgumentError.value(recipe.id, 'recipe.id', 'must be "$expected", the ID that the name gives');
    }
  }
}
