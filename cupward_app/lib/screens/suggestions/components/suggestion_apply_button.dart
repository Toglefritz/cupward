import 'package:material_ui/material_ui.dart';

import '../../../components/panel_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';

/// The action on a suggested change that saves it to the recipe: an "Update my recipe" button, or, once saved, a
/// green check with "Saved to your recipe".
///
/// The button uses the app's cream pill for actions inside cards, so it sits below the screen's green Done button in
/// emphasis. The saved state replaces the button so the change is not saved twice.
class SuggestionApplyButton extends StatelessWidget {
  /// Creates the action, showing the saved state when [isApplied] is true, and otherwise a button that calls
  /// [onPressed].
  const SuggestionApplyButton({required this.isApplied, this.onPressed, super.key})
      : assert(isApplied || onPressed != null, 'onPressed is required until the suggestion is saved');

  /// Whether this suggestion has been saved to the recipe.
  final bool isApplied;

  /// Called when the button is tapped, or null once the suggestion is saved.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context)!;

    final VoidCallback? pressed = onPressed;
    if (!isApplied && pressed != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: PanelButton(label: strings.buttonApplySuggestion, onPressed: pressed),
      );
    }

    final Color success = context.cupwardColors.success;
    return Semantics(
      liveRegion: true,
      child: Row(
        children: <Widget>[
          Icon(Icons.check_circle, size: 20, color: success),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: Insets.xSmall),
              child: Text(
                strings.suggestionApplied,
                style: context.theme.textTheme.bodyMedium?.copyWith(color: success, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
