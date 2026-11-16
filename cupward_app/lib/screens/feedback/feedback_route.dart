import 'package:material_ui/material_ui.dart';

import '../../models/brews/brew_record.dart';
import 'feedback_controller.dart';

/// The screen shown when a brew is done, where the user reviews the brew and gives feedback on it.
///
/// It opens in place of the brewing screen, so going back returns to the home screen. It shows the recipe that was
/// followed and a summary of [record], including the scale's readings when a scale was connected.
class FeedbackRoute extends StatefulWidget {
  /// Creates the screen for the finished brew described by [record].
  const FeedbackRoute({required this.record, super.key});

  /// What happened during the brew.
  final BrewRecord record;

  @override
  State<FeedbackRoute> createState() => FeedbackController();
}
