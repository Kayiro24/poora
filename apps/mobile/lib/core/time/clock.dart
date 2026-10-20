/// Injectable wall clock so timer and metrics logic can be tested with a
/// fake time source.
abstract class Clock {
  const Clock();
  DateTime now();
}

class SystemClock extends Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

/// Test clock; advance it manually.
class FakeClock extends Clock {
  FakeClock(this._now);
  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);
  void set(DateTime t) => _now = t;
}
