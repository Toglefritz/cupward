import 'package:material_ui/material_ui.dart';

import '../../models/brews/brew_record.dart';
import '../../models/brews/tasting_notes.dart';
import '../../services/brew_feedback/brew_feedback_service.dart';
import '../../services/recipes/recipe_repository.dart';
import 'suggestions_controller.dart';

/// The brew feedback screen, which asks the hybrid AI system how to change the recipe and shows its suggestions.
///
/// It opens from the feedback screen with the brew's [record] and the user's [notes], and sends them as soon as it
/// appears. Going back returns to the feedback screen, so the user can change their notes and ask again. A suggestion
/// with a new value can be saved to the recipe that was brewed, so the next brew uses it.
class SuggestionsRoute extends StatefulWidget {
  /// Creates the screen for feedback on [record] with [notes].
  ///
  /// [feedbackService] defaults to a new `BrewFeedbackService`, and [recipeRepository] to `RecipeRepository.instance`.
  /// Tests supply their own.
  const SuggestionsRoute({
    required this.record,
    required this.notes,
    this.feedbackService,
    this.recipeRepository,
    super.key,
  });

  /// What happened during the brew.
  final BrewRecord record;

  /// How the user said the brew tasted.
  final TastingNotes notes;

  /// The service that asks for feedback, or null to use a new one.
  final BrewFeedbackService? feedbackService;

  /// The repository that saves the changed recipe, or null to use the app's shared one.
  final RecipeRepository? recipeRepository;

  @override
  State<SuggestionsRoute> createState() => SuggestionsController();
}
