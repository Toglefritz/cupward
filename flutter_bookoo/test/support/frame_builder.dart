import 'package:flutter_bookoo/flutter_bookoo.dart';

/// The sign byte for a positive value.
const int signPlus = 0x2B;

/// The sign byte for a negative value (ASCII minus).
const int signMinus = 0x2D;

/// Builds a 20-byte measurement frame with a correct checksum.
///
/// [weightHundredths] and [flowHundredths] are unsigned magnitudes in
/// hundredths of a gram and gram per second. The sign bytes are separate, as
/// on the wire.
List<int> buildMeasurementFrame({
  int milliseconds = 0,
  int weightSign = signPlus,
  int weightHundredths = 0,
  int flowSign = signPlus,
  int flowHundredths = 0,
  int battery = 100,
  int standbyTenths = 0,
  int beepLevel = 0,
  int smoothing = 0,
}) {
  final List<int> frame = <int>[
    BookooFrameDecoder.productNumber,
    BookooFrameDecoder.measurementType,
    (milliseconds >> 16) & 0xFF,
    (milliseconds >> 8) & 0xFF,
    milliseconds & 0xFF,
    0x01,
    weightSign,
    (weightHundredths >> 16) & 0xFF,
    (weightHundredths >> 8) & 0xFF,
    weightHundredths & 0xFF,
    flowSign,
    (flowHundredths >> 8) & 0xFF,
    flowHundredths & 0xFF,
    battery,
    (standbyTenths >> 8) & 0xFF,
    standbyTenths & 0xFF,
    beepLevel,
    smoothing,
    0x00,
    0x00,
  ];
  frame[19] = BookooFrameDecoder.checksum(frame);
  return frame;
}
