import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../components/app_snack_bars.dart';
import '../../l10n/app_localizations.dart';

import '../../models/feedback/brew_feedback.dart';
import '../../models/feedback/recipe_suggestion.dart';
import '../../models/recipes/brew_recipe.dart';
import '../../services/brew_feedback/brew_feedback_exception.dart';
import '../../services/brew_feedback/brew_feedback_failure.dart';
import '../../services/brew_feedback/brew_feedback_service.dart';
import '../../services/recipes/recipe_adjuster.dart';
import '../../services/recipes/recipe_repository.dart';
import 'components/recipe_parameter_labels.dart';
import 'models/suggestions_status.dart';
import 'suggestions_route.dart';
import 'suggestions_view.dart';

/// State and behavior for [SuggestionsRoute].
///
/// The request starts when the screen appears. While it runs the status is [SuggestionsStatus.loading]. It ends with
/// the [feedback] and [SuggestionsStatus.loaded], or with a [failure] and [SuggestionsStatus.failed], after which the
/// user can try again.
///
/// The user can save one suggestion to the recipe they brewed, which is the stored copy that the next brew loads. Only
/// one can be saved, so that each brew changes one variable. The change is confirmed as soon as it is made, because
/// Firestore saves it on the device first and sends it when it can. If the server refuses it, the screen says so and
/// the suggestion can be saved again.
class SuggestionsController extends State<SuggestionsRoute> {
  /// The service that asks for feedback, created once for the life of the screen.
  late final BrewFeedbackService _service = widget.feedbackService ?? BrewFeedbackService();

  /// Where the request stands.
  SuggestionsStatus status = SuggestionsStatus.loading;

  /// The feedback, once it has arrived.
  BrewFeedback? feedback;

  /// Why the last request failed, or null if it did not.
  BrewFeedbackFailure? failure;

  /// The suggestion saved to the recipe, or null if none has been.
  RecipeSuggestion? appliedSuggestion;

  /// The repository that saves the changed recipe.
  RecipeRepository get _recipes => widget.recipeRepository ?? RecipeRepository.instance;

  /// Whether [suggestion] can be saved to the recipe now: it gives a new recipe value, and no suggestion has been
  /// saved yet.
  bool canApply(RecipeSuggestion suggestion) =>
      appliedSuggestion == null && RecipeAdjuster.canApply(widget.record.recipe, suggestion);

  @override
  void initState() {
    super.initState();
    unawaited(_request());
  }

  /// Asks for feedback and shows the result. The status must already be [SuggestionsStatus.loading].
  Future<void> _request() async {
    try {
      final BrewFeedback result = await _service.requestFeedback(widget.record, widget.notes);
      if (!mounted) {
        return;
      }
      setState(() {
        feedback = result;
        status = SuggestionsStatus.loaded;
      });
    } on BrewFeedbackException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        failure = error.failure;
        status = SuggestionsStatus.failed;
      });
    }
  }

  /// Handles a tap on Try again by repeating the request.
  Future<void> onTryAgainPressed() {
    setState(() {
      status = SuggestionsStatus.loading;
      failure = null;
    });
    return _request();
  }

  /// Handles a tap on "Update my recipe" by saving [suggestion] to the recipe that was brewed.
  void onApplySuggestionPressed(RecipeSuggestion suggestion) {
    final BrewRecipe? updated = RecipeAdjuster.apply(widget.record.recipe, suggestion);
    if (updated == null || appliedSuggestion != null) {
      return;
    }

    final AppLocalizations strings = AppLocalizations.of(context)!;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    // Built now, because the screen may be gone by the time a failure is reported.
    final SnackBar failed = AppSnackBars.problem(context, strings.suggestionApplyFailed);
    setState(() => appliedSuggestion = suggestion);
    messenger.showSnackBar(
      AppSnackBars.confirmation(
        context,
        strings.suggestionAppliedMessage(
          RecipeParameterLabels.nameFor(suggestion.parameter, strings),
          RecipeParameterLabels.formatValue(suggestion.parameter, suggestion.suggestedValue!, strings),
        ),
      ),
    );

    unawaited(
      _recipes.update(updated).catchError((Object error) {
        debugPrint('Could not save the suggestion to the recipe: $error');
        if (mounted) {
          setState(() => appliedSuggestion = null);
        }
        // The confirmation is no longer true, so it is replaced rather than queued behind.
        messenger
          ..removeCurrentSnackBar()
          ..showSnackBar(failed);
      }),
    );
  }

  /// Handles a tap on Done by returning to the home screen.
  void onDonePressed() {
    Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) => SuggestionsView(this);
}
