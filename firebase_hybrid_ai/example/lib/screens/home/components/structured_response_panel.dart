import 'dart:convert';

import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';
import 'response_panel.dart';
import 'status_dot.dart';

/// The result of a structured request: where it was generated, whether the schema was enforced and met, the fields
/// of the response, and the JSON itself.
class StructuredResponsePanel extends StatelessWidget {
  /// Creates the panel for [result], or the error of a failed request in [errorMessage].
  ///
  /// [elapsed] is how long the request took. Before the first request, both [result] and [errorMessage] are null.
  const new({required this.result, required this.elapsed, required this.errorMessage, super.key});

  /// The last structured response, or null.
  final StructuredGenerationResult? result;

  /// How long the last request took, or null.
  final Duration? elapsed;

  /// A description of the last failure, or null if the last request succeeded.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final StructuredGenerationResult? current = result;

    if (errorMessage != null) {
      return Text(errorMessage!, style: theme.textTheme.bodyMedium?.copyWith(color: colors.error));
    }

    if (current == null) {
      return Text(
        'Structured responses appear here.',
        style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      );
    }

    final Object? data = current.data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            StatusDot(
              color: current.source == InferenceSource.onDevice ? colors.primary : colors.tertiary,
              size: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(left: Insets.xSmall),
              child: Text(ResponsePanel.sourceLabel(current.source), style: theme.textTheme.titleMedium),
            ),
          ],
        ),
        if (elapsed != null)
          Padding(
            padding: const EdgeInsets.only(top: Insets.xxSmall),
            child: Text('${elapsed!.inMilliseconds} ms', style: theme.textTheme.labelSmall),
          ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          // Enforcement and conformance are separate facts, so each has its own line: a response can be unenforced and
          // still conform.
          child: Text(
            current.isSchemaEnforced ? 'Schema enforced by the platform' : 'Schema described in the prompt',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.xxSmall),
          child: Text(
            current.conformsToSchema ? 'Matches the schema' : 'Does not match the schema',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: current.conformsToSchema ? colors.primary : colors.error,
            ),
          ),
        ),
        for (final String violation in current.violations)
          Padding(
            padding: const EdgeInsets.only(top: Insets.xxSmall),
            child: Text(violation, style: theme.textTheme.bodyMedium?.copyWith(color: colors.error)),
          ),
        if (data is Map<String, Object?>)
          for (final MapEntry<String, Object?> field in data.entries)
            Padding(
              padding: const EdgeInsets.only(top: Insets.small),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(field.key, style: theme.textTheme.labelSmall),
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.micro),
                    child: SelectableText(_fieldText(field.value), style: theme.textTheme.bodyLarge),
                  ),
                ],
              ),
            ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.medium),
          child: Container(
            padding: const EdgeInsets.all(Insets.small),
            decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(Insets.xSmall),
            ),
            child: SelectableText(
              _jsonText(current),
              style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurface),
            ),
          ),
        ),
      ],
    );
  }

  /// A field's value as display text: lists as one item per line, and everything else as written.
  static String _fieldText(Object? value) {
    if (value is List<Object?>) {
      return value.map((Object? item) => '• $item').join('\n');
    }

    return '$value';
  }

  /// The response as indented JSON, or the raw text when it could not be decoded.
  static String _jsonText(StructuredGenerationResult result) {
    if (result.data == null) {
      return result.text;
    }

    return const JsonEncoder.withIndent('  ').convert(result.data);
  }
}
