/// GATT identifiers and advertisement conventions for the BOOKOO Themis Ultra.
///
/// The scale uses 16-bit UUIDs from the Bluetooth base UUID range. Platforms report the same UUID in different shapes
/// (for example `FF12`, `ff12`, or `0000ff12-0000-1000-8000-00805f9b34fb`), so comparisons should go through
/// [normalizeUuid].
abstract final class ThemisUltraGatt {
  /// The 16-bit UUID of the primary service that carries all scale traffic.
  static const String serviceUuid = '0FFE';

  /// The 16-bit UUID of the characteristic the app writes commands to.
  static const String commandCharacteristicUuid = 'FF12';

  /// The 16-bit UUID of the characteristic that notifies weight, flow rate, timer, and battery data.
  static const String weightCharacteristicUuid = 'FF11';

  /// The default advertised name prefix used to recognize BOOKOO scales.
  static const String advertisedNamePrefix = 'BOOKOO';

  /// The suffix shared by every 128-bit UUID derived from a 16-bit UUID.
  static const String _baseUuidSuffix = '-0000-1000-8000-00805f9b34fb';

  /// Converts [uuid] to a lowercase canonical form for comparison.
  ///
  /// 16-bit UUIDs, 32-bit UUIDs with a zero prefix, and 128-bit UUIDs built on the Bluetooth base UUID all normalize to
  /// the 4-character short form (for example `ff12`). Any other UUID is returned lowercased and unchanged.
  static String normalizeUuid(
    String uuid,
  ) {
    final String lower = uuid.trim().toLowerCase();

    if (lower.length == 4) {
      return lower;
    }

    if (lower.length == 8 &&
        lower.startsWith(
          '0000',
        )) {
      return lower.substring(
        4,
      );
    }

    if (lower.length == 36 &&
        lower.startsWith(
          '0000',
        ) &&
        lower.endsWith(
          _baseUuidSuffix,
        )) {
      return lower.substring(
        4,
        8,
      );
    }

    return lower;
  }

  /// Returns whether [a] and [b] identify the same UUID after normalization.
  static bool uuidsMatch(
    String a,
    String b,
  ) =>
      normalizeUuid(
        a,
      ) ==
      normalizeUuid(
        b,
      );
}
