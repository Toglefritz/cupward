/// Base class for errors reported by this plugin.
///
/// This type is thrown directly when the host platform reports a failure that has no more specific type. The
/// [code] and [details] come from the platform and are meant for logging. They are not suitable for display to
/// users.
class FirebaseHybridAiException implements Exception {
  /// Creates an exception with a platform error [code] and an optional [message] and [details].
  const new({required this.code, this.message, this.details});

  /// A short, stable identifier for the failure, as reported by the host platform.
  final String code;

  /// A description of the failure, or null if the platform did not provide one.
  final String? message;

  /// Platform-specific diagnostic information, or null. This may contain internal details.
  final String? details;

  @override
  String toString() => 'FirebaseHybridAiException($code${message == null ? '' : ': $message'})';
}
