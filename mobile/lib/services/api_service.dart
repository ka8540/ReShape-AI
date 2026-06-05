// ignore_for_file: use_null_aware_elements

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Thin typed layer over the FastAPI backend. Routes mirror `backend/API.md`.
///
/// Every method that hits a protected endpoint relies on the Dio interceptor
/// in [apiClientProvider] to attach the Firebase ID token. Methods raise
/// [ApiException] for non-2xx responses so callers can show consistent
/// error UI.
class ApiService {
  ApiService(this._dio);

  final Dio _dio;

  // ---------------------------------------------------------------- health

  Future<bool> ping() async {
    try {
      final res = await _dio.get<dynamic>(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------------ auth

  Future<Map<String, dynamic>> postSession() => _post('/auth/session');
  Future<Map<String, dynamic>> getAuthMe() => _get('/auth/me');

  // ----------------------------------------------------------------- users

  Future<Map<String, dynamic>> getMe() => _get('/users/me');
  Future<Map<String, dynamic>> getProjectsSummary() =>
      _get('/users/me/projects-summary');

  // -------------------------------------------------------------- projects

  Future<List<Map<String, dynamic>>> listProjects() async {
    final res = await _dio.get<dynamic>('/projects');
    return _asList(res.data);
  }

  Future<Map<String, dynamic>> createProject({
    required String name,
    String? room,
    String mode = 'reshuffle',
    String? notes,
  }) {
    return _post('/projects', data: {
      'name': name,
      if (room != null) 'room': room,
      'mode': mode,
      if (notes != null) 'notes': notes,
    });
  }

  Future<Map<String, dynamic>> getProject(String projectId) =>
      _get('/projects/$projectId');

  Future<void> deleteProject(String projectId) async {
    await _dio.delete<dynamic>('/projects/$projectId');
  }

  // ----------------------------------------------------------------- media

  Future<Map<String, dynamic>> requestUploadUrl({
    required String projectId,
    required String fileName,
    required String mimeType,
    required int fileSize,
    required String mediaKind, // image | video
  }) {
    return _post(
      '/projects/$projectId/media/upload-url',
      data: {
        'file_name': fileName,
        'mime_type': mimeType,
        'file_size': fileSize,
        'media_kind': mediaKind,
      },
    );
  }

  /// Performs the actual PUT to the signed R2 URL the backend returned.
  /// Skipped (returns false) when the URL looks like the mock fallback.
  Future<bool> putToSignedUrl({
    required String uploadUrl,
    required File file,
    required String contentType,
  }) async {
    if (uploadUrl.startsWith('mock://')) return false;
    final raw = Dio();
    final res = await raw.put<dynamic>(
      uploadUrl,
      data: file.openRead(),
      options: Options(
        headers: {
          HttpHeaders.contentTypeHeader: contentType,
          HttpHeaders.contentLengthHeader: await file.length(),
        },
      ),
    );
    return res.statusCode != null && res.statusCode! < 300;
  }

  Future<Map<String, dynamic>> completeUpload({
    required String projectId,
    required String mediaId,
  }) {
    return _post(
      '/projects/$projectId/media/complete',
      data: {'media_id': mediaId},
    );
  }

  Future<Map<String, dynamic>> getReadUrl({
    required String projectId,
    required String mediaId,
  }) =>
      _get('/projects/$projectId/media/$mediaId/read-url');

  // ------------------------------------------------------------ processing

  Future<Map<String, dynamic>> processingStatus(String projectId) =>
      _get('/projects/$projectId/processing-status');

  Future<Map<String, dynamic>> retryProcessing(String projectId) =>
      _post('/projects/$projectId/retry-processing');

  // ----------------------------------------------------------------- items

  Future<List<Map<String, dynamic>>> listItems(String projectId) async {
    final res = await _dio.get<dynamic>('/projects/$projectId/items');
    return _asList(res.data);
  }

  Future<Map<String, dynamic>> createItem({
    required String projectId,
    required String name,
    required String type,
    bool fixed = false,
    bool structural = false,
  }) {
    return _post(
      '/projects/$projectId/items',
      data: {
        'name': name,
        'type': type,
        'fixed': fixed,
        'structural': structural,
      },
    );
  }

  Future<Map<String, dynamic>> patchItem({
    required String projectId,
    required String itemId,
    Map<String, dynamic>? changes,
  }) async {
    final res = await _dio.patch<dynamic>(
      '/projects/$projectId/items/$itemId',
      data: changes ?? const {},
    );
    return _asMap(res.data);
  }

  Future<void> deleteItem({
    required String projectId,
    required String itemId,
  }) async {
    try {
      await _dio.delete<dynamic>('/projects/$projectId/items/$itemId');
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  // ----------------------------------------------------------- preferences

  Future<Map<String, dynamic>?> getPreferences(String projectId) async {
    try {
      final res = await _dio.get<dynamic>('/projects/$projectId/preferences');
      return _asMap(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _wrap(e);
    }
  }

  Future<Map<String, dynamic>> putPreferences({
    required String projectId,
    String? primaryGoal,
    String? style,
    String? constraintsJson,
  }) async {
    final res = await _dio.put<dynamic>(
      '/projects/$projectId/preferences',
      data: {
        'primary_goal': primaryGoal,
        'style': style,
        'constraints_json': constraintsJson,
      },
    );
    return _asMap(res.data);
  }

  // ------------------------------------------------------------ generation

  Future<List<Map<String, dynamic>>> generateLayouts({
    required String projectId,
    int variants = 3,
    String? referenceMediaId,
  }) async {
    final res = await _dio.post<dynamic>(
      '/projects/$projectId/generate-layouts',
      data: {
        'variants': variants,
        if (referenceMediaId != null) 'reference_media_id': referenceMediaId,
      },
    );
    return _asList(res.data);
  }

  Future<Map<String, dynamic>> generationStatus(String projectId) =>
      _get('/projects/$projectId/generation-status');

  // --------------------------------------------------------------- designs

  Future<List<Map<String, dynamic>>> listDesigns(String projectId) async {
    final res = await _dio.get<dynamic>('/projects/$projectId/designs');
    return _asList(res.data);
  }

  Future<Map<String, dynamic>> getDesign({
    required String projectId,
    required String designId,
  }) =>
      _get('/projects/$projectId/designs/$designId');

  Future<Map<String, dynamic>> selectDesign({
    required String projectId,
    required String designId,
  }) =>
      _post('/projects/$projectId/designs/$designId/select');

  // ------------------------------------------------------------ final plan

  Future<Map<String, dynamic>> saveFinalPlan({
    required String projectId,
    required String selectedDesignId,
    String? planJson,
  }) {
    return _post('/projects/$projectId/final-plan', data: {
      'selected_design_id': selectedDesignId,
      if (planJson != null) 'plan_json': planJson,
    });
  }

  Future<Map<String, dynamic>?> getFinalPlan(String projectId) async {
    try {
      final res = await _dio.get<dynamic>('/projects/$projectId/final-plan');
      return _asMap(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _wrap(e);
    }
  }

  // --------------------------------------------------------------- helpers

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await _dio.get<dynamic>(path);
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  Future<Map<String, dynamic>> _post(String path, {Object? data}) async {
    try {
      final res = await _dio.post<dynamic>(path, data: data);
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  ApiException _wrap(DioException e) {
    final code = e.response?.statusCode;
    final body = e.response?.data;
    return ApiException(
      statusCode: code,
      message: _extractMessage(body) ?? e.message ?? 'Network error',
      isUnauthorized: code == 401,
    );
  }

  static String? _extractMessage(dynamic body) {
    if (body is Map && body['detail'] != null) return body['detail'].toString();
    if (body is String && body.isNotEmpty) return body;
    return null;
  }
}

class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.isUnauthorized = false,
  });

  final int? statusCode;
  final String message;
  final bool isUnauthorized;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(apiClientProvider));
});
