import 'package:material_ui/material_ui.dart';

import '../../theme/insets.dart';
import 'components/activity_tile.dart';
import 'components/check_status_row.dart';
import 'components/header.dart';
import 'components/model_status_section.dart';
import 'components/section_header.dart';
import 'home_controller.dart';

/// Layout for the example screen. Contains no logic.
///
/// The screen shows the state of the status check, the on-device model's availability, supporting values, and a button
/// to check again. The activity log follows.
class HomeView extends StatelessWidget {
  /// Creates the view for [state].
  const new(this.state, {super.key});

  /// The controller supplying data and callbacks.
  final HomeController state;

  /// The widest the content column grows on large windows.
  static const double _maxContentWidth = 560;

  /// Horizontal page margin.
  static const double _margin = 28;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(_margin, Insets.large, _margin, 0),
                  sliver: SliverList.list(
                    children: <Widget>[
                      const Header(),
                      const Padding(padding: EdgeInsets.only(top: Insets.medium), child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: Insets.xSmall),
                        child: CheckStatusRow(isChecking: state.isChecking, hasFailed: state.errorMessage != null),
                      ),
                      ModelStatusSection(state: state),
                      const Padding(
                        padding: EdgeInsets.only(top: Insets.large),
                        child: SectionHeader(title: 'Activity'),
                      ),
                      if (state.activity.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: Insets.small),
                          child: Text(
                            'Nothing yet.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(_margin, 0, _margin, Insets.large),
                  sliver: SliverList.separated(
                    itemCount: state.activity.length,
                    itemBuilder: (BuildContext context, int index) => ActivityTile(entry: state.activity[index]),
                    separatorBuilder: (BuildContext context, int index) =>
                        Divider(color: theme.colorScheme.outlineVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
