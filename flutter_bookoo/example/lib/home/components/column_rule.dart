import 'package:material_ui/material_ui.dart';

/// A vertical rule between stat columns, inset from the row's edges.
class ColumnRule extends StatelessWidget {
  /// Creates the rule.
  const ColumnRule({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 12, right: 16, top: 18, bottom: 18),
      child: VerticalDivider(width: 1),
    );
  }
}
