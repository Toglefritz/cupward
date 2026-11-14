import '../exceptions/themis_frame_exception.dart';
import '../models/bookoo_scale_reading.dart';

/// Decodes the 20-byte notification frames a BOOKOO scale sends on its weight
/// characteristic.
///
/// Every frame has the same envelope. Byte 0 is the product number (`0x03`),
/// byte 1 is the message type, bytes 2 to 18 are payload, and byte 19 is an XOR
/// checksum of bytes 0 to 18. Multi-byte integers are big-endian.
///
/// Measurement frames (type `0x0B`) lay out as follows.
///
/// | Bytes | Meaning |
/// | --- | --- |
/// | 2 to 4 | Timer in milliseconds (unsigned 24-bit) |
/// | 5 | Weight unit (`01` gram, `02` ounce), unused because weight is always grams |
/// | 6 | Weight sign |
/// | 7 to 9 | Weight in hundredths of a gram (unsigned 24-bit) |
/// | 10 | Flow rate sign |
/// | 11 to 12 | Flow rate in hundredths of a gram per second (unsigned 16-bit) |
/// | 13 | Battery percent |
/// | 14 to 15 | Standby time in tenths of a minute (unsigned 16-bit) |
/// | 16 | Beep level |
/// | 17 | Flow smoothing switch |
abstract final class BookooFrameDecoder {
  /// The length of every frame.
  static const int frameLength = 20;

  /// The product number found in byte 0.
  static const int productNumber = 0x03;

  /// The message type of a measurement frame.
  static const int measurementType = 0x0B;

  /// The sign byte value that is the ASCII code for a minus sign.
  static const int _signMinusAscii = 0x2D;

  /// The sign byte value that some firmware uses to flag a negative number.
  static const int _signNegativeFlag = 0x01;

  /// Milliseconds represented by one unit of the standby time field (0.1 min).
  static const int _standbyUnitMilliseconds = 6000;

  /// Computes the XOR checksum over the first [frameLength] - 1 bytes of
  /// [frame].
  static int checksum(List<int> frame) {
    int result = 0;
    for (int i = 0; i < frameLength - 1; i++) {
      result ^= frame[i];
    }
    return result;
  }

  /// Decodes [frame] into a reading.
  ///
  /// Returns null for a valid frame of a type that is not a measurement, such
  /// as powder weight or automatic-mode events, which are not decoded here.
  ///
  /// Throws [ThemisFrameException] when [frame] is not 20 bytes, does not start
  /// with the product number, or fails the checksum.
  static BookooScaleReading? decode(List<int> frame) {
    if (frame.length != frameLength) {
      throw ThemisFrameException('Expected $frameLength bytes but received ${frame.length}.');
    }

    if (frame[0] != productNumber) {
      throw ThemisFrameException('Unexpected product number 0x${frame[0].toRadixString(16)}.');
    }

    final int expected = checksum(frame);
    if (frame[frameLength - 1] != expected) {
      throw ThemisFrameException(
        'Checksum mismatch: frame has 0x${frame[frameLength - 1].toRadixString(16)}, '
        'computed 0x${expected.toRadixString(16)}.',
      );
    }

    if (frame[1] != measurementType) {
      return null;
    }

    final int milliseconds = _uint24(frame, 2);
    final double weight = _uint24(frame, 7) / 100 * _sign(frame[6]);
    final double flow = _uint16(frame, 11) / 100 * _sign(frame[10]);

    return BookooScaleReading(
      elapsed: Duration(milliseconds: milliseconds),
      weightGrams: weight,
      flowRateGramsPerSecond: flow,
      batteryPercent: frame[13],
      standbyTime: Duration(milliseconds: _uint16(frame, 14) * _standbyUnitMilliseconds),
      beepLevel: frame[16],
      flowSmoothingEnabled: frame[17] == 1,
    );
  }

  /// Returns -1 when [signByte] marks a negative value, otherwise 1.
  ///
  /// The protocol documents the sign only as "+/-". Both an ASCII minus and a
  /// `0x01` flag are treated as negative, and anything else, including ASCII
  /// plus and zero, as positive.
  static int _sign(int signByte) {
    return signByte == _signMinusAscii || signByte == _signNegativeFlag ? -1 : 1;
  }

  /// Reads an unsigned big-endian 16-bit integer at [offset].
  static int _uint16(List<int> bytes, int offset) => (bytes[offset] << 8) | bytes[offset + 1];

  /// Reads an unsigned big-endian 24-bit integer at [offset].
  static int _uint24(List<int> bytes, int offset) => (bytes[offset] << 16) | _uint16(bytes, offset + 1);
}
