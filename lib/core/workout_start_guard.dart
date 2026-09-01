class WorkoutStartGuard {
  WorkoutStartGuard._();

  static bool _inFlight = false;

  static bool tryAcquire() {
    if (_inFlight) return false;
    _inFlight = true;
    return true;
  }

  static void release() => _inFlight = false;
}
