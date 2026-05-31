import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps Firebase Auth + Google Sign-In and exposes the current Firebase ID
/// token. Every Firebase touch is guarded by `Firebase.apps.isNotEmpty` so the
/// app can run with `ENABLE_FIREBASE=false` (the design-pass / mock-data build)
/// without ever calling `FirebaseAuth.instance`, which would otherwise throw
/// `[core/no-app] No Firebase App '[DEFAULT]' has been created`.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuthOverride = firebaseAuth,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth? _firebaseAuthOverride;
  final GoogleSignIn _googleSignIn;

  /// Returns the FirebaseAuth instance if Firebase has been initialised,
  /// otherwise null. Reading `FirebaseAuth.instance` before `initializeApp`
  /// throws synchronously, so we must check first.
  FirebaseAuth? get _firebaseAuth {
    if (_firebaseAuthOverride != null) return _firebaseAuthOverride;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance;
  }

  bool get isFirebaseReady => _firebaseAuth != null;

  Stream<User?> authStateChanges() {
    final auth = _firebaseAuth;
    if (auth == null) return Stream<User?>.value(null);
    return auth.authStateChanges();
  }

  User? get currentUser => _firebaseAuth?.currentUser;

  Future<String?> currentIdToken({bool forceRefresh = false}) async {
    final auth = _firebaseAuth;
    if (auth == null) return null;
    final user = auth.currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken(forceRefresh);
    } catch (e) {
      debugPrint('Failed to fetch Firebase ID token: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    final auth = _requireAuth();
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    final auth = _requireAuth();
    return auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final auth = _requireAuth();
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      try {
        await credential.user?.updateDisplayName(name);
        await credential.user?.reload();
      } catch (e) {
        debugPrint('updateDisplayName failed: $e');
      }
    }
    return credential;
  }

  Future<void> sendPasswordReset(String email) {
    final auth = _requireAuth();
    return auth.sendPasswordResetEmail(email: email.trim());
  }

  FirebaseAuth _requireAuth() {
    final auth = _firebaseAuth;
    if (auth == null) {
      throw StateError(
        'Firebase is not initialised. Run with '
        '--dart-define=ENABLE_FIREBASE=true and ensure the GoogleService '
        'config files are in place.',
      );
    }
    return auth;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    final auth = _firebaseAuth;
    if (auth == null) return;
    try {
      await auth.signOut();
    } catch (_) {}
  }

  void markUnauthenticated() {
    // Hook for interceptors: in a full implementation, push the user back to
    // login. Kept minimal here so the mock-data flow still compiles.
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});
