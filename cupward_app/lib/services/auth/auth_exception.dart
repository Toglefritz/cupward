import 'auth_failure.dart';

/// Thrown when the app could not sign in. [failure] says why.
class AuthException implements Exception {
  /// Creates an exception for [failure].
  const AuthException(this.failure);

  /// Why signing in failed.
  final AuthFailure failure;

  @override
  String toString() => 'AuthException(${failure.name})';
}
