import 'package:material_ui/material_ui.dart';

import '../../../models/recipes/brew_method.dart';
import '../../../theme/insets.dart';
import 'brew_method_card.dart';

/// A grid of cards, one for each brewing method, of which the user picks one.
///
/// It has two columns on phones and three on wider screens. The cards in a row share the height of the tallest, so the
/// grid stays even when a description wraps to more lines.
class BrewMethodPicker extends StatelessWidget {
  /// Creates a picker with [selected] chosen, or none when it is null.
  const BrewMethodPicker({required this.selected, required this.onSelected, super.key});

  /// The chosen method, or null if none has been chosen.
  final BrewMethod? selected;

  /// Called with the method the user tapped.
  final ValueChanged<BrewMethod> onSelected;

  /// The narrowest width at which three columns fit.
  static const double _threeColumnMinWidth = 560;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= _threeColumnMinWidth ? 3 : 2;
        const List<BrewMethod> methods = BrewMethod.values;

        return Column(
          children: <Widget>[
            for (int start = 0; start < methods.length; start += columns)
              Padding(
                padding: EdgeInsets.only(top: start == 0 ? 0 : Insets.xSmall),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (int column = 0; column < columns; column++) ...<Widget>[
                        if (column > 0) const SizedBox(width: Insets.xSmall),
                        Expanded(
                          child: start + column < methods.length
                              ? BrewMethodCard(
                                  method: methods[start + column],
                                  isSelected: selected == methods[start + column],
                                  onPressed: () => onSelected(methods[start + column]),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
