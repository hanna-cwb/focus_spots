import 'package:flutter/material.dart';

import 'firebase_init.dart';
import 'sensor_test/sensor_test_page.dart';

/// Separate entry point for the sensor test screen:
/// flutter run -t lib/main_sensor_test.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  runApp(const SensorTestApp());
}
