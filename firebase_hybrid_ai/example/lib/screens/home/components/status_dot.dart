import 'package:material_ui/material_ui.dart';

/// A small filled circle that signals state by color.
class StatusDot extends StatelessWidget {
  /// Creates a dot filled with [color].
  const new({required this.color, this.size = 12, super.key});

  /// The fill color.
  final Color color;

  /// The diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
