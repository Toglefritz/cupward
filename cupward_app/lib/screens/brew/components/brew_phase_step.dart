import 'package:material_ui/material_ui.dart';

import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';
import '../models/brew_phase_status.dart';
import 'brew_phase_line.dart';
import 'brew_phase_marker.dart';

/// One phase in the phase indicator: its marker on the connecting line, with its name below.
///
/// The line is drawn in two halves, one on each side of the marker, so neighboring steps join into one continuous
/// line. See [BrewPhaseLine].
class BrewPhaseStep extends StatelessWidget {
  /// Creates the step for one phase.
  ///
  /// [isFirst] and [isLast] leave out the half of the line that would lead off the end. [isLeadingLineReached] and
  /// [isTrailingLineReached] say whether the brew has reached each half.
  const BrewPhaseStep({
    required this.label,
    required this.status,
    required this.isFirst,
    required this.isLast,
    required this.isLeadingLineReached,
    required this.isTrailingLineReached,
    super.key,
  });

  /// The name of the phase.
  final String label;

  /// Where the phase stands in the brew.
  final BrewPhaseStatus status;

  /// Whether this is the first phase, which has no line on its left.
  final bool isFirst;

  /// Whether this is the last phase, which has no line on its right.
  final bool isLast;

  /// Whether the brew has reached the half of the line on the left of the marker.
  final bool isLeadingLineReached;

  /// Whether the brew has reached the half of the line on the right of the marker.
  final bool isTrailingLineReached;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final bool isCurrent = status == BrewPhaseStatus.current;

    return Column(
      children: <Widget>[
        SizedBox(
          height: BrewPhaseMarker.currentSize,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: BrewPhaseLine(isVisible: !isFirst, isReached: isLeadingLineReached)),
                  Expanded(child: BrewPhaseLine(isVisible: !isLast, isReached: isTrailingLineReached)),
                ],
              ),
              BrewPhaseMarker(status: status),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.xxSmall, left: Insets.micro, right: Insets.micro),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: isCurrent
                  ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
                  : theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}
