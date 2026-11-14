import 'package:material_ui/material_ui.dart';

import 'activity_tile.dart';
import 'column_rule.dart';
import 'stat_cell.dart';

/// The platform, the on-device model's name, and the time of the last check, in three columns separated by rules.
class StatusStats extends StatelessWidget {
  /// Creates the row.
  ///
  /// [modelName] and [checkedAt] show placeholders when they are null.
  const new({required this.platform, required this.modelName, required this.checkedAt, super.key});

  /// The name of the platform the app is running on.
  final String platform;

  /// The name the platform reports for the on-device model, or null if it does not report one.
  final String? modelName;

  /// When the last successful check finished, or null before the first one.
  final DateTime? checkedAt;

  /// Placeholder shown when a value is not available.
  static const String _empty = '–';

  @override
  Widget build(BuildContext context) {
    final DateTime? time = checkedAt;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: StatCell(label: 'Platform', value: platform),
          ),
          const ColumnRule(),
          Expanded(
            child: StatCell(label: 'Model', value: modelName ?? _empty),
          ),
          const ColumnRule(),
          Expanded(
            child: StatCell(label: 'Checked', value: time == null ? _empty : ActivityTile.formatTime(time)),
          ),
        ],
      ),
    );
  }
}
