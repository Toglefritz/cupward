import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';

/// A progress bar for a model download, with the percentage beside it.
class DownloadProgressBar extends StatelessWidget {
  /// Creates a bar filled to [fraction], which runs from 0.0 to 1.0.
  const new({required this.fraction, super.key});

  /// How much of the download has finished, from 0.0 to 1.0.
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Expanded(
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: Insets.xSmall,
            borderRadius: BorderRadius.circular(Insets.xxSmall),
            backgroundColor: theme.colorScheme.outlineVariant,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: Insets.small),
          child: Text('${(fraction * 100).round()}%', style: theme.textTheme.labelSmall),
        ),
      ],
    );
  }
}
