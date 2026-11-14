import 'dart:convert';

import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';

/// Shows a schema as indented JSON, so the user can see what shape the response must have.
class SchemaPreview extends StatelessWidget {
  /// Creates the preview of [schema].
  const new({required this.schema, super.key});

  /// The schema shown.
  final ResponseSchema schema;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(Insets.small),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(Insets.xSmall),
      ),
      child: SelectableText(
        const JsonEncoder.withIndent('  ').convert(schema.toJson()),
        style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurface),
      ),
    );
  }
}
