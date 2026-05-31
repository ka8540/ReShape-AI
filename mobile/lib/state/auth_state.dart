import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// Higher-level auth state combining the raw Firebase stream with a
/// backend-synced local user. When [enableFirebase] is false (default for
/// the design-pass build) this provider exposes a guest state without
/// blocking the rest of the app.
enum AppAuthStatus { booting, unauthenticated, authenticated, guest }

class AppAuthState {
  const AppAuthState({
    required this.status,
    this.firebaseUser,
    this.localUser,
    this.error,
  });

  final AppAuthStatus status;
  final User? firebaseUser;
  final Map<String, dynamic>? localUser;
  final String? error;

  AppAuthState copyWith({
    AppAuthStatus? status,
    User? firebaseUser,
    Map<String, dynamic>? localUser,
    String? error,
    bool clearError = false,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      localUser: localUser ?? this.localUser,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AppAuthController extends StateNotifier<AppAuthState> {
  AppAuthController(this._ref)
    : super(
        enableFirebase
            ? const AppAuthState(status: AppAuthStatus.booting)
            : const AppAuthState(status: AppAuthStatus.guest),
      ) {
    if (enableFirebase) _listen();
  }

  final Ref _ref;

  void _listen() {
    _ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) async {
      final user = next.valueOrNull;
      if (user == null) {
        state = state.copyWith(
          status: AppAuthStatus.unauthenticated,
          firebaseUser: null,
          localUser: null,
        );
        return;
      }
      state = state.copyWith(
        status: AppAuthStatus.booting,
        firebaseUser: user,
        clearError: true,
      );
      try {
        final api = _ref.read(apiServiceProvider);
        final session = await api.postSession();
        state = state.copyWith(
          status: AppAuthStatus.authenticated,
          localUser: session,
        );
      } catch (e) {
        debugPrint('POST /auth/session failed: $e');
        state = state.copyWith(
          status: AppAuthStatus.authenticated,
          error: 'Could not sync user with backend',
        );
      }
    }, fireImmediately: true);
  }

  /// Lets the user continue without Firebase (useful for the mock-data
  /// design-pass build).
  void continueAsGuest() {
    state = const AppAuthState(status: AppAuthStatus.guest);
  }

  Future<void> signOut() async {
    await _ref.read(authServiceProvider).signOut();
    state = const AppAuthState(status: AppAuthStatus.unauthenticated);
  }
}

final appAuthControllerProvider =
    StateNotifierProvider<AppAuthController, AppAuthState>((ref) {
  return AppAuthController(ref);
});
