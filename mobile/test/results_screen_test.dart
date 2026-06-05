import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:respace_ai/screens/screens.dart';
import 'package:respace_ai/services/api_service.dart';
import 'package:respace_ai/state/project_state.dart';

Map<String, dynamic> _design(
  String id, {
  required String status,
  String? url,
  String? error,
}) {
  return {
    'id': id,
    'project_id': 'p1',
    'generation_status': status,
    'is_selected': false,
    'output_read_url': url,
    'error_code': error == null ? null : 'GEMINI_AUTH_FAILED',
    'error_message': error,
  };
}

Map<String, dynamic> _generationStatus({
  required String status,
  int total = 1,
  int queued = 0,
  int running = 0,
  int succeeded = 0,
  int failed = 0,
  String? error,
}) {
  return {
    'project_id': 'p1',
    'status': status,
    'designs_ready': succeeded,
    'designs_requested': total,
    'total': total,
    'queued': queued,
    'running': running,
    'succeeded': succeeded,
    'failed': failed,
    'error_code': error == null ? null : 'GENERATION_FAILED',
    'error_message': error,
  };
}

class _FakeApi extends ApiService {
  _FakeApi({
    required this.designs,
    this.generateReturns,
    this.statuses = const [],
    this.designsAfterCompleted,
    this.generateError,
  }) : super(Dio());

  List<Map<String, dynamic>> designs;
  List<Map<String, dynamic>>? generateReturns;
  List<Map<String, dynamic>> statuses;
  List<Map<String, dynamic>>? designsAfterCompleted;
  Object? generateError;
  int generateCalls = 0;
  int statusCalls = 0;
  bool selectCalled = false;
  String? selectedId;

  @override
  Future<List<Map<String, dynamic>>> listDesigns(String projectId) async =>
      designs;

  @override
  Future<Map<String, dynamic>> generateLayouts({
    required String projectId,
    int variants = 3,
    String? referenceMediaId,
  }) async {
    generateCalls++;
    final error = generateError;
    if (error is DioException) throw error;
    if (error is ApiException) throw error;
    if (error != null) throw error;
    if (generateReturns != null) designs = generateReturns!;
    return _statusFromDesigns();
  }

  @override
  Future<Map<String, dynamic>> generationStatus(String projectId) async {
    final index = statusCalls;
    statusCalls++;
    final status = statuses.isEmpty
        ? _statusFromDesigns()
        : statuses[index < statuses.length ? index : statuses.length - 1];
    final normalized = status['status']?.toString();
    if ((normalized == 'completed' || normalized == 'succeeded') &&
        designsAfterCompleted != null) {
      designs = designsAfterCompleted!;
    }
    return status;
  }

  Map<String, dynamic> _statusFromDesigns() {
    var queued = 0;
    var running = 0;
    var succeeded = 0;
    var failed = 0;
    String? error;
    for (final design in designs) {
      switch (design['generation_status']) {
        case 'queued':
        case 'pending':
          queued++;
          break;
        case 'running':
        case 'processing':
          running++;
          break;
        case 'succeeded':
          succeeded++;
          break;
        case 'failed':
          failed++;
          error ??= design['error_message']?.toString();
          break;
      }
    }
    final total = designs.length;
    final status = queued + running > 0
        ? 'running'
        : succeeded > 0
        ? 'completed'
        : failed > 0
        ? 'failed'
        : 'completed';
    return _generationStatus(
      status: status,
      total: total,
      queued: queued,
      running: running,
      succeeded: succeeded,
      failed: failed,
      error: error,
    );
  }

  @override
  Future<Map<String, dynamic>> selectDesign({
    required String projectId,
    required String designId,
  }) async {
    selectCalled = true;
    selectedId = designId;
    return {'id': designId, 'is_selected': true};
  }
}

