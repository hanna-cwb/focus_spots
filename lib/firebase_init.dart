import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Set if Firebase.initializeApp fails, so the app still starts and the
/// error can be shown (e.g. in the sensor test's Firebase card).
Object? firebaseInitError;

/// Initializes Firebase. Never throws; on failure the error is stored in
/// [firebaseInitError]. Call after WidgetsFlutterBinding.ensureInitialized().
Future<void> initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    firebaseInitError = e;
    debugPrint('Firebase.initializeApp failed: $e');
  }
}
