import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';

/// A small copper "Demo" tag beside the scale panel's heading, which shows that the readings are simulated.
///
/// It uses the copper of the app's eyebrow labels, in spaced capitals, inside a hairline outline, so it reads as a
/// label rather than a button.
class ScaleDemoBadge extends StatelessWidget {
  /// Creates the badge.
  const ScaleDemoBadge({super.key});

  /// The corner radius of the outline.
  static const double _cornerRadius = 6;

  @override
  Widget build(BuildContext context) {
    final Color accent = context.cupwardColors.accent;
    return Semantics(
      label: AppLocalizations.of(context)!.scaleDemoSemanticLabel,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(_cornerRadius),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Insets.xSmall - Insets.micro, vertical: Insets.micro),
          child: Text(
            AppLocalizations.of(context)!.scaleDemoBadge.toUpperCase(),
            style: context.theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}
