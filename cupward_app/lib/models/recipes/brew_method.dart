/// A way of brewing coffee that a new recipe can be built for.
///
/// Each method has a typical brew time, which helps the user tell the methods apart and gives a starting point for a
/// new recipe. The methods differ in how water meets the coffee: the drippers pour water through a filter, the French
/// press steeps the coffee in the water, and the AeroPress and Clever Dripper steep and then drain or press.
///
/// The [name] of each value is its stored and JSON form, so values must not be renamed.
enum BrewMethod {
  /// A cone dripper with a single large hole, known for a bright, clean cup.
  v60(typicalBrewTime: Duration(minutes: 3), isImmersion: false),

  /// A flat-bottom dripper with three small holes, which drains evenly.
  kalitaWave(typicalBrewTime: Duration(minutes: 3, seconds: 30), isImmersion: false),

  /// A glass pour-over brewer with a thick paper filter, known for a very clean cup.
  chemex(typicalBrewTime: Duration(minutes: 4, seconds: 30), isImmersion: false),

  /// A full-immersion brewer with a metal mesh filter, known for a heavy body.
  frenchPress(typicalBrewTime: Duration(minutes: 4), isImmersion: true),

  /// A short steep followed by pressing through a paper filter.
  aeroPress(typicalBrewTime: Duration(minutes: 2), isImmersion: true),

  /// A dripper with a valve, so the coffee steeps and then drains when the brewer is set on a cup.
  cleverDripper(typicalBrewTime: Duration(minutes: 3, seconds: 30), isImmersion: true);

  const BrewMethod({required this.typicalBrewTime, required this.isImmersion});

  /// About how long a brew with this method takes.
  final Duration typicalBrewTime;

  /// Whether the coffee steeps in all of the water at once, rather than having water poured through it.
  ///
  /// An immersion recipe adds all the water in one pour and then steeps. A pour-over recipe has a bloom and several
  /// pours.
  final bool isImmersion;

  /// Returns the method whose [name] is [value].
  ///
  /// Throws an [ArgumentError] if no method has that name, for example in data written by a newer version of the app.
  static BrewMethod fromName(String value) {
    for (final BrewMethod method in values) {
      if (method.name == value) {
        return method;
      }
    }
    throw ArgumentError('Unknown brew method: $value');
  }
}
