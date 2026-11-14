import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:material_ui/material_ui.dart';

import 'components/activity_tile.dart';
import 'components/bench_header.dart';
import 'components/connected_section.dart';
import 'components/connection_status_row.dart';
import 'components/discovery_section.dart';
import 'components/section_header.dart';
import 'home_controller.dart';

/// Layout for the example screen. Contains no logic.
///
/// While connected, the screen shows the live weight, the secondary readings,
/// and the tare control. Otherwise it shows scan results and a scan button.
/// The activity log follows in both states.
class HomeView extends StatelessWidget {
  /// Creates the view for [state].
  const HomeView(this.state, {super.key});

  /// The controller supplying data and callbacks.
  final HomeController state;

  /// The widest the content column grows on large windows.
  static const double _maxContentWidth = 560;

  /// Horizontal page margin.
  static const double _margin = 28;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ThemisUltra? scale = state.scale;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(_margin, 32, _margin, 0),
                  sliver: SliverList.list(
                    children: <Widget>[
                      const BenchHeader(),
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Divider(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: ConnectionStatusRow(
                          isConnected: scale != null,
                          isBusy: state.isScanning || state.isConnecting,
                          busyLabel: state.isConnecting
                              ? 'Connecting'
                              : 'Scanning',
                          deviceName: scale?.device.name,
                          onDisconnect: scale == null
                              ? null
                              : state.onDisconnectPressed,
                        ),
                      ),
                      if (scale != null)
                        ConnectedSection(state: state)
                      else
                        DiscoverySection(state: state),
                      Padding(
                        padding: const EdgeInsets.only(top: 36),
                        child: SectionHeader(title: 'Activity'),
                      ),
                      if (state.activity.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Nothing yet.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(_margin, 0, _margin, 32),
                  sliver: SliverList.separated(
                    itemCount: state.activity.length,
                    itemBuilder: (BuildContext context, int index) =>
                        ActivityTile(entry: state.activity[index]),
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
