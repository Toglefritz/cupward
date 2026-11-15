/// Where the app stands with the BOOKOO scale.
enum ScaleConnectionStatus {
  /// The platform cannot reach a scale at all, for example in a web browser, where the Bluetooth plugin has no
  /// implementation.
  unsupported,

  /// No scale is connected, and nothing is in progress.
  disconnected,

  /// The app is looking for nearby scales.
  scanning,

  /// The app is connecting to a scale that the user picked.
  connecting,

  /// A scale is connected, and its readings are arriving.
  connected,
}
