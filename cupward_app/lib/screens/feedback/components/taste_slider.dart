import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/brews/taste_attribute.dart';
import '../../../models/brews/tasting_notes.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';
import 'taste_attribute_labels.dart';

/// A slider for rating one taste attribute, with the attribute's name above it and the words for its two ends below.
///
/// The slider has a stop for each rating from `TastingNotes.minRating` to `TastingNotes.maxRating`. Until the user
/// rates the attribute, the slider is drawn in the hairline color with its thumb in the middle, and "Not rated" sits
/// beside the name, so an untouched slider does not look like an answer. Touching it anywhere, including the thumb,
/// rates the attribute.
///
/// Screen readers announce the name with the value, such as "Bitterness, 4 of 5", or "Not rated".
class TasteSlider extends StatelessWidget {
  /// Creates a slider for [attribute] showing [rating], or no rating when it is null.
  const TasteSlider({required this.attribute, required this.rating, required this.onChanged, super.key});

  /// The attribute rated.
  final TasteAttribute attribute;

  /// The current rating, or null if the user has not rated the attribute.
  final int? rating;

  /// Called with the new rating when the user moves the slider.
  final ValueChanged<int> onChanged;

  /// Where the thumb rests before the attribute is rated.
  static const int _restingRating = (TastingNotes.minRating + TastingNotes.maxRating) ~/ 2;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final int? current = rating;
    final bool isRated = current != null;
    final TextStyle? endStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final Color muted = context.cupwardColors.cardBorder;
    final SliderThemeData sliderTheme = SliderTheme.of(context).copyWith(
      activeTrackColor: isRated ? theme.colorScheme.primary : muted,
      inactiveTrackColor: muted,
      thumbColor: isRated ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
      activeTickMarkColor: isRated ? theme.colorScheme.onPrimary : theme.colorScheme.outlineVariant,
      inactiveTickMarkColor: theme.colorScheme.outlineVariant,
      overlayColor: theme.colorScheme.primary.withValues(alpha: 0.12),
    );

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  TasteAttributeLabels.nameFor(attribute, strings),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (!isRated) ExcludeSemantics(child: Text(strings.tastingNotRated, style: endStyle)),
            ],
          ),
          SliderTheme(
            data: sliderTheme,
            child: Slider(
              value: (current ?? _restingRating).toDouble(),
              min: TastingNotes.minRating.toDouble(),
              max: TastingNotes.maxRating.toDouble(),
              divisions: TastingNotes.maxRating - TastingNotes.minRating,
              // A tap on the resting thumb does not change the value, so the first touch rates the attribute here.
              onChangeStart: isRated ? null : (double value) => onChanged(value.round()),
              onChanged: (double value) => onChanged(value.round()),
              semanticFormatterCallback: (double value) => isRated
                  ? strings.tastingRatingSemantics(value.round(), TastingNotes.maxRating)
                  : strings.tastingNotRated,
            ),
          ),
          ExcludeSemantics(
            child: Padding(
              // Matches the slider's own inset, so the words sit under the ends of the track.
              padding: const EdgeInsets.symmetric(horizontal: Insets.small),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Each end gets up to half the width, so a long translation wraps instead of overflowing.
                  Flexible(child: Text(TasteAttributeLabels.lowFor(attribute, strings), style: endStyle)),
                  const SizedBox(width: Insets.small),
                  Flexible(
                    child: Text(
                      TasteAttributeLabels.highFor(attribute, strings),
                      style: endStyle,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
