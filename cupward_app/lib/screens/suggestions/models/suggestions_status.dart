/// Where the brew feedback screen stands with its request.
enum SuggestionsStatus {
  /// The feedback is being prepared.
  loading,

  /// The feedback has arrived.
  loaded,

  /// The feedback could not be produced.
  failed,
}
