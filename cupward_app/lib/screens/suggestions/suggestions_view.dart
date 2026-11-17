import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../models/feedback/brew_feedback.dart';
import '../../models/feedback/recipe_suggestion.dart';
import '../../services/brew_feedback/brew_feedback_failure.dart';
import '../../theme/context_theme_extension.dart';
import '../../theme/insets.dart';
import 'components/alternative_suggestion_card.dart';
import 'components/primary_suggestion_card.dart';
import 'components/suggestion_apply_button.dart';
import 'components/suggestions_status_card.dart';
import 'components/suggestions_summary_card.dart';
import 'models/suggestions_status.dart';
import 'suggestions_controller.dart';

/// Layout for the brew feedback screen. Contains no logic.
///
/// It uses the app's scrolling content column of limited width. While the feedback is prepared, and if it fails, a
/// single status card fills the column. Once the feedback arrives, the summary card comes first, then the main
/// suggestion, then any ideas for later brews under their own heading, and a Done button at the end. Each suggestion
/// that can be saved to the recipe has an "Update my recipe" button until one of them is saved, which then shows as
/// saved.
class SuggestionsView extends StatelessWidget {
  /// Creates the view for [state].
  const SuggestionsView(this.state, {super.key});

  /// The controller supplying data and callbacks.
  final SuggestionsController state;

  /// The widest the content column grows on large windows, matching the other screens.
  static const double _maxContentWidth = 760;

  /// Returns the message for [failure].
  static String messageFor(BrewFeedbackFailure failure, AppLocalizations strings) {
    switch (failure) {
      case BrewFeedbackFailure.unsupported:
        return strings.suggestionsFailureUnsupported;
      case BrewFeedbackFailure.requestFailed:
        return strings.suggestionsFailureRequest;
      case BrewFeedbackFailure.invalidResponse:
        return strings.suggestionsFailureInvalid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Insets.small, Insets.xSmall, Insets.small, Insets.small),
              children: _buildChildren(context),
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the save action for [suggestion]: the saved state if it was saved, a button if it can be, or null.
  Widget? _applyAction(RecipeSuggestion suggestion) {
    if (state.appliedSuggestion == suggestion) {
      return const SuggestionApplyButton(isApplied: true);
    }
    if (state.canApply(suggestion)) {
      return SuggestionApplyButton(isApplied: false, onPressed: () => state.onApplySuggestionPressed(suggestion));
    }
    return null;
  }

  /// Returns the content for the current status.
  List<Widget> _buildChildren(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final BrewFeedback? feedback = state.feedback;
    final BrewFeedbackFailure? failure = state.failure;

    switch (state.status) {
      case SuggestionsStatus.loading:
        return <Widget>[
          SuggestionsStatusCard(
            title: strings.suggestionsLoadingTitle,
            message: strings.suggestionsLoadingMessage,
            isBusy: true,
          ),
        ];
      case SuggestionsStatus.failed:
        return <Widget>[
          SuggestionsStatusCard(
            title: strings.suggestionsErrorTitle,
            message: messageFor(failure ?? BrewFeedbackFailure.requestFailed, strings),
            action: failure == BrewFeedbackFailure.unsupported
                ? null
                : OutlinedButton(onPressed: state.onTryAgainPressed, child: Text(strings.buttonTryAgain)),
          ),
        ];
      case SuggestionsStatus.loaded:
        if (feedback == null) {
          return const <Widget>[];
        }
        return <Widget>[
          SuggestionsSummaryCard(feedback: feedback),
          Padding(
            padding: const EdgeInsets.only(top: Insets.small),
            child: PrimarySuggestionCard(suggestion: feedback.primary, action: _applyAction(feedback.primary)),
          ),
          if (feedback.alternatives.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(Insets.xSmall, Insets.large, Insets.xSmall, Insets.xSmall),
              child: Semantics(
                header: true,
                child: Text(
                  strings.suggestionsAlternativesTitle,
                  style: context.theme.textTheme.headlineMedium?.copyWith(fontSize: 24),
                ),
              ),
            ),
          for (final RecipeSuggestion suggestion in feedback.alternatives)
            Padding(
              padding: const EdgeInsets.only(top: Insets.xSmall),
              child: AlternativeSuggestionCard(suggestion: suggestion, action: _applyAction(suggestion)),
            ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.large),
            child: FilledButton(onPressed: state.onDonePressed, child: Text(strings.buttonFinish)),
          ),
        ];
    }
  }
}
