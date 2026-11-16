import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../models/feedback/brew_feedback.dart';
import '../../services/brew_feedback/brew_feedback_exception.dart';
import '../../services/brew_feedback/brew_feedback_failure.dart';
import '../../services/brew_feedback/brew_feedback_service.dart';
import 'models/suggestions_status.dart';
import 'suggestions_route.dart';
import 'suggestions_view.dart';

/// State and behavior for [SuggestionsRoute].
///
/// The request starts when the screen appears. While it runs the status is [SuggestionsStatus.loading]. It ends with
/// the [feedback] and [SuggestionsStatus.loaded], or with a [failure] and [SuggestionsStatus.failed], after which the
/// user can try again.
class SuggestionsController extends State<SuggestionsRoute> {
  /// The service that asks for feedback, created once for the life of the screen.
  late final BrewFeedbackService _service = widget.feedbackService ?? BrewFeedbackService();

  /// Where the request stands.
  SuggestionsStatus status = SuggestionsStatus.loading;

  /// The feedback, once it has arrived.
  BrewFeedback? feedback;

  /// Why the last request failed, or null if it did not.
  BrewFeedbackFailure? failure;

  @override
  void initState() {
    super.initState();
    unawaited(_request());
  }

  /// Asks for feedback and shows the result. The status must already be [SuggestionsStatus.loading].
  Future<void> _request() async {
    try {
      final BrewFeedback result = await _service.requestFeedback(widget.record, widget.notes);
      if (!mounted) {
        return;
      }
      setState(() {
        feedback = result;
        status = SuggestionsStatus.loaded;
      });
    } on BrewFeedbackException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        failure = error.failure;
        status = SuggestionsStatus.failed;
      });
    }
  }

  /// Handles a tap on Try again by repeating the request.
  Future<void> onTryAgainPressed() {
    setState(() {
      status = SuggestionsStatus.loading;
      failure = null;
    });
    return _request();
  }

  /// Handles a tap on Done by returning to the home screen.
  void onDonePressed() {
    Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) => SuggestionsView(this);
}
