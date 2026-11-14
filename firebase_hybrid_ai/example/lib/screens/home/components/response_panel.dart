import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';
import 'status_dot.dart';

/// The model's response to the last prompt, with where it was generated and how long it took.
///
/// It shows the generated text, or the error if the request failed, or a hint before the first request.
class ResponsePanel extends StatelessWidget {
  /// Creates the panel.
  ///
  /// [result] and [elapsed] describe the last successful request. [errorMessage] describes a failed one and takes
  /// precedence. All three are null before the first request.
  const new({required this.result, required this.elapsed, required this.errorMessage, super.key});

  /// The last successful response, or null.
  final TextGenerationResult? result;

  /// How long the last successful request took, or null.
  final Duration? elapsed;

  /// A description of the last failure, or null if the last request succeeded.
  final String? errorMessage;

  /// The label for a response source.
  static String sourceLabel(InferenceSource source) {
    switch (source) {
      case InferenceSource.onDevice:
        return 'On-device';
      case InferenceSource.inCloud:
        return 'Cloud';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final String? error = errorMessage;
    final TextGenerationResult? current = result;

    if (error != null) {
      return Text(error, style: theme.textTheme.bodyMedium?.copyWith(color: colors.error));
    }

    if (current == null) {
      return Text(
        'Responses appear here.',
        style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      );
    }

    // The dot color separates the two sources at a glance: green for a response that never left the device.
    final Color dotColor = current.source == InferenceSource.onDevice ? colors.primary : colors.tertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            StatusDot(color: dotColor, size: 10),
            Padding(
              padding: const EdgeInsets.only(left: Insets.xSmall),
              child: Text(sourceLabel(current.source), style: theme.textTheme.titleMedium),
            ),
            const Spacer(),
            if (elapsed != null) Text('${elapsed!.inMilliseconds} ms', style: theme.textTheme.labelSmall),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: SelectableText(current.text, style: theme.textTheme.bodyLarge),
        ),
      ],
    );
  }
}
