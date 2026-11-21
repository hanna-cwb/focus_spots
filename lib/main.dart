import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'firebase_options.dart';

/// Set if Firebase.initializeApp fails, so the app still starts and shows the error.
Object? firebaseInitError;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    firebaseInitError = e;
  }
  runApp(const SensorTestApp());
}

class SensorTestApp extends StatelessWidget {
  const SensorTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Spots – Sensor-Test',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const SensorTestPage(),
    );
  }
}

/// After this time without an event, a motion sensor is considered "not delivering data".
const Duration kTimeout = Duration(seconds: 3);

/// GPS takes longer for the first fix, hence a more generous timeout.
const Duration kGpsTimeout = Duration(seconds: 15);

const double kGravity = 9.81;

enum SensorStatus { waiting, ok, noData, error }

double _mag(List<double> v) => sqrt(v.fold(0.0, (s, x) => s + x * x));

// ---------------------------------------------------------------------------
// Motion sensors (accelerometer, gyroscope)
// ---------------------------------------------------------------------------

class SensorChannel {
  SensorChannel({
    required this.name,
    required this.unit,
    required this.icon,
    required this.check,
    required this.checkHint,
  });

  final String name;
  final String unit;
  final IconData icon;
  final bool Function(double magnitude) check;
  final String checkHint;

  List<double>? values;
  int totalEvents = 0;
  int _eventsSinceTick = 0;
  double rateHz = 0;
  DateTime startedAt = DateTime.now();
  DateTime? lastEventAt;
  String? error;

  double get magnitude => values == null ? 0 : _mag(values!);

  void onData(List<double> v) {
    values = v;
    totalEvents++;
    _eventsSinceTick++;
    lastEventAt = DateTime.now();
  }

  void onError(Object e) => error = e.toString();

  void tick(Duration elapsed) {
    if (elapsed.inMilliseconds == 0) return;
    rateHz = _eventsSinceTick * 1000 / elapsed.inMilliseconds;
    _eventsSinceTick = 0;
  }

  void reset() {
    values = null;
    totalEvents = 0;
    _eventsSinceTick = 0;
    rateHz = 0;
    startedAt = DateTime.now();
    lastEventAt = null;
    error = null;
  }

  SensorStatus get status {
    final now = DateTime.now();
    if (error != null) return SensorStatus.error;
    if (lastEventAt == null) {
      return now.difference(startedAt) > kTimeout
          ? SensorStatus.noData
          : SensorStatus.waiting;
    }
    return now.difference(lastEventAt!) > kTimeout
        ? SensorStatus.noData
        : SensorStatus.ok;
  }
}

// ---------------------------------------------------------------------------
// GPS + spot detection
// ---------------------------------------------------------------------------

class GpsChannel {
  LocationPermission? permission;
  bool? serviceEnabled;
  Position? position;
  int totalEvents = 0;
  DateTime startedAt = DateTime.now();
  DateTime? lastEventAt;
  String? error;

  /// Saved test spot (persists when "Neu starten" / restart is tapped).
  Position? spot;
  double radiusM = 50;

  void onData(Position p) {
    position = p;
    totalEvents++;
    lastEventAt = DateTime.now();
  }

  void onError(Object e) => error = e.toString();

  void reset() {
    permission = null;
    serviceEnabled = null;
    position = null;
    totalEvents = 0;
    startedAt = DateTime.now();
    lastEventAt = null;
    error = null;
  }

  double? get distanceToSpot {
    if (spot == null || position == null) return null;
    return Geolocator.distanceBetween(
      position!.latitude,
      position!.longitude,
      spot!.latitude,
      spot!.longitude,
    );
  }

  bool? get insideSpot {
    final d = distanceToSpot;
    return d == null ? null : d <= radiusM;
  }

