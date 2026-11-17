/// Why a new recipe could not be created. Screens show a localized message for each.
enum RecipeGenerationFailure {
  /// The platform cannot run hybrid inference, such as iOS and macOS today.
  unsupported,

  /// The request failed, for example because the device is offline and the on-device model cannot answer.
  requestFailed,

  /// The model answered, but not with a brewable recipe, even after the cloud model was asked.
  invalidResponse,

  /// The recipe was created but could not be saved.
  saveFailed,
}
