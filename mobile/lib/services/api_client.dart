import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'auth_service.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Belt + suspenders: even if AuthService throws (e.g. Firebase plugin
        // not initialised on this build), the request still goes through
        // without an Authorization header rather than crashing the isolate.
        try {
          final auth = ref.read(authServiceProvider);
          final token = await auth.currentIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          debugPrint('Skipping auth token (Firebase not ready): $e');
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          // Token expired/invalid → surface as auth failure for the UI to
          // route the user back to login. We don't auto-retry here.
          try {
            ref.read(authServiceProvider).markUnauthenticated();
          } catch (_) {}
        }
        handler.next(err);
      },
    ),
  );
  return dio;
});
