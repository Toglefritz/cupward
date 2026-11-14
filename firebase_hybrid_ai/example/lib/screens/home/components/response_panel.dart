import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';
import 'status_dot.dart';

/// The model's response to the last prompt, with where it was generated and how long it took.
///
/// It shows the generated text, or the error if the request failed, or a hint before the first request. A streamed
/// response that fails partway shows the text that arrived, followed by the error.
class ResponsePanel extends StatelessWidget {
  /// Creates the panel.
  ///
  /// [result] and [elapsed] describe the last request. [errorMessage] describes a failed one and is shown after any
  /// text. All of them are null before the first request. [firstChunk] is how long a streamed response took to
  /// start, and is null for a response that was not streamed.
  const new({
    required this.result,
    required this.elapsed,
    required this.firstChunk,
    required this.errorMessage,
    super.key,
  });

  /// The last successful response, or null.
  final TextGenerationResult? result;

  /// How long the last successful request took, or null while it is running.
  final Duration? elapsed;

  /// How long a streamed response took to produce its first chunk, or null.
  final Duration? firstChunk;

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

    final Widget? errorText = error == null
        ? null
        : Text(error, style: theme.textTheme.bodyMedium?.copyWith(color: colors.error));

    if (current == null && errorText != null) {
      return errorText;
    }

    if (current == null) {
      return Text(
        'Responses appear here.',
        style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      );
    }

    // A streamed response shows when its first chunk arrived as well as the total, because the gap between them is
    // the reason to stream.
    final String? timing = _timing();

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
          ],
        ),
        // The timing has its own line. With both a first-chunk time and a total, it is too wide to share a row with
        // the source on a narrow phone.
        if (timing != null)
          Padding(
            padding: const EdgeInsets.only(top: Insets.xxSmall),
            child: Text(timing, style: theme.textTheme.labelSmall),
          ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: SelectableText(current.text, style: theme.textTheme.bodyLarge),
        ),
        // A streamed response that fails keeps the text that arrived, and the error follows it.
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: Insets.small),
            child: errorText,
          ),
      ],
    );
  }

  /// The timing label, such as "412 ms" or "first chunk 380 ms, total 1204 ms", or null if nothing has finished.
  String? _timing() {
    final Duration? first = firstChunk;
    final Duration? total = elapsed;

    if (first != null && total != null) {
      return 'first chunk ${first.inMilliseconds} ms, total ${total.inMilliseconds} ms';
    }

    if (first != null) {
      return 'first chunk ${first.inMilliseconds} ms';
    }

    return total == null ? null : '${total.inMilliseconds} ms';
  }
}
