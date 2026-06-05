import 'dart:async';

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

class _FakeApi extends ApiService {
  _FakeApi({
    required this.designs,
    this.generateReturns,
    this.hangGenerate = false,
  }) : super(Dio());

  List<Map<String, dynamic>> designs;
  List<Map<String, dynamic>>? generateReturns;
  bool hangGenerate;
  int generateCalls = 0;
  bool selectCalled = false;
  String? selectedId;

  final Completer<List<Map<String, dynamic>>> _never = Completer();

  @override
  Future<List<Map<String, dynamic>>> listDesigns(String projectId) async =>
      designs;

  @override
  Future<List<Map<String, dynamic>>> generateLayouts({
    required String projectId,
    int variants = 3,
    String? referenceMediaId,
  }) async {
    generateCalls++;
    if (hangGenerate) return _never.future;
    if (generateReturns != null) designs = generateReturns!;
    return designs;
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
    final api = _FakeApi(designs: const [], hangGenerate: true);
    await _pump(tester, api);

    expect(find.text('Generating your room layout…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
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
    final api = _FakeApi(designs: const [], generateReturns: const []);
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
