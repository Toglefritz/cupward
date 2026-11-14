import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:firebase_hybrid_ai/src/web/chrome_availability.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the conversion of Chrome's availability strings. This logic has no browser dependency, so it runs on
/// the VM.
void main() {
  group('parseChromeAvailability', () {
    /// The four values documented for the Prompt API must each map to their counterpart.
    test('maps the documented Chrome values', () {
      expect(parseChromeAvailability('available'), OnDeviceModelAvailability.available);
      expect(parseChromeAvailability('downloadable'), OnDeviceModelAvailability.downloadable);
      expect(parseChromeAvailability('downloading'), OnDeviceModelAvailability.downloading);
      expect(parseChromeAvailability('unavailable'), OnDeviceModelAvailability.unavailable);
    });

    /// A browser without the Prompt API passes null, which must read as unavailable and not as an error.
    test('maps null to unavailable', () {
      expect(parseChromeAvailability(null), OnDeviceModelAvailability.unavailable);
    });

    /// A value added to Chrome later must not be treated as usable.
    test('maps an unrecognized value to unavailable', () {
      expect(parseChromeAvailability('something-new'), OnDeviceModelAvailability.unavailable);
    });
  });
}
