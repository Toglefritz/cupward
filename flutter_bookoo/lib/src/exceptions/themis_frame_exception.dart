import 'themis_exception.dart';

/// Thrown when bytes received from a scale are not a valid protocol frame.
///
/// Causes include a truncated notification, a corrupted payload that fails the
/// checksum, and bytes that do not belong to the Themis protocol. A single bad
/// frame is not fatal. The next notification usually decodes normally, so
/// callers can drop the frame and continue.
class ThemisFrameException extends ThemisException {
  /// Creates an exception describing why a frame was rejected.
  const new(super.message);
}
