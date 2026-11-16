/// Which way a suggestion moves a brewing variable.
///
/// For the grind size, [increase] means finer, because a finer grind increases extraction, and [decrease] means
/// coarser.
///
/// The [name] of each value is what the AI model is asked to answer with, so values must not be renamed.
enum ChangeDirection {
  /// More of the parameter, or a finer grind.
  increase,

  /// Less of the parameter, or a coarser grind.
  decrease;

  /// Returns the direction whose [name] is [value], or null if none has it.
  static ChangeDirection? tryFromName(String value) {
    for (final ChangeDirection direction in values) {
      if (direction.name == value) {
        return direction;
      }
    }
    return null;
  }
}