Future<void> _pump(WidgetTester tester, _FakeApi api) async {
  tester.view.physicalSize = const Size(1200, 2800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [apiServiceProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  container.read(projectControllerProvider.notifier).setRemoteProjectId('p1');

  final router = GoRouter(
    initialLocation: '/results',
    routes: [
      GoRoute(path: '/results', builder: (_, _) => const ResultsScreen()),
      GoRoute(
        path: '/final',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('FINAL SCREEN'))),
      ),
      GoRoute(
        path: '/preferences',
        builder: (_, _) => const Scaffold(body: Text('PREFS')),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 40));
  await tester.pump(const Duration(milliseconds: 40));
}

void main() {
  testWidgets('shows generating state while generation is running', (
    tester,
  ) async {
    final api = _FakeApi(
      designs: const [],
      generateReturns: [
        _design('d1', status: 'queued'),
      ],
      statuses: [
        _generationStatus(status: 'running', total: 1, queued: 1),
      ],
    );
    await _pump(tester, api);

    expect(find.text('Generating your room layout…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(api.generateCalls, 1);
    expect(api.statusCalls, 1);
  });

  testWidgets('renders the real output_read_url when designs are ready', (
    tester,
  ) async {
    final api = _FakeApi(
      designs: [
        _design('d1', status: 'succeeded', url: 'https://cdn.example.com/d1.png'),
        _design('d2', status: 'succeeded', url: 'https://cdn.example.com/d2.png'),
      ],
    );
    await _pump(tester, api);

    expect(find.text('Generated layouts'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is CachedNetworkImage && w.imageUrl == 'https://cdn.example.com/d1.png',
      ),
      findsWidgets,
    );
  });

  testWidgets('shows the backend failure message in the error state', (
    tester,
  ) async {
    final api = _FakeApi(
      designs: [
        _design(
          'd1',
          status: 'failed',
          error: 'Gemini authentication failed. Use a valid Google AI Studio API key.',
        ),
      ],
    );
    await _pump(tester, api);

    expect(find.text('Generation failed'), findsOneWidget);
    expect(
      find.text('Gemini authentication failed. Use a valid Google AI Studio API key.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('shows the backend polling failure message in the error state', (
    tester,
  ) async {
    final api = _FakeApi(
      designs: const [],
      generateReturns: [
        _design('d1', status: 'queued'),
      ],
      statuses: [
        _generationStatus(
          status: 'failed',
          total: 1,
          failed: 1,
          error: 'Gemini model is unavailable for this API key.',
        ),
      ],
    );
    await _pump(tester, api);

    expect(find.text('Generation failed'), findsOneWidget);
    expect(
      find.text('Gemini model is unavailable for this API key.'),
      findsOneWidget,
    );
  });

  testWidgets('receive timeout maps to a friendly message', (tester) async {
    final api = _FakeApi(
      designs: const [],
      generateError: DioException(
        requestOptions: RequestOptions(path: '/projects/p1/generate-layouts'),
        type: DioExceptionType.receiveTimeout,
        message:
            'The request took longer than 0:00:30.000000 to receive data.',
      ),
    );
    await _pump(tester, api);

    expect(find.text('Generation failed'), findsOneWidget);
    expect(
      find.text(
        'The server is still taking too long to respond. Try again in a moment.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('DioException'), findsNothing);
    expect(find.textContaining('0:00:30'), findsNothing);
  });

  testWidgets('polls status until completed and then renders the real image', (
    tester,
  ) async {
    final api = _FakeApi(
      designs: const [],
      generateReturns: [
        _design('d1', status: 'queued'),
      ],
      statuses: [
        _generationStatus(status: 'running', total: 1, queued: 1),
        _generationStatus(status: 'completed', total: 1, succeeded: 1),
      ],
      designsAfterCompleted: [
        _design('d1', status: 'succeeded', url: 'https://cdn.example.com/d1.png'),
      ],
    );
    await _pump(tester, api);

    expect(find.text('Generating your room layout…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();

    expect(api.statusCalls, 2);
    expect(find.text('Generated layouts'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is CachedNetworkImage &&
            w.imageUrl == 'https://cdn.example.com/d1.png',
      ),
      findsWidgets,
    );
  });

  testWidgets('no fake gallery text in real mode', (tester) async {
    final api = _FakeApi(
      designs: [
        _design('d1', status: 'succeeded', url: 'https://cdn.example.com/d1.png'),
      ],
    );
    await _pump(tester, api);

    expect(find.text('Grid'), findsNothing);
    expect(find.text('Swipe'), findsNothing);
    expect(find.text('Compare'), findsNothing);
    expect(find.text('The Open Studio'), findsNothing);
    expect(find.text('Focused Work Corner'), findsNothing);
  });

  testWidgets('empty state when nothing is generated', (tester) async {
    final api = _FakeApi(
      designs: const [],
      generateReturns: const [],
      statuses: [
        _generationStatus(status: 'completed', total: 0),
      ],
    );
    await _pump(tester, api);

    expect(find.text('No layouts yet'), findsOneWidget);
    expect(find.text('Regenerate'), findsOneWidget);
  });

  testWidgets('Regenerate calls the backend and can recover to ready', (
    tester,
  ) async {
    final api = _FakeApi(
      designs: [
        _design('d1', status: 'failed', error: 'Gemini auth failed.'),
      ],
      generateReturns: [
        _design('d2', status: 'queued'),
      ],
      statuses: [
        _generationStatus(status: 'completed', total: 1, succeeded: 1),
      ],
      designsAfterCompleted: [
        _design('d2', status: 'succeeded', url: 'https://cdn.example.com/d2.png'),
      ],
    );
    await _pump(tester, api);

    expect(find.text('Generation failed'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(api.generateCalls, 1);
    expect(
      find.byWidgetPredicate(
        (w) => w is CachedNetworkImage && w.imageUrl == 'https://cdn.example.com/d2.png',
      ),
      findsWidgets,
    );
  });

  testWidgets('selecting a layout persists it and continues to final', (
    tester,
  ) async {
    final api = _FakeApi(
      designs: [
        _design('d1', status: 'succeeded', url: 'https://cdn.example.com/d1.png'),
        _design('d2', status: 'succeeded', url: 'https://cdn.example.com/d2.png'),
      ],
    );
    await _pump(tester, api);

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is CachedNetworkImage && w.imageUrl == 'https://cdn.example.com/d2.png',
      ).last,
    );
    await tester.pump();
    expect(find.text('Layout 2'), findsOneWidget);

    await tester.tap(find.text('Use this layout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(api.selectCalled, isTrue);
    expect(api.selectedId, 'd2');
    expect(find.text('FINAL SCREEN'), findsOneWidget);
  });
}
