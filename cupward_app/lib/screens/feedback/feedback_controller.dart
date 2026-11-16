import 'package:material_ui/material_ui.dart';

import '../../models/brews/brew_record.dart';
import '../../models/brews/taste_attribute.dart';
import '../../models/brews/tasting_notes.dart';
import '../suggestions/suggestions_route.dart';
import 'feedback_route.dart';
import 'feedback_view.dart';

/// State and behavior for [FeedbackRoute].
///
/// The controller holds the user's tasting notes while they fill in the form. Ratings are kept in [TastingNotes], and
/// the goal text in [goalController], which the text field edits directly. [tastingNotes] combines the two. When the
/// user asks for feedback, they are sent with the [record] to the brew feedback screen.
class FeedbackController extends State<FeedbackRoute> {
  /// What happened during the brew.
  BrewRecord get record => widget.record;

  /// Holds the text of the goal field.
  final TextEditingController goalController = TextEditingController();

  /// The ratings so far.
  TastingNotes _ratings = TastingNotes();

  /// The tasting notes as the user has filled them in so far, including the goal text.
  TastingNotes get tastingNotes => _ratings.withGoal(goalController.text);

  /// Whether the user has filled in enough to ask for feedback: at least one rating, or a goal.
  bool get canRequestFeedback => !tastingNotes.isEmpty;

  @override
  void initState() {
    super.initState();
    // The feedback button depends on the goal text, so the screen rebuilds as the user types.
    goalController.addListener(_onGoalChanged);
  }

  /// Rebuilds the screen after the goal text changes.
  void _onGoalChanged() => setState(() {});

  /// Handles a move of the slider for [attribute] by recording [rating].
  void onRatingChanged(TasteAttribute attribute, int rating) {
    setState(() => _ratings = _ratings.withRating(attribute, rating));
  }

  /// Handles a tap on "Get brew feedback" by opening the brew feedback screen with the brew and the tasting notes.
  ///
  /// The feedback screen stays below it, so the user can come back, change their notes, and ask again.
  Future<void> onGetFeedbackPressed() async {
    final TastingNotes notes = tastingNotes;
    FocusScope.of(context).unfocus();

    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (BuildContext context) => SuggestionsRoute(record: record, notes: notes)),
    );
  }

  @override
  void dispose() {
    goalController.removeListener(_onGoalChanged);
    goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FeedbackView(this);
}
