/// Why the last scan or connection attempt failed, so that screens can show a message the user can act on.
///
/// The exceptions from `flutter_bookoo` carry messages written for developers, so screens show a localized message
/// for the failure's kind instead.
enum ScaleFailure {
  /// Bluetooth is off, or the app is not allowed to use it.
  bluetoothUnavailable,

  /// The scale could not be reached, for example because it is off, asleep, or out of range.
  connectionFailed,

  /// The device connected, but it is not a scale that the app supports.
  unsupportedDevice,

  /// Something else went wrong. The details are in the debug log.
  unknown,
}
