/// Where a phase stands relative to the brew's current phase.
enum BrewPhaseStatus {
  /// The phase is finished.
  completed,

  /// The phase is the one the user is on now.
  current,

  /// The phase has not started.
  upcoming;

  /// Returns the status of the phase at [index] when the brew is at [currentIndex].
  static BrewPhaseStatus of(int index, int currentIndex) {
    if (index < currentIndex) {
      return BrewPhaseStatus.completed;
    }

    return index == currentIndex ? BrewPhaseStatus.current : BrewPhaseStatus.upcoming;
  }
}
