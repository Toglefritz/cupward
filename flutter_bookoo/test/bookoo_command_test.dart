/// Tests for `BookooCommand` byte encoding.
///
/// Pure Dart, with no Bluetooth classes or mocks involved.
library;

import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// The tare command must match the protocol document byte for byte,
  /// including the XOR checksum (03 ^ 0A ^ 01 ^ 00 ^ 00 = 08).
  test('tare encodes as 03 0A 01 00 00 08', () {
    expect(BookooCommand.tare.bytes, <int>[0x03, 0x0A, 0x01, 0x00, 0x00, 0x08]);
  });

  /// The bytes are shared, so callers must not be able to alter them.
  test('bytes are unmodifiable', () {
    expect(() => BookooCommand.tare.bytes[0] = 0, throwsUnsupportedError);
  });
}
