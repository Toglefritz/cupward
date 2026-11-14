import 'package:material_ui/material_ui.dart';

/// The screen title and the capability it demonstrates.
class Header extends StatelessWidget {
  /// Creates the header.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Hybrid AI', style: text.headlineLarge),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('Firebase AI Logic', style: text.labelMedium),
        ),
      ],
    );
  }
}
