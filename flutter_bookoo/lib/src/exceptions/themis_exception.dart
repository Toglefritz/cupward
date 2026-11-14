/// Base type for errors raised by `flutter_bookoo`.
///
/// Catch this type to handle any package-level failure, or catch a subtype to respond to a specific condition.
abstract class ThemisException implements Exception {
  /// Creates an exception with a developer-facing [message].
  const new(
    this.message,
  );

  /// A description of what went wrong. It is intended for logs and developers, not for display to end users.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}
