import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';

enum FirebaseStatus {
  /// `--dart-define=ENABLE_FIREBASE=false` (or unset). Auth disabled — login
  /// screen prompts you to re-run with the flag.
  disabled,

  /// Firebase initialised cleanly; login screen can render real auth UI.
  ready,

  /// `ENABLE_FIREBASE=true` was passed but `Firebase.initializeApp` failed —
  /// usually because `GoogleService-Info.plist` / `google-services.json`
  /// aren't in place. Login screen shows setup instructions and the actual
  /// error so the user can fix it.
  configError,
}

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult(this.status, [this.error]);

  final FirebaseStatus status;
  final Object? error;
}

/// Initializes Firebase if `--dart-define=ENABLE_FIREBASE=true`.
/// Returns a status describing what happened so the UI can react.
Future<FirebaseBootstrapResult> bootstrapFirebase() async {
  if (!enableFirebase) {
    return const FirebaseBootstrapResult(FirebaseStatus.disabled);
  }
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    return const FirebaseBootstrapResult(FirebaseStatus.ready);
  } catch (e, st) {
    debugPrint('Firebase initialisation failed: $e\n$st');
    return FirebaseBootstrapResult(FirebaseStatus.configError, e);
  }
}

/// Set in `main.dart` once `bootstrapFirebase()` completes, by overriding the
/// provider on the root `ProviderScope`. Login screen reads this to decide
/// what to show.
final firebaseStatusProvider = Provider<FirebaseBootstrapResult>(
  (ref) => const FirebaseBootstrapResult(FirebaseStatus.disabled),
);
