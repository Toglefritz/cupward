/// What happens during a phase of a brew.
///
/// The kind decides how the app presents a phase: its name, its instructions, and what the scale readings mean during
/// it. Kinds describe actions rather than one brewing method, so a recipe for any method is a sequence of them. A pour
/// over is prepare, bloom, several pours, and complete. An immersion brew, such as a French press, is prepare, a pour of
/// all the water, steep, and complete. Methods that need other actions add their own kinds here.
///
/// The [name] of each value is its JSON form, so values must not be renamed.
enum BrewPhaseKind {
  /// Setting up: rinsing the filter, adding the coffee, and taring the scale. Happens before any water is poured.
  prepare,

  /// The first, small pour that wets the grounds and lets them release gas before the main pours.
  bloom,

  /// Pouring water toward a target weight. A recipe can have several pours in a row.
  pour,

  /// Leaving the coffee in the water for the phase's duration, then pressing or draining it, as in a French press.
  steep,

  /// The end of the brew, after the last water has drained through.
  complete;

  /// Returns the kind whose [name] is [value].
  ///
  /// Throws an [ArgumentError] if no kind has that name, for example in data written by a newer version of the app.
  static BrewPhaseKind fromName(String value) {
    for (final BrewPhaseKind kind in values) {
      if (kind.name == value) {
        return kind;
      }
    }

    throw ArgumentError('Unknown brew phase kind: $value');
  }
}
