import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'firebase_init.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

// The former sensor test screen now lives in lib/sensor_test/.
// Run it with: flutter run -t lib/main_sensor_test.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  runApp(const FocusSpotsApp());
}

class FocusSpotsApp extends StatefulWidget {
  const FocusSpotsApp({super.key});

  @override
  State<FocusSpotsApp> createState() => _FocusSpotsAppState();
}

class _FocusSpotsAppState extends State<FocusSpotsApp> {
  final _state = AppState();

  /// null while checking, true once onboarding is done.
  bool? _onboarded;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  /// Without local storage yet, onboarding counts as done once location
  /// access has been granted.
  Future<void> _checkOnboarding() async {
    var granted = false;
    try {
      final perm = await Geolocator.checkPermission();
      granted = perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always;
    } catch (_) {}
    if (mounted) setState(() => _onboarded = granted);
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget home = switch (_onboarded) {
      null => const Scaffold(),
      false => OnboardingScreen(onFinished: () => setState(() => _onboarded = true)),
      true => const ShellScreen(),
    };

    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'Focus Spots',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: home,
      ),
    );
  }
}
