import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';

/// The message above the main button that explains what the scale is doing to the brew.
///
/// While the grounds rest after the bloom water is added, it shows the time left. When the phase is finished and the
/// brew is about to move on by itself, it counts down and offers Cancel. The countdown takes precedence over the rest,
/// because it is the one the user can act on. When neither applies it takes no space.
class BrewAdvanceNotice extends StatelessWidget {
  /// Creates the notice.
  ///
  /// [restRemaining] is the time left in a rest, or null when the phase is not resting. [advanceRemaining] is the time
  /// left before the brew moves on, or null when it is not about to. [onCancel] is called when the user taps Cancel.
  const BrewAdvanceNotice({required this.onCancel, this.restRemaining, this.advanceRemaining, super.key});

  /// The time left in the phase's rest, or null if it is not resting.
  final Duration? restRemaining;

  /// The time left before the brew moves to the next step, or null if it is not about to.
  final Duration? advanceRemaining;

  /// Called when the user taps Cancel during the countdown.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final ThemeData theme = context.theme;
    final Duration? advance = advanceRemaining;
    final Duration? rest = restRemaining;

    final Widget? content;
    if (advance != null) {
      // Rounds up so the countdown shows 3, 2, 1 and never a 0 before the brew moves on.
      final int seconds = (advance.inMilliseconds / 1000).ceil();
      content = Row(
        children: <Widget>[
          Expanded(child: Text(strings.brewAdvanceCountdown(seconds), style: theme.textTheme.titleMedium)),
          TextButton(onPressed: onCancel, child: Text(strings.brewAdvanceCancel)),
        ],
      );
    } else if (rest != null && rest > Duration.zero) {
      content = Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Insets.xSmall),
          child: Text(strings.brewRestRemaining(_format(rest)), style: theme.textTheme.titleMedium),
        ),
      );
    } else {
      content = null;
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      alignment: Alignment.topCenter,
      child: content == null
          ? const SizedBox(width: double.infinity)
          : Padding(padding: const EdgeInsets.only(bottom: Insets.xSmall), child: content),
    );
  }

  /// Formats [duration] as minutes and seconds, such as "0:32", rounding up to the next whole second.
  static String _format(Duration duration) {
    final int totalSeconds = (duration.inMilliseconds / 1000).ceil();
    final String seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    return '${totalSeconds ~/ 60}:$seconds';
  }
}
