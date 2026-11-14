import 'package:meta/meta.dart';

import '../messages.g.dart';

/// A response that was requested with a schema, with the decoded value and whether it conforms.
///
/// Every platform returns this same contract. [isSchemaEnforced] says whether the platform constrained the model to
/// the schema while it generated, and [violations] says whether the output actually conforms, which the plugin checks
/// on every platform. A response can be unenforced and still conform, and callers that need conforming data should
/// check [conformsToSchema].
@immutable
class StructuredGenerationResult {
  /// Creates a result.
  const new({
    required this.text,
    required this.data,
    required this.source,
    required this.isSchemaEnforced,
    required this.violations,
  });

  /// The text that the model returned, before it was decoded.
  final String text;

  /// The decoded JSON value, such as a `Map<String, Object?>` for an object schema, or null if [text] is not JSON.
  final Object? data;

  /// Whether the on-device model or the cloud model generated the response.
  final InferenceSource source;

  /// Whether the platform constrained the model's output to the schema.
  ///
  /// When this is false, the schema was given to the model as instructions in the prompt, and only the plugin's
  /// validation checked the output. On Android, on-device and hybrid requests are not enforced, because the platform
  /// only supports schemas that are compiled into the app.
  final bool isSchemaEnforced;

  /// A description of each way that the output does not match the schema. Empty when it conforms.
  final List<String> violations;

  /// Whether the output is valid JSON that matches the schema.
  bool get conformsToSchema => violations.isEmpty;
}
