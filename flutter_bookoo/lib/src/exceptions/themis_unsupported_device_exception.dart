import 'themis_exception.dart';

/// Thrown when a connected device does not expose the GATT layout of a Themis Ultra.
///
/// This happens when the device is not a Themis scale, or when its firmware exposes a different layout than this
/// package expects. The package disconnects before throwing. Retrying will not help.
class ThemisUnsupportedDeviceException extends ThemisException {
  /// Creates an exception for the device at [address] with the list of [problems] found during verification.
  new({
    required this.address,
    required List<String> problems,
  }) : problems = List<String>.unmodifiable(
         problems,
       ),
       super(
         'Device $address does not look like a Themis Ultra: ${problems.join('; ')}.',
       );

  /// The platform identifier of the rejected device.
  final String address;

  /// One entry per missing service, missing characteristic, or missing characteristic capability.
  final List<String> problems;
}
