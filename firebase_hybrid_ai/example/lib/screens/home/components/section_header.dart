import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';

/// A section title over a full-width rule.
class SectionHeader extends StatelessWidget {
  /// Creates a header reading [title], with an optional [trailing] widget on the right.
  const new({required this.title, this.trailing, super.key});

  /// The section name.
  final String title;

  /// A widget aligned to the end of the title row, such as a progress indicator.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: Insets.small),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}
