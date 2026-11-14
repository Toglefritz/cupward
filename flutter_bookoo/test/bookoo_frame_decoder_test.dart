/// Tests for `BookooFrameDecoder`, the pure Dart decoder for 0x0B frames.
///
/// No Bluetooth classes are involved. Frames are built byte by byte with
/// `buildMeasurementFrame`, and any frames captured from hardware and stored
/// under `test/fixtures/frames` are decoded as well.
library;

import 'dart:io';

import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/frame_builder.dart';

void main() {
  /// Field-by-field decoding of a valid frame.
  group('decode', () {
    /// Every field must land in the right unit, so each uses a distinct value.
    test('decodes all fields of a valid frame', () {
      // Arrange
      final List<int> frame = buildMeasurementFrame(
        milliseconds: 0x01E240, // 123,456 ms
        weightHundredths: 25034,
        flowHundredths: 412,
        battery: 87,
        standbyTenths: 300,
        beepLevel: 2,
        smoothing: 1,
      );

      // Act
      final BookooScaleReading? reading = BookooFrameDecoder.decode(frame);

      // Assert
      expect(reading, isNotNull);
      expect(reading!.elapsed, const Duration(milliseconds: 123456));
      expect(reading.weightGrams, 250.34);
      expect(reading.flowRateGramsPerSecond, 4.12);
      expect(reading.batteryPercent, 87);
      expect(reading.standbyTime, const Duration(minutes: 30));
      expect(reading.beepLevel, 2);
      expect(reading.flowSmoothingEnabled, isTrue);
    });

    /// Weight removed after taring must decode as a negative number.
    test('decodes negative weight and flow', () {
      // Arrange
      final List<int> frame = buildMeasurementFrame(
        weightSign: signMinus,
        weightHundredths: 1250,
        flowSign: signMinus,
        flowHundredths: 75,
      );

      // Act
      final BookooScaleReading? reading = BookooFrameDecoder.decode(frame);

      // Assert
      expect(reading!.weightGrams, -12.5);
      expect(reading.flowRateGramsPerSecond, -0.75);
    });

    /// A 0x01 flag is also treated as negative, and zero as positive.
    test('accepts alternate sign encodings', () {
      // Act
      final BookooScaleReading? flagged = BookooFrameDecoder.decode(
        buildMeasurementFrame(weightSign: 0x01, weightHundredths: 500),
      );
      final BookooScaleReading? zero = BookooFrameDecoder.decode(
        buildMeasurementFrame(weightSign: 0x00, weightHundredths: 500),
      );

      // Assert
      expect(flagged!.weightGrams, -5);
      expect(zero!.weightGrams, 5);
    });

    /// The largest 24-bit weight must not overflow into the sign.
    test('decodes the maximum 24-bit weight', () {
      final BookooScaleReading? reading = BookooFrameDecoder.decode(buildMeasurementFrame(weightHundredths: 0xFFFFFF));

      expect(reading!.weightGrams, closeTo(167772.15, 0.001));
    });

    /// A frame cut short in transit must be rejected, not misread.
    test('rejects a truncated frame', () {
      final List<int> frame = buildMeasurementFrame(weightHundredths: 100).sublist(0, 12);

      expect(() => BookooFrameDecoder.decode(frame), throwsA(isA<ThemisFrameException>()));
    });

    /// An over-long payload is also not a valid frame.
    test('rejects an oversized frame', () {
      final List<int> frame = <int>[...buildMeasurementFrame(), 0];

      expect(() => BookooFrameDecoder.decode(frame), throwsA(isA<ThemisFrameException>()));
    });

    /// A flipped bit must be caught by the checksum.
    test('rejects a bad checksum', () {
      final List<int> frame = buildMeasurementFrame(weightHundredths: 100);
      frame[8] ^= 0x01;

      expect(
        () => BookooFrameDecoder.decode(frame),
        throwsA(isA<ThemisFrameException>().having((e) => e.message, 'message', contains('Checksum'))),
      );
    });

    /// Bytes from another protocol must not be decoded.
    test('rejects a wrong product number', () {
      final List<int> frame = buildMeasurementFrame();
      frame[0] = 0x04;
      frame[19] = BookooFrameDecoder.checksum(frame);

      expect(() => BookooFrameDecoder.decode(frame), throwsA(isA<ThemisFrameException>()));
    });

    /// Valid frames of other types, such as powder weight, are not readings.
    test('returns null for a valid non-measurement frame', () {
      final List<int> frame = buildMeasurementFrame();
      frame[1] = 0x0F;
      frame[19] = BookooFrameDecoder.checksum(frame);

      expect(BookooFrameDecoder.decode(frame), isNull);
    });
  });

  /// Frames captured from a real scale, one hex-encoded frame per line.
  group('captured fixtures', () {
    /// Every captured measurement frame must decode, so a regression in the
    /// decoder or a firmware change shows up against real data.
    test('all frames in test/fixtures/frames decode', () {
      // Arrange
      final Directory directory = Directory('test/fixtures/frames');
      if (!directory.existsSync()) {
        return;
      }

      // Act and assert
      for (final File file in directory.listSync().whereType<File>().where((f) => f.path.endsWith('.hex'))) {
        for (final String line in file.readAsLinesSync().map((l) => l.trim()).where((l) => l.isNotEmpty)) {
          final List<int> frame = <int>[
            for (int i = 0; i < line.length; i += 2) int.parse(line.substring(i, i + 2), radix: 16),
          ];
          expect(() => BookooFrameDecoder.decode(frame), returnsNormally, reason: '${file.path}: $line');
        }
      }
    });
  });
}
