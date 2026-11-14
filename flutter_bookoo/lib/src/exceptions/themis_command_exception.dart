import 'themis_exception.dart';

/// Thrown when a command could not be delivered to a scale.
///
/// This covers a GATT write that the platform rejects or that fails before the
/// scale acknowledges it, and a command sent after `ThemisUltra.disconnect`.
/// The connection is usually still usable after a failed write, so retrying is
/// reasonable. If the scale has disconnected, connect again first.
///
/// A successful write means the scale received the command, not that it acted
/// on it. The scale ignores some commands in some modes, for example tare
/// during an automatic-mode extraction.
class ThemisCommandException extends ThemisException {
  /// Creates an exception with a developer-facing [message].
  const new(super.message);
}
