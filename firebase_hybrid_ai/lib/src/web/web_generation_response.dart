import 'package:meta/meta.dart';

/// The text and source that the Firebase AI Logic JavaScript SDK returned for one request.
@immutable
class WebGenerationResponse {
  /// Creates a response with the generated [text] and the SDK's name for the [source].
  const new({required this.text, required this.source});

  /// The generated text.
  final String text;

  /// The value of the SDK's `inferenceSource` property, such as `ON_DEVICE` or `IN_CLOUD`.
  final String source;
}
