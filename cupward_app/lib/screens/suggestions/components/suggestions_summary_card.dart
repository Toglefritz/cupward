import 'package:material_ui/material_ui.dart';

import '../../../components/content_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/feedback/brew_feedback.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';
import 'inference_source_badge.dart';

/// The opening card of the brew feedback screen: a "Your next brew" heading with a badge for the model that answered,
/// and the feedback's short read of the cup.
class SuggestionsSummaryCard extends StatelessWidget {
  /// Creates the card for [feedback].
  const SuggestionsSummaryCard({required this.feedback, super.key});

  /// The feedback summarized.
  final BrewFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;

    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Insets.small,
            runSpacing: Insets.xSmall,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(strings.suggestionsTitle, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 26)),
              ),
              InferenceSourceBadge(source: feedback.source),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Insets.small),
            child: Divider(color: context.cupwardColors.cardBorder),
          ),
          Text(feedback.summary, style: theme.textTheme.bodyLarge?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}
