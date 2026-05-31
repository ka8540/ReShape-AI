import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

/// Periodic /health probe. Polls every 20s; refreshes immediately when the
/// widget tree first reads it.
final backendReachableProvider = StreamProvider<bool>((ref) {
  final api = ref.watch(apiServiceProvider);
  final controller = StreamController<bool>();
  Timer? timer;

  Future<void> tick() async {
    final ok = await api.ping();
    if (!controller.isClosed) controller.add(ok);
  }

  tick();
  timer = Timer.periodic(const Duration(seconds: 20), (_) => tick());

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });
  return controller.stream;
});
