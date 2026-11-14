import 'package:flutter/foundation.dart';

/// One line in the on-screen activity log.
@immutable
class ActivityEntry {
  /// Creates an entry recorded at [time].
  const new({
    required this.time,
    required this.message,
    this.isError = false,
  });

  /// When the event happened, in local time.
  final DateTime time;

  /// A short description of what happened.
  final String message;

  /// Whether the entry reports a failure, which is shown in the error color.
  final bool isError;
}
