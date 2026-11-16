import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';

/// A small label saying which AI model produced the feedback: "On-device AI" or "Cloud AI".
///
/// Hybrid inference picks the model for each request, so the badge tells the user whether their brew data stayed on
/// the device. The on-device badge uses the success green, and the cloud badge the secondary ink color.
class InferenceSourceBadge extends StatelessWidget {
  /// Creates a badge for [source].
  const InferenceSourceBadge({required this.source, super.key});

  /// The model that produced the feedback.
  final InferenceSource source;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final bool onDevice = source == InferenceSource.onDevice;
    final Color color = onDevice ? context.cupwardColors.success : theme.colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: StadiumBorder(side: BorderSide(color: color.withValues(alpha: 0.4))),
        color: color.withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.xSmall, vertical: Insets.xxSmall),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(onDevice ? Icons.smartphone : Icons.cloud_outlined, size: 14, color: color),
            Padding(
              padding: const EdgeInsets.only(left: Insets.xxSmall),
              child: Text(
                onDevice ? strings.suggestionsSourceOnDevice : strings.suggestionsSourceCloud,
                style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
