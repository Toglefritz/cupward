import 'package:material_ui/material_ui.dart';

import '../../models/brews/brew_record.dart';
import 'feedback_route.dart';
import 'feedback_view.dart';

/// State and behavior for [FeedbackRoute].
class FeedbackController extends State<FeedbackRoute> {
  /// What happened during the brew.
  BrewRecord get record => widget.record;

  @override
  Widget build(BuildContext context) => FeedbackView(this);
}
