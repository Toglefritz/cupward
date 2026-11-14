import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';

import 'themis_exception.dart';

/// Thrown when a connection to a scale cannot be established.
///
/// This covers connection failures reported by the platform, timeouts while connecting, and failures while discovering
/// services. Retrying is usually reasonable, after confirming the scale is awake and in range.
class ThemisConnectionException extends ThemisException {
  /// Creates an exception with a developer-facing [message] and optional platform [failure] detail.
  const new(
    super.message, {
    this.failure,
  });

  /// Failure detail reported by the platform, or null when the failure did not come from the platform (for example a
  /// timeout).
  ///
  /// Raw codes and descriptions in this value are for diagnostics and should not be shown to users.
  final BleConnectionFailure? failure;
}
