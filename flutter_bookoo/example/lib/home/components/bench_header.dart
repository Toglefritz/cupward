import 'package:material_ui/material_ui.dart';

/// The screen title and the scale model it targets.
class BenchHeader extends StatelessWidget {
  /// Creates the header.
  const BenchHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Flutter + BOOKOO', style: text.headlineLarge),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('BOOKOO Themis Ultra', style: text.labelMedium),
        ),
      ],
    );
  }
}
