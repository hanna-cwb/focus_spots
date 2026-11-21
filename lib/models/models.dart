enum SpotKind { library, cafe, home, other }

class Spot {
  Spot({
    required this.name,
    required this.kind,
    required this.radiusM,
    required this.shared,
    this.latitude,
    this.longitude,
  });

  final String name;
  final SpotKind kind;
  final double radiusM;

  /// Shared spots are visible to friends too.
  final bool shared;

  /// Null for demo spots that were never captured with GPS.
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get iconAsset => switch (kind) {
        SpotKind.library => 'assets/figma/spots/library.svg',
        SpotKind.cafe => 'assets/figma/spots/cafe.svg',
        SpotKind.home => 'assets/figma/spots/home.svg',
        SpotKind.other => 'assets/figma/home/pin.svg',
      };
}

class Friend {
  const Friend({
    required this.name,
    this.avatarAsset,
    this.studyingAt,
    this.studyingFor,
  });

  final String name;

  /// Optional local image, e.g. assets/figma/avatars/mia.png.
  final String? avatarAsset;

  /// Name of the spot the friend is currently studying at, null if offline.
  final String? studyingAt;
  final Duration? studyingFor;

  bool get isStudying => studyingAt != null;
}

class RankingEntry {
  const RankingEntry({required this.name, required this.minutes, this.isMe = false});

  final String name;
  final int minutes;
  final bool isMe;
}

class FocusSessionResult {
  const FocusSessionResult({
    required this.spotName,
    required this.start,
    required this.end,
    required this.pickups,
  });

  final String spotName;
  final DateTime start;
  final DateTime end;
  final int pickups;

  Duration get duration => end.difference(start);

  double get pickupsPerHour {
    final hours = duration.inSeconds / 3600;
    if (hours <= 0) return 0;
    return pickups / hours;
  }
}

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

/// 380 → "6 h 20 min", 45 → "45 min".
String formatMinutesLong(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m min';
  return '$h h ${m.toString().padLeft(2, '0')} min';
}

/// 380 → "6 h 20", 45 → "0 h 45".
String formatMinutesShort(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '$h h ${m.toString().padLeft(2, '0')}';
}

/// 1.94 → "1.9"
String formatOneDecimal(double v) => v.toStringAsFixed(1);

String formatClock(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String pickupsLabel(int n) => n == 1 ? '1 pickup' : '$n pickups';
