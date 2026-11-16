/// Why brew feedback could not be produced. Screens show a localized message for each.
enum BrewFeedbackFailure {
  /// The platform cannot run hybrid inference, such as iOS and macOS today.
  unsupported,

  /// The request failed, for example because the device is offline and the on-device model cannot answer.
  requestFailed,

  /// The model answered, but not in the expected shape, even after the cloud model was asked.
  invalidResponse,
}
