import 'dart:math';

import 'package:flutter_bookoo/flutter_bookoo.dart';

/// Simulates the readings of a scale under a brew, for demo mode.
///
/// The simulator is a model of what sits on the platter and of a person pouring from a kettle. It does not keep time
/// itself: each call to [advance] moves it forward by a given step and returns the reading the scale would send at that
/// moment, so it can be driven by a timer in the app and by a loop in tests.
///
/// The scene follows a brew the way a person would:
///
/// 1. After [reset], the platter is empty. Shortly after, the brewer with its filter and coffee is set down, and the
///    weight rises to [brewerGrams].
/// 2. [tare] zeroes the weight, as the brewing screen does when the user leaves preparation.
/// 3. [pourTo] asks for water up to a total weight since the tare. After a short pause to pick up the kettle, the water
///    goes in at a rate that wobbles around 5 to 7 g/s, slows over the last few grams, and stops close to the target,
///    a little under or over, as a person stops by eye. A null target holds the weight, as during a rest or a steep.
///
/// The reported flow rate is smoothed, as the BOOKOO scale's own flow smoothing does, so it falls to near zero about a
/// second after the pour stops. Weights are reported to a tenth of a gram, the scale's precision.
///
/// All randomness comes from the [Random] given to the constructor, so tests can repeat a run exactly.
class DemoScaleSimulator {
  /// Creates a simulator with an empty platter. [random] defaults to an unseeded generator.
  DemoScaleSimulator({Random? random}) : _random = random ?? Random();

  /// The weight of the brewer, filter, coffee, and carafe that is set on the platter at the start, in grams.
  static const double brewerGrams = 412.6;

  /// How long after [reset] the brewer is set on the platter.
  static const Duration placeDelay = Duration(milliseconds: 1500);

  /// How long setting the brewer down takes, during which the weight rises to [brewerGrams].
  static const Duration placeDuration = Duration(milliseconds: 600);

  /// How long after [pourTo] the water starts, the time it takes to pick up the kettle.
  static const Duration pourDelay = Duration(milliseconds: 1500);

  /// How many grams before the target the pour starts to slow down.
  static const double slowDownGrams = 12;

  /// The pour rate over the last few grams, in grams per second.
  static const double finishingRate = 2.5;

  /// The battery level the simulated scale reports.
  static const int batteryPercent = 86;

  /// The share of each new flow measurement in the smoothed flow rate, per second of time simulated.
  static const double _flowSmoothingPerSecond = 4;

  /// The source of the small variations that make the readings look real.
  final Random _random;

  /// The time since [reset].
  Duration _sceneTime = Duration.zero;

  /// The weight on the platter, before tare, in grams.
  double _grossGrams = 0;

  /// The weight that [tare] subtracted, in grams.
  double _tareGrams = 0;

  /// The smoothed flow rate, in grams per second.
  double _flow = 0;

  /// The weight since the tare at which the current pour stops, or null if no water is being poured.
  double? _stopAtGrams;

  /// The time left before the current pour starts.
  Duration _pourWait = Duration.zero;

  /// How long the current pour has been running.
  Duration _pourTime = Duration.zero;

  /// The steady pour rate of the current pour, in grams per second.
  double _pourRate = 6;

  /// The weight since the last tare, in grams, without rounding.
  double get netGrams => _grossGrams - _tareGrams;

  /// Whether water is being poured, or about to be.
  bool get isPouring => _stopAtGrams != null;

  /// Empties the platter and starts the scene again, ready for a new brew.
  void reset() {
    _sceneTime = Duration.zero;
    _grossGrams = 0;
    _tareGrams = 0;
    _flow = 0;
    _stopAtGrams = null;
  }

  /// Zeroes the weight. If the brewer has not been set down yet, it is set down first, so that the water poured after
  /// the tare is all that the weight counts.
  void tare() {
    _grossGrams = max(_grossGrams, brewerGrams);
    _tareGrams = _grossGrams;
  }

  /// Pours water until the weight since the tare is about [targetGrams], or holds the weight if [targetGrams] is null
  /// or already reached.
  void pourTo(double? targetGrams) {
    if (targetGrams == null || targetGrams <= netGrams) {
      _stopAtGrams = null;
      return;
    }
    // A person stops by eye, so the pour ends a little under or over the target, within what the brewing screen
    // accepts as reaching it.
    _stopAtGrams = targetGrams + _between(-0.6, 1.0);
    _pourWait = pourDelay;
    _pourTime = Duration.zero;
    _pourRate = _between(5.2, 6.8);
  }

  /// Moves the scene forward by [step] and returns the reading the scale sends at the end of it.
  BookooScaleReading advance(Duration step) {
    final double seconds = step.inMicroseconds / Duration.microsecondsPerSecond;
    final double before = _grossGrams;
    _sceneTime += step;
    _placeBrewer();
    _pour(step, seconds);
    final double measured = seconds > 0 ? (_grossGrams - before) / seconds : 0;
    final double share = min(1, _flowSmoothingPerSecond * seconds);
    _flow += (measured - _flow) * share;
    if (_flow.abs() < 0.05) {
      _flow = 0;
    }
    return BookooScaleReading(
      elapsed: Duration.zero,
      weightGrams: _roundTenth(netGrams),
      flowRateGramsPerSecond: _roundTenth(_flow),
      batteryPercent: batteryPercent,
      standbyTime: const Duration(minutes: 5),
      beepLevel: 0,
      flowSmoothingEnabled: true,
    );
  }

  /// Raises the weight while the brewer is being set down.
  void _placeBrewer() {
    final Duration sincePlaced = _sceneTime - placeDelay;
    if (sincePlaced.isNegative || _grossGrams >= brewerGrams) {
      return;
    }
    final double progress = min(1, sincePlaced.inMicroseconds / placeDuration.inMicroseconds);
    _grossGrams = brewerGrams * progress;
  }

  /// Adds the water poured during [step], which lasts [seconds].
  void _pour(Duration step, double seconds) {
    final double? stopAt = _stopAtGrams;
    if (stopAt == null) {
      return;
    }
    if (_pourWait > Duration.zero) {
      _pourWait -= step;
      return;
    }
    _pourTime += step;
    final double pourSeconds = _pourTime.inMicroseconds / Duration.microsecondsPerSecond;
    // The stream builds up over the first second, wobbles as the kettle moves, and slows over the last few grams.
    final double rampUp = min(1, pourSeconds);
    final double wobble = 0.7 * sin(2 * pi * pourSeconds / 1.7) + _between(-0.3, 0.3);
    final double remaining = stopAt - netGrams;
    final double rate = remaining < slowDownGrams ? finishingRate : max(finishingRate, (_pourRate + wobble) * rampUp);
    final double added = min(remaining, rate * seconds);
    _grossGrams += added;
    if (netGrams >= stopAt - 0.01) {
      _stopAtGrams = null;
    }
  }

  /// A random number from [low] to [high].
  double _between(double low, double high) => low + (high - low) * _random.nextDouble();

  /// Rounds [value] to the nearest tenth, the scale's precision.
  static double _roundTenth(double value) => (value * 10).roundToDouble() / 10;
}
