import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

/// Backend-backed list of the current user's projects. Consumed by screens
/// when `useMockData=false` (see [apiConfig]). Otherwise the existing
/// `ProjectController` mock state is used.
final remoteProjectsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.listProjects();
});

/// One-shot mutation: create a project. Returns the new row so callers can
/// route into it. Invalidates [remoteProjectsProvider] on success.
final createProjectProvider = Provider<
    Future<Map<String, dynamic>> Function({
  required String name,
  String? room,
  String mode,
  String? notes,
})>((ref) {
  return ({required String name, String? room, String mode = 'reshuffle', String? notes}) async {
    final api = ref.read(apiServiceProvider);
    final created = await api.createProject(
      name: name,
      room: room,
      mode: mode,
      notes: notes,
    );
    ref.invalidate(remoteProjectsProvider);
    return created;
  };
});
