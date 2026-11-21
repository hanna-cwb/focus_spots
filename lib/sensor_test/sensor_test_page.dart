// Minimal sensor test screen.
// Run it with: flutter run -t lib/main_sensor_test.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../firebase_init.dart';
import '../sensors/pickup_detector.dart';

class SensorTestApp extends StatelessWidget {
  const SensorTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor-Test',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const SensorTestPage(),
    );
  }
}

class SensorTestPage extends StatefulWidget {
  const SensorTestPage({super.key});

  @override
  State<SensorTestPage> createState() => _SensorTestPageState();
}

class _SensorTestPageState extends State<SensorTestPage> {
  final _pickup = PickupDetector();
  final List<StreamSubscription<dynamic>> _subs = [];

  List<double>? _accel;
  List<double>? _gyro;
  Position? _position;
  String _gpsInfo = 'Warte…';
  String _firebaseInfo = 'Warte…';

  @override
  void initState() {
    super.initState();
    _subs.add(accelerometerEventStream().listen((e) {
      _accel = [e.x, e.y, e.z];
      _pickup.onAccel(_accel!);
      setState(() {});
    }));
    _subs.add(gyroscopeEventStream().listen((e) {
      _gyro = [e.x, e.y, e.z];
      _pickup.onGyro(_gyro!);
    }));
    _startGps();
    _testFirebase();
  }

  Future<void> _startGps() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _gpsInfo = 'Keine Standortberechtigung');
        return;
      }
      _subs.add(Geolocator.getPositionStream().listen(
        (p) => setState(() => _position = p),
        onError: (Object e) => setState(() => _gpsInfo = '$e'),
      ));
    } catch (e) {
      setState(() => _gpsInfo = '$e');
    }
  }

  /// Writes a document and reads it back from the server (not the cache).
  Future<void> _testFirebase() async {
    if (firebaseInitError != null) {
      setState(() => _firebaseInfo = 'Init fehlgeschlagen: $firebaseInitError');
      return;
    }
    setState(() => _firebaseInfo = 'Teste…');
    try {
      final doc =
          FirebaseFirestore.instance.collection('_connection_test').doc('ping');
      await doc
          .set({'at': FieldValue.serverTimestamp()})
          .timeout(const Duration(seconds: 10));
      await doc
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));
      _firebaseInfo = 'OK';
    } catch (e) {
      _firebaseInfo = 'Fehler: $e';
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  String _fmt(List<double>? v) =>
      v == null ? 'Keine Daten' : v.map((x) => x.toStringAsFixed(2)).join('  ');

  @override
  Widget build(BuildContext context) {
    final p = _position;
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor-Test')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('Firebase'),
            subtitle: Text(_firebaseInfo),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _testFirebase,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('GPS'),
            subtitle: Text(p == null
                ? _gpsInfo
                : '${p.latitude.toStringAsFixed(5)}, '
                    '${p.longitude.toStringAsFixed(5)}  '
                    '(±${p.accuracy.toStringAsFixed(0)} m)'),
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Beschleunigung (m/s²)'),
            subtitle: Text(_fmt(_accel)),
          ),
          ListTile(
            leading: const Icon(Icons.threesixty),
            title: const Text('Gyroskop (rad/s)'),
            subtitle: Text(_fmt(_gyro)),
          ),
          ListTile(
            leading: const Icon(Icons.back_hand),
            title: Text('Pickups: ${_pickup.pickups}'),
            subtitle: Text('Status: ${_pickup.state.name}'),
            trailing: IconButton(
              icon: const Icon(Icons.restart_alt),
              onPressed: () => setState(_pickup.resetCount),
            ),
          ),
        ],
      ),
    );
  }
}
