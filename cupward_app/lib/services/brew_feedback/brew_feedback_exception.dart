import 'brew_feedback_failure.dart';

/// Thrown when brew feedback could not be produced. [failure] says why.
class BrewFeedbackException implements Exception {
  /// Creates an exception for [failure].
  const BrewFeedbackException(this.failure);

  /// Why the feedback could not be produced.
  final BrewFeedbackFailure failure;

  @override
  String toString() => 'BrewFeedbackException(${failure.name})';
}
