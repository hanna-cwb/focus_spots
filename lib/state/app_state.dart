import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import '../models/models.dart';

/// App-wide state. Holds demo data from the Figma design until Firebase is
/// wired up; replace the demo lists with Firestore data later.
class AppState extends ChangeNotifier {
  AppState() {
    _currentSpot = spots.first; // Demo: "Library", as in the design.
  }

  // --- Spots -----------------------------------------------------------------

  final List<Spot> spots = [
    Spot(name: 'Library', kind: SpotKind.library, radiusM: 100, shared: true),
    Spot(name: 'Campus Café', kind: SpotKind.cafe, radiusM: 75, shared: true),
    Spot(name: 'Home', kind: SpotKind.home, radiusM: 50, shared: false),
  ];

  Spot? _currentSpot;

  /// The spot the user is currently in, or null if none is nearby.
  Spot? get currentSpot => _currentSpot;

  void addSpot(Spot spot) {
    spots.add(spot);
    if (spot.hasCoordinates) _currentSpot = spot;
    notifyListeners();
  }

  // --- Friends ---------------------------------------------------------------

  final List<Friend> friends = const [
    Friend(
      name: 'Mia',
      avatarAsset: 'assets/figma/avatars/mia.png',
      studyingAt: 'Library',
      studyingFor: Duration(minutes: 40),
    ),
    Friend(
      name: 'Jonas',
      avatarAsset: 'assets/figma/avatars/jonas.png',
      studyingAt: 'Campus Café',
      studyingFor: Duration(minutes: 25),
    ),
    Friend(
      name: 'Lea',
      avatarAsset: 'assets/figma/avatars/lea.png',
      studyingAt: 'Library',
      studyingFor: Duration(minutes: 12),
    ),
    Friend(name: 'Alex'),
  ];

  List<Friend> get studyingFriends => friends.where((f) => f.isStudying).toList();

  /// Own friend code shown in the "Add friend" sheet.
  final String myFriendCode = '619382';

  // --- Weekly statistics -----------------------------------------------------

  /// Focus minutes Monday..Sunday of the current week.
  final List<int> weekMinutes = [60, 75, 45, 80, 120, 0, 0];
  int weekPickups = 12;
  int favoriteSpotMinutes = 270; // Library, 4 h 30 min
  int sharedSpotMinutes = 360; // 6 h

  int get weekTotalMinutes => weekMinutes.fold(0, (a, b) => a + b);

  double get weekPickupsPerHour {
    final hours = weekTotalMinutes / 60;
    return hours == 0 ? 0 : weekPickups / hours;
  }

  List<RankingEntry> get ranking {
    final list = [
      const RankingEntry(name: 'Mia', minutes: 490),
      RankingEntry(name: 'You', minutes: weekTotalMinutes, isMe: true),
      const RankingEntry(name: 'Jonas', minutes: 345),
    ]..sort((a, b) => b.minutes.compareTo(a.minutes));
    return list;
  }

  void addSession(FocusSessionResult result) {
    final day = result.start.weekday - 1; // Monday = 0
    weekMinutes[day] += result.duration.inMinutes;
    weekPickups += result.pickups;
    notifyListeners();
  }

  // --- Location / spot detection ----------------------------------------------

  StreamSubscription<Position>? _positionSub;

  /// Starts GPS updates if permission was already granted. Only spots that
  /// were saved with coordinates take part in detection; as long as there are
  /// none, the demo spot stays selected.
  Future<void> startSpotDetection() async {
    if (_positionSub != null) return;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.whileInUse &&
          perm != LocationPermission.always) {
        return;
      }
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(_onPosition, onError: (_) {});
    } catch (_) {
      // Location not available (e.g. simulator) – keep demo state.
    }
  }

  void _onPosition(Position p) {
    final located = spots.where((s) => s.hasCoordinates).toList();
    if (located.isEmpty) return;
    Spot? best;
    double bestDistance = double.infinity;
    for (final s in located) {
      final d = Geolocator.distanceBetween(
          p.latitude, p.longitude, s.latitude!, s.longitude!);
      if (d <= s.radiusM && d < bestDistance) {
        best = s;
        bestDistance = d;
      }
    }
    if (best != _currentSpot) {
      _currentSpot = best;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}

/// Makes [AppState] available below it: `AppScope.of(context)`.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!.notifier!;
  }

  /// Read without subscribing to changes (e.g. inside callbacks).
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    return scope!.notifier!;
  }
}
