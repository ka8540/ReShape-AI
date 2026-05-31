import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'api_config.dart';

/// Initializes Firebase if `--dart-define=ENABLE_FIREBASE=true`.
///
/// Returns true when Firebase was successfully initialised. Failures are
/// swallowed and logged so the rest of the app keeps booting (the mock-data
/// design build runs without GoogleService-Info.plist / google-services.json).
Future<bool> bootstrapFirebase() async {
  if (!enableFirebase) return false;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    return true;
  } catch (e, st) {
    debugPrint('Firebase initialisation failed: $e\n$st');
    return false;
  }
}