  SensorStatus get status {
    final now = DateTime.now();
    if (error != null) return SensorStatus.error;
    if (lastEventAt == null) {
      return now.difference(startedAt) > kGpsTimeout
          ? SensorStatus.noData
          : SensorStatus.waiting;
    }
    return now.difference(lastEventAt!) > kGpsTimeout
        ? SensorStatus.noData
        : SensorStatus.ok;
  }
}

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

  void onGyro(List<double> v) => gyroMagnitude = _mag(v);

  void onAccel(List<double> v) {
    final now = DateTime.now();
    accelDeviation = (_mag(v) - kGravity).abs();
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

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class SensorTestPage extends StatefulWidget {
  const SensorTestPage({super.key});

  @override
  State<SensorTestPage> createState() => _SensorTestPageState();
}

class _SensorTestPageState extends State<SensorTestPage> {
  final accel = SensorChannel(
    name: 'Beschleunigung (inkl. Gravitation)',
    unit: 'm/s²',
    icon: Icons.speed,
    check: (m) => m > 9.0 && m < 10.6,
    checkHint: 'In Ruhe sollte |a| ≈ 9,81 m/s² sein',
  );
  final userAccel = SensorChannel(
    name: 'Lineare Beschleunigung (ohne Gravitation)',
    unit: 'm/s²',
    icon: Icons.open_with,
    check: (m) => m < 0.5,
    checkHint: 'In Ruhe ≈ 0, beim Schütteln steigt es',
  );
  final gyro = SensorChannel(
    name: 'Gyroskop',
    unit: 'rad/s',
    icon: Icons.threesixty,
    check: (m) => m < 0.1,
    checkHint: 'In Ruhe ≈ 0, beim Drehen steigt der Wert',
  );

  late final List<SensorChannel> channels = [accel, userAccel, gyro];
  final gps = GpsChannel();
  final pickup = PickupDetector();

  final List<StreamSubscription<dynamic>> _subs = [];
  StreamSubscription<Position>? _gpsSub;
  Timer? _uiTimer;
  Timer? _rateTimer;
  final Stopwatch _rateWatch = Stopwatch();

  Duration _interval = SensorInterval.gameInterval;
  bool _running = false;

  static final Map<Duration, String> _intervals = {
    SensorInterval.normalInterval: 'Normal',
    SensorInterval.uiInterval: 'UI',
    SensorInterval.gameInterval: 'Game',
    SensorInterval.fastestInterval: 'Max',
  };

  @override
  void initState() {
    super.initState();
    _start();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  void _listen<T>(
    SensorChannel ch,
    Stream<T> stream,
    List<double> Function(T e) extract, [
    void Function(List<double> v)? also,
  ]) {
    try {
      _subs.add(stream.listen(
        (e) {
          final v = extract(e);
          ch.onData(v);
          also?.call(v);
        },
        onError: ch.onError,
        cancelOnError: true,
      ));
    } catch (e) {
      ch.onError(e);
    }
  }

  void _start() {
    _running = true;
    for (final ch in channels) {
      ch.reset();
    }
    pickup.reset();

    _listen<AccelerometerEvent>(
      accel,
      accelerometerEventStream(samplingPeriod: _interval),
      (e) => [e.x, e.y, e.z],
      pickup.onAccel,
    );
    _listen<UserAccelerometerEvent>(
      userAccel,
      userAccelerometerEventStream(samplingPeriod: _interval),
      (e) => [e.x, e.y, e.z],
    );
    _listen<GyroscopeEvent>(
      gyro,
      gyroscopeEventStream(samplingPeriod: _interval),
      (e) => [e.x, e.y, e.z],
      pickup.onGyro,
    );

    _rateWatch
      ..reset()
      ..start();
    _rateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = _rateWatch.elapsed;
      _rateWatch
        ..reset()
        ..start();
      for (final ch in channels) {
        ch.tick(elapsed);
      }
    });

    _startGps();
  }

  Future<void> _startGps() async {
    gps.reset();
    try {
      gps.serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (gps.serviceEnabled != true) {
        gps.error = 'Ortungsdienste sind am Gerät deaktiviert.';
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      gps.permission = perm;
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        gps.error = 'Standortberechtigung verweigert ($perm). '
            'In den Einstellungen erlauben.';
        return;
      }
      if (!_running || _gpsSub != null) return;
      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).listen(gps.onData, onError: gps.onError);
    } catch (e) {
      gps.onError(e);
    }
  }

  Future<void> _stop() async {
    _running = false;
    _rateTimer?.cancel();
    _rateWatch.stop();
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _gpsSub?.cancel();
    _gpsSub = null;
    for (final ch in channels) {
      ch.rateHz = 0;
    }
  }

  Future<void> _restart() async {
    await _stop();
    _start();
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final okCount = channels.where((c) => c.status == SensorStatus.ok).length +
        (gps.status == SensorStatus.ok ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Spots – Sensor-Test'),
        actions: [
          IconButton(
            tooltip: _running ? 'Pausieren' : 'Fortsetzen',
            icon: Icon(_running ? Icons.pause : Icons.play_arrow),
            onPressed: () async {
              _running ? await _stop() : _start();
              setState(() {});
            },
          ),
          IconButton(
            tooltip: 'Neu starten',
            icon: const Icon(Icons.refresh),
            onPressed: _restart,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            '$okCount von ${channels.length + 1} Sensoren liefern Daten',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const FirebaseCard(),
          GpsCard(gps: gps, onChanged: () => setState(() {})),
          PickupCard(detector: pickup, onChanged: () => setState(() {})),
          const SizedBox(height: 8),
          Text('Rohdaten Bewegungssensoren',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          SegmentedButton<Duration>(
            segments: _intervals.entries
                .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
                .toList(),
            selected: {_interval},
            onSelectionChanged: (s) {
              _interval = s.first;
              _restart();
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Abtastintervall: ${_interval.inMilliseconds} ms '
            '(das System kann davon abweichen)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          for (final ch in channels) SensorCard(channel: ch),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final SensorStatus status;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      SensorStatus.waiting => ('Warte…', Colors.grey),
      SensorStatus.ok => ('OK', Colors.green),
      SensorStatus.noData => ('Keine Daten', Colors.orange),
      SensorStatus.error => ('Fehler', Colors.red),
    };
    return Chip(
      label: Text(text),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class SensorCard extends StatelessWidget {
  const SensorCard({super.key, required this.channel});

  final SensorChannel channel;

  @override
  Widget build(BuildContext context) {
    final ch = channel;
    final status = ch.status;
    final theme = Theme.of(context);
    final plausible = ch.values != null && ch.check(ch.magnitude);
    const axes = ['x', 'y', 'z'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              icon: ch.icon,
              title: ch.name,
              trailing: StatusChip(status),
            ),
            if (ch.values != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < ch.values!.length; i++)
                    Expanded(
                      child: Text(
                        '${axes[i]}: ${ch.values![i].toStringAsFixed(3)}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '|v| = ${ch.magnitude.toStringAsFixed(3)} ${ch.unit}   ·   '
                '${ch.rateHz.toStringAsFixed(1)} Hz   ·   '
                '${ch.totalEvents} Events',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    plausible ? Icons.check_circle : Icons.info_outline,
                    size: 16,
                    color: plausible ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(ch.checkHint, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ],
            if (ch.error != null) ...[
              const SizedBox(height: 8),
              Text(
                ch.error!,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ],
            if (status == SensorStatus.noData && ch.error == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Seit ${kTimeout.inSeconds}s kein Event – Sensor evtl. '
                  'nicht vorhanden (z. B. im Simulator).',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Writes a document to Firestore and reads it back directly from the server
/// (bypassing the local cache) to verify the real connection.
class FirebaseCard extends StatefulWidget {
  const FirebaseCard({super.key});

  @override
  State<FirebaseCard> createState() => _FirebaseCardState();
}

class _FirebaseCardState extends State<FirebaseCard> {
  static const _timeout = Duration(seconds: 10);

  SensorStatus _status = SensorStatus.waiting;
  String? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _test();
  }

  String _hint(String code) => switch (code) {
        'permission-denied' =>
          '\n→ Security Rules in der Firebase Console prüfen '
              '(Test-Modus oder Anmeldung nötig).',
        'not-found' =>
          '\n→ Firestore-Datenbank in der Firebase Console noch nicht angelegt?',
        'unavailable' => '\n→ Keine Internetverbindung?',
        _ => '',
      };

  Future<void> _test() async {
    if (firebaseInitError != null) {
      setState(() {
        _status = SensorStatus.error;
        _message = 'Firebase.initializeApp fehlgeschlagen: $firebaseInitError';
      });
      return;
    }
    setState(() {
      _busy = true;
      _status = SensorStatus.waiting;
      _message = null;
    });

    final sw = Stopwatch()..start();
    try {
      final doc =
          FirebaseFirestore.instance.collection('_connection_test').doc('ping');
      // set() only completes once the server has confirmed the write.
      await doc.set({
        'at': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
      }).timeout(_timeout);
      final snap = await doc
          .get(const GetOptions(source: Source.server))
          .timeout(_timeout);
      sw.stop();
      final at = (snap.data()?['at'] as Timestamp?)?.toDate();
      _status = SensorStatus.ok;
      _message = 'Schreiben + Lesen OK (${sw.elapsedMilliseconds} ms)\n'
          'Server-Zeit: $at';
    } on FirebaseException catch (e) {
      _status = SensorStatus.error;
      _message = '${e.code}: ${e.message}${_hint(e.code)}';
    } on TimeoutException {
      _status = SensorStatus.noData;
      _message = 'Keine Antwort vom Server nach ${_timeout.inSeconds}s '
          '(offline? Datenbank angelegt?)';
    } catch (e) {
      _status = SensorStatus.error;
      _message = e.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = firebaseInitError == null ? Firebase.app() : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              icon: Icons.cloud,
              title: 'Firebase / Firestore',
              trailing: StatusChip(_status),
            ),
            const SizedBox(height: 8),
            Text(
              'Projekt: ${app?.options.projectId ?? '–'}',
              style: theme.textTheme.bodySmall,
            ),
            if (_message != null) ...[
              const SizedBox(height: 4),
              Text(
                _message!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _status == SensorStatus.ok ? null : Colors.red,
                ),
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: const Text('Verbindung testen'),
              onPressed: _busy ? null : _test,
            ),
          ],
        ),
      ),
    );
  }
}

class GpsCard extends StatelessWidget {
  const GpsCard({super.key, required this.gps, required this.onChanged});

  final GpsChannel gps;
  final VoidCallback onChanged;

  String _fmtDist(double m) =>
      m < 1000 ? '${m.toStringAsFixed(0)} m' : '${(m / 1000).toStringAsFixed(2)} km';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = gps.position;
    final d = gps.distanceToSpot;
    final inside = gps.insideSpot;
    final mono = const TextStyle(fontFamily: 'monospace');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              icon: Icons.location_on,
              title: 'GPS / Spot-Erkennung',
              trailing: StatusChip(gps.status),
            ),
            const SizedBox(height: 8),
            Text(
              'Berechtigung: ${gps.permission?.name ?? '–'}   ·   '
              'Ortung an: ${gps.serviceEnabled ?? '–'}',
              style: theme.textTheme.bodySmall,
            ),
            if (p != null) ...[
              const SizedBox(height: 4),
              Text('Lat: ${p.latitude.toStringAsFixed(6)}', style: mono),
              Text('Lon: ${p.longitude.toStringAsFixed(6)}', style: mono),
              Text(
                'Genauigkeit: ±${p.accuracy.toStringAsFixed(1)} m   ·   '
                '${gps.totalEvents} Updates',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.push_pin),
                    label: const Text('Aktuellen Ort als Spot'),
                    onPressed: p == null
                        ? null
                        : () {
                            gps.spot = p;
                            onChanged();
                          },
                  ),
                ),
                if (gps.spot != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Spot löschen',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      gps.spot = null;
                      onChanged();
                    },
                  ),
                ],
              ],
            ),
            Row(
              children: [
                Text('Radius: ${gps.radiusM.toStringAsFixed(0)} m'),
                Expanded(
                  child: Slider(
                    min: 10,
                    max: 200,
                    divisions: 19,
                    value: gps.radiusM,
                    onChanged: (v) {
                      gps.radiusM = v;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            if (gps.spot == null)
              Text(
                'Noch kein Spot gespeichert. Am Lernplatz auf den Button '
                'tippen, dann weggehen und zurückkommen.',
                style: theme.textTheme.bodySmall,
              )
            else if (d != null) ...[
              Row(
                children: [
                  Icon(
                    inside! ? Icons.check_circle : Icons.cancel,
                    color: inside ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    inside ? 'Im Spot' : 'Außerhalb',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text('Entfernung: ${_fmtDist(d)}'),
                ],
              ),
              if (p != null && p.accuracy > gps.radiusM)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '⚠ Genauigkeit (±${p.accuracy.toStringAsFixed(0)} m) ist '
                    'schlechter als der Radius – Ergebnis unzuverlässig '
                    '(typisch in Gebäuden).',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.orange[800]),
                  ),
                ),
            ],
            if (gps.error != null) ...[
              const SizedBox(height: 8),
              Text(
                gps.error!,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PickupCard extends StatelessWidget {
  const PickupCard({super.key, required this.detector, required this.onChanged});

  final PickupDetector detector;
  final VoidCallback onChanged;

  Widget _meter(BuildContext context, String label, double value,
      double threshold, String unit) {
    final over = value > threshold;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${value.toStringAsFixed(2)} $unit '
            '(Schwelle ${threshold.toStringAsFixed(2)})',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            // Bar full = 2× threshold, middle = threshold.
            value: (value / (threshold * 2)).clamp(0.0, 1.0),
            color: over ? Colors.red : Colors.teal,
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final det = detector;
    final theme = Theme.of(context);

    final (stateText, stateColor) = switch (det.state) {
      PickupState.armed => ('Liegt ruhig – scharf', Colors.green),
      PickupState.moving => ('Bewegung', Colors.red),
      PickupState.settling =>
        (det.requireFlat && !det.isFlat ? 'Nicht abgelegt' : 'Beruhigt sich…',
            Colors.grey),
    };

    final last = det.lastPickup;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              icon: Icons.back_hand,
              title: 'Pickup-Erkennung',
              trailing: Chip(
                label: Text(stateText),
                backgroundColor: stateColor.withValues(alpha: 0.15),
                side: BorderSide(color: stateColor),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${det.pickups}', style: theme.textTheme.displaySmall),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    det.pickups == 1 ? 'Pickup' : 'Pickups',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Zähler 0'),
                  onPressed: () {
                    det.resetCount();
                    onChanged();
                  },
                ),
              ],
            ),
            if (last != null)
              Text(
                'Letzter Pickup: ${last.hour.toString().padLeft(2, '0')}:'
                '${last.minute.toString().padLeft(2, '0')}:'
                '${last.second.toString().padLeft(2, '0')}',
                style: theme.textTheme.bodySmall,
              ),
            _meter(context, '| |a| − 9,81 |', det.accelDeviation,
                det.accelThreshold, 'm/s²'),
            _meter(context, '|ω|', det.gyroMagnitude, det.gyroThreshold,
                'rad/s'),
            const Divider(height: 20),
            Text('Einstellungen', style: theme.textTheme.titleSmall),
            _slider(
              'Beschl.-Schwelle',
              '${det.accelThreshold.toStringAsFixed(1)} m/s²',
              det.accelThreshold,
              0.3,
              5,
              (v) => det.accelThreshold = v,
            ),
            _slider(
              'Gyro-Schwelle',
              '${det.gyroThreshold.toStringAsFixed(1)} rad/s',
              det.gyroThreshold,
              0.1,
              3,
              (v) => det.gyroThreshold = v,
            ),
            _slider(
              'Ruhezeit',
              '${(det.restTime.inMilliseconds / 1000).toStringAsFixed(1)} s',
              det.restTime.inMilliseconds / 1000,
              0.5,
              5,
              (v) => det.restTime = Duration(milliseconds: (v * 1000).round()),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Nur scharf, wenn Handy flach liegt'),
              subtitle: Text('Aktuell flach: ${det.isFlat ? 'ja' : 'nein'}'),
              value: det.requireFlat,
              onChanged: (v) {
                det.requireFlat = v;
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider(String label, String valueText, double value, double min,
      double max, void Function(double) set) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label)),
        Expanded(
          child: Slider(
            min: min,
            max: max,
            value: value.clamp(min, max),
            onChanged: (v) {
              set(v);
              onChanged();
            },
          ),
        ),
        SizedBox(width: 70, child: Text(valueText, textAlign: TextAlign.end)),
      ],
    );
  }
}
