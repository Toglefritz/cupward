import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';

/// A vertical rule between stat columns, inset from the row's edges.
class ColumnRule extends StatelessWidget {
  /// Creates the rule.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(Insets.small),
      child: VerticalDivider(width: 1),
    );
  }
}
