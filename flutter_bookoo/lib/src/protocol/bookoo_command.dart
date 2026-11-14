import 'package:flutter/foundation.dart';

/// A command that can be written to a BOOKOO scale's command characteristic.
///
/// Every command is six bytes: the product number (`0x03`), the command type
/// (`0x0A`), a command code, two data bytes, and an XOR checksum of the first
/// five bytes.
@immutable
class BookooCommand {
  /// Creates a command from its [code] and the data bytes [data1] and [data2].
  ///
  /// Private so that only documented commands, such as [tare], can be sent.
  /// Each value must fit in one byte.
  const new _(this.code, this.data1, this.data2);

  /// Zeroes the scale at its current load.
  ///
  /// The scale ignores this during an automatic-mode extraction, in automatic
  /// done, and while charging.
  static const BookooCommand tare = BookooCommand._(0x01, 0x00, 0x00);

  /// The product number in byte 0 of every command.
  static const int productNumber = 0x03;

  /// The message type in byte 1 of every command.
  static const int commandType = 0x0A;

  /// The command code in byte 2.
  final int code;

  /// The first data byte, byte 3.
  final int data1;

  /// The second data byte, byte 4.
  final int data2;

  /// The six bytes to write, including the checksum.
  List<int> get bytes {
    final List<int> body = <int>[productNumber, commandType, code, data1, data2];
    final int checksum = body.fold(0, (result, byte) => result ^ byte);
    return List<int>.unmodifiable(<int>[...body, checksum]);
  }

  @override
  bool operator ==(Object other) {
    return other is BookooCommand && other.code == code && other.data1 == data1 && other.data2 == data2;
  }

  @override
  int get hashCode => Object.hash(code, data1, data2);

  @override
  String toString() {
    final String hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');
    return 'BookooCommand($hex)';
  }
}
