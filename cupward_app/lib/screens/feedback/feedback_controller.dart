import 'package:material_ui/material_ui.dart';

import '../../models/brews/brew_record.dart';
import '../../models/brews/taste_attribute.dart';
import '../../models/brews/tasting_notes.dart';
import 'feedback_route.dart';
import 'feedback_view.dart';

/// State and behavior for [FeedbackRoute].
///
/// The controller holds the user's tasting notes while they fill in the form. Ratings are kept in [TastingNotes], and
/// the goal text in [goalController], which the text field edits directly. [tastingNotes] combines the two, ready to
/// be sent with the [record] for brew feedback.
class FeedbackController extends State<FeedbackRoute> {
  /// What happened during the brew.
  BrewRecord get record => widget.record;

  /// Holds the text of the goal field.
  final TextEditingController goalController = TextEditingController();

  /// The ratings so far.
  TastingNotes _ratings = TastingNotes();

  /// The tasting notes as the user has filled them in so far, including the goal text.
  TastingNotes get tastingNotes => _ratings.withGoal(goalController.text);

  /// Handles a move of the slider for [attribute] by recording [rating].
  void onRatingChanged(TasteAttribute attribute, int rating) {
    setState(() => _ratings = _ratings.withRating(attribute, rating));
  }

  @override
  void dispose() {
    goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FeedbackView(this);
}
