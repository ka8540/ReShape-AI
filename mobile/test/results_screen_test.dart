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

class _FakeApi extends ApiService {
  _FakeApi({
    required this.designs,
    this.urls = const {},
    this.generateReturns,
    this.hangGenerate = false,
  }) : super(Dio());

  List<Map<String, dynamic>> designs;
  Map<String, String> urls;
  List<Map<String, dynamic>>? generateReturns;
  bool hangGenerate;
  bool selectCalled = false;
  String? selectedId;

  final Completer<List<Map<String, dynamic>>> _never = Completer();

  @override
  Future<List<Map<String, dynamic>>> listDesigns(String projectId) async {
    return designs;
  }

  @override
  Future<Map<String, dynamic>> getDesign({
    required String projectId,
    required String designId,
  }) async {
    return {
      'id': designId,
      'generation_status': 'succeeded',
      'output_read_url': urls[designId],
    };
  }

  @override
  Future<List<Map<String, dynamic>>> generateLayouts({
    required String projectId,
    int variants = 3,
    String? referenceMediaId,
  }) async {
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
  testWidgets('shows a loading/generating state while generating', (
    tester,
  ) async {
    // Empty designs → auto-generate, which never completes → stays generating.
    final api = _FakeApi(designs: const [], hangGenerate: true);
    await _pump(tester, api);

    expect(find.text('Generating your room layout…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('shows real backend image URL when designs exist', (tester) async {
    final api = _FakeApi(
      designs: [
        {'id': 'd1', 'generation_status': 'succeeded', 'is_selected': false},
        {'id': 'd2', 'generation_status': 'succeeded', 'is_selected': false},
      ],
      urls: {
        'd1': 'https://cdn.example.com/d1.png',
        'd2': 'https://cdn.example.com/d2.png',
      },
    );
    await _pump(tester, api);

    expect(find.text('Generated layouts'), findsOneWidget);
    expect(find.text('Choose the layout you want to use.'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is CachedNetworkImage && w.imageUrl == 'https://cdn.example.com/d1.png',
      ),
      findsWidgets,
    );
  });

  testWidgets('does NOT render Grid/Swipe/Compare or fake titles in real mode', (
    tester,
  ) async {
    final api = _FakeApi(
      designs: [
        {'id': 'd1', 'generation_status': 'succeeded', 'is_selected': false},
      ],
      urls: {'d1': 'https://cdn.example.com/d1.png'},
    );
    await _pump(tester, api);

    expect(find.text('Grid'), findsNothing);
    expect(find.text('Swipe'), findsNothing);
    expect(find.text('Compare'), findsNothing);
    expect(find.text('The Open Studio'), findsNothing);
    expect(find.text('Focused Work Corner'), findsNothing);
    expect(find.text('Cosy Lounge'), findsNothing);
  });

  testWidgets('shows empty state when no designs are generated', (tester) async {
    // List empty, and generation also returns nothing → honest empty state.
    final api = _FakeApi(designs: const [], generateReturns: const []);
    await _pump(tester, api);

    expect(find.text('No layouts yet'), findsOneWidget);
    expect(find.text('Regenerate'), findsOneWidget);
  });

  testWidgets('selecting a design persists it and continues to final', (
    tester,
  ) async {
    final api = _FakeApi(
      designs: [
        {'id': 'd1', 'generation_status': 'succeeded', 'is_selected': false},
        {'id': 'd2', 'generation_status': 'succeeded', 'is_selected': false},
      ],
      urls: {
        'd1': 'https://cdn.example.com/d1.png',
        'd2': 'https://cdn.example.com/d2.png',
      },
    );
    await _pump(tester, api);

    // Pick the second layout via its thumbnail.
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is CachedNetworkImage && w.imageUrl == 'https://cdn.example.com/d2.png',
      ).last,
    );
    await tester.pump();
    expect(find.text('Layout 2'), findsOneWidget);

    // Confirm selection -> calls select API and routes to final.
    await tester.tap(find.text('Use this layout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(api.selectCalled, isTrue);
    expect(api.selectedId, 'd2');
    expect(find.text('FINAL SCREEN'), findsOneWidget);
  });
}
