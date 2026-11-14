import 'themis_exception.dart';

/// Thrown when Bluetooth cannot be used for a scan.
///
/// Common causes are a disabled or missing Bluetooth adapter and denied Bluetooth permissions. The caller should ask
/// the user to enable Bluetooth or grant permission in system settings, then try again.
class ThemisBluetoothUnavailableException extends ThemisException {
  /// Creates an exception with a developer-facing [message].
  const new(
    super.message,
  );
}
