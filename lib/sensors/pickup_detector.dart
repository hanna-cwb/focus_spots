import 'dart:math';

/// Earth's gravity in m/s².
const double kGravity = 9.81;

/// Length of a 3-axis sensor vector.
double vectorMagnitude(List<double> v) =>
    sqrt(v.fold(0.0, (s, x) => s + x * x));

// ---------------------------------------------------------------------------
// Pickup detection
// ---------------------------------------------------------------------------

enum PickupState { settling, armed, moving }

/// Simple state machine:
///  1. Phone lies still for [restTime] (optionally: flat) → "armed".
///  2. Movement above threshold while armed → count a pickup.
///  3. Only re-armed after lying still again.
/// This way a phone that is picked up counts only once, no matter how long it is moved.
class PickupDetector {
  double accelThreshold = 1.5; // deviation of |a| from 9.81 in m/s²
  double gyroThreshold = 0.8; // rad/s
  Duration restTime = const Duration(milliseconds: 1500);
  bool requireFlat = true; // only arm when the display faces up/down

  int pickups = 0;
  DateTime? lastPickup;
  PickupState state = PickupState.settling;

  double accelDeviation = 0;
  double gyroMagnitude = 0;
  bool isFlat = false;

  DateTime? _stillSince;
  bool _armed = false;

  void onGyro(List<double> v) => gyroMagnitude = vectorMagnitude(v);

  void onAccel(List<double> v) {
    final now = DateTime.now();
    accelDeviation = (vectorMagnitude(v) - kGravity).abs();
    // Flat = gravity acts almost entirely on the z-axis.
    isFlat = v[2].abs() > 8.5;

    final moving =
        accelDeviation > accelThreshold || gyroMagnitude > gyroThreshold;

    if (moving) {
      _stillSince = null;
      if (_armed) {
        pickups++;
        lastPickup = now;
        _armed = false;
      }
      state = PickupState.moving;
      return;
    }

    if (requireFlat && !isFlat) {
      // Still, but not put down (e.g. held steady in the hand) → not armed.
      _stillSince = null;
      state = _armed ? PickupState.armed : PickupState.settling;
      return;
    }

    _stillSince ??= now;
    if (!_armed && now.difference(_stillSince!) >= restTime) _armed = true;
    state = _armed ? PickupState.armed : PickupState.settling;
  }

  void resetCount() {
    pickups = 0;
    lastPickup = null;
  }

  void reset() {
    resetCount();
    state = PickupState.settling;
    _stillSince = null;
    _armed = false;
  }
}
