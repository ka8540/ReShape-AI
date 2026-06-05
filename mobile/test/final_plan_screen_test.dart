import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:respace_ai/screens/screens.dart';
import 'package:respace_ai/services/api_service.dart';
import 'package:respace_ai/state/project_state.dart';
import 'package:respace_ai/widgets/room_art.dart';

Map<String, dynamic> _designRow(String id, {bool selected = false}) {
  return {
    'id': id,
    'project_id': 'p1',
    'model_name': 'test',
    'prompt_version': 'test',
    'generation_status': 'succeeded',
    'is_selected': selected,
    'error_code': null,
    'error_message': null,
  };
}

Map<String, dynamic> _designDetail(
  String id, {
  String? outputUrl,
  String? referenceUrl,
}) {
  return {
    ..._designRow(id),
    'output_read_url': outputUrl,
    'reference_read_url': referenceUrl,
  };
}

Map<String, dynamic> _mediaRow(String id, {String kind = 'image'}) {
  return {
    'id': id,
    'project_id': 'p1',
    'media_kind': kind,
    'file_name': 'room.jpg',
    'mime_type': kind == 'image' ? 'image/jpeg' : 'video/quicktime',
    'file_size': 123,
    'upload_status': 'uploaded',
  };
}

Map<String, dynamic> _itemRow(
  String id,
  String name,
  String type, {
  bool fixed = false,
  bool structural = false,
}) {
  return {
    'id': id,
    'project_id': 'p1',
    'name': name,
    'type': type,
    'confidence': 0.9,
    'fixed': fixed,
    'structural': structural,
    'added_by_user': false,
  };
}

Map<String, dynamic> _savedPlan({String? planJson}) {
  return {
    'id': 'fp1',
    'project_id': 'p1',
    'selected_design_id': 'd1',
    'plan_json': planJson,
    'export_status': 'none',
    'export_url': null,
  };
}

class _FakeFinalPlanApi extends ApiService {
  _FakeFinalPlanApi({
    this.designs = const [],
    this.designDetails = const {},
    this.media = const [],
    this.mediaUrls = const {},
    this.items = const [],
    this.finalPlan,
  }) : super(Dio());

  final List<Map<String, dynamic>> designs;
  final Map<String, Map<String, dynamic>> designDetails;
  final List<Map<String, dynamic>> media;
  final Map<String, String> mediaUrls;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic>? finalPlan;
  bool saveCalled = false;

  @override
  Future<List<Map<String, dynamic>>> listDesigns(String projectId) async {
    return designs;
  }

  @override
  Future<Map<String, dynamic>> getDesign({
    required String projectId,
    required String designId,
  }) async {
    return designDetails[designId] ?? _designDetail(designId);
  }

  @override
  Future<List<Map<String, dynamic>>> listMedia(String projectId) async {
    return media;
  }

  @override
  Future<Map<String, dynamic>> getReadUrl({
    required String projectId,
    required String mediaId,
  }) async {
    return {'read_url': mediaUrls[mediaId]};
  }

  @override
  Future<List<Map<String, dynamic>>> listItems(String projectId) async {
    return items;
  }

  @override
  Future<Map<String, dynamic>?> getFinalPlan(String projectId) async {
    return finalPlan;
  }

  @override
  Future<Map<String, dynamic>> saveFinalPlan({
    required String projectId,
    required String selectedDesignId,
    String? planJson,
  }) async {
    saveCalled = true;
    return _savedPlan(planJson: planJson);
  }
}

Future<ProviderContainer> _pumpFinalPlan(
  WidgetTester tester,
  _FakeFinalPlanApi api, {
  String? selectedDesignId = 'd1',
  bool withRemoteProject = true,
}) async {
  tester.view.physicalSize = const Size(1200, 2800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [apiServiceProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  final controller = container.read(projectControllerProvider.notifier);
  if (withRemoteProject) controller.setRemoteProjectId('p1');
  if (selectedDesignId != null) controller.setSelectedDesign(selectedDesignId);

  final router = GoRouter(
    initialLocation: '/final',
    routes: [
      GoRoute(path: '/final', builder: (_, _) => const FinalPlanScreen()),
      GoRoute(
        path: '/results',
        builder: (_, _) => const Scaffold(body: Text('RESULTS')),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('HOME')),
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
  return container;
}

void main() {
  testWidgets('Final Plan renders selected generated image URL as After', (
    tester,
  ) async {
    final api = _FakeFinalPlanApi(
      designs: [_designRow('d1', selected: true)],
      designDetails: {
        'd1': _designDetail(
          'd1',
          outputUrl: 'https://cdn.example.com/generated.png',
          referenceUrl: 'https://cdn.example.com/reference.png',
        ),
      },
      finalPlan: _savedPlan(),
    );

    await _pumpFinalPlan(tester, api);

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is CachedNetworkImage &&
            w.imageUrl == 'https://cdn.example.com/generated.png',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Final Plan renders uploaded/reference image URL as Before', (
    tester,
  ) async {
    final api = _FakeFinalPlanApi(
      designs: [_designRow('d1', selected: true)],
      designDetails: {
        'd1': _designDetail(
          'd1',
          outputUrl: 'https://cdn.example.com/generated.png',
          referenceUrl: 'https://cdn.example.com/reference.png',
        ),
      },
      media: [_mediaRow('m1')],
      mediaUrls: {'m1': 'https://cdn.example.com/uploaded-room.jpg'},
      finalPlan: _savedPlan(),
    );

    await _pumpFinalPlan(tester, api);
    await tester.tap(find.text('Before'));
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is CachedNetworkImage &&
            w.imageUrl == 'https://cdn.example.com/uploaded-room.jpg',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'Final Plan does not render fake floor plan labels in real mode',
    (tester) async {
      final api = _FakeFinalPlanApi(
        designs: [_designRow('d1', selected: true)],
        designDetails: {
          'd1': _designDetail(
            'd1',
            outputUrl: 'https://cdn.example.com/generated.png',
          ),
        },
        items: [_itemRow('i1', 'Chair', 'chair')],
        finalPlan: _savedPlan(),
      );

      await _pumpFinalPlan(tester, api);

      expect(find.byType(FloorPlanView), findsNothing);
      for (final label in ['Desk', 'Bed', 'Sofa', 'Rug', 'TV', 'Shelf']) {
        expect(find.text(label), findsNothing);
      }
    },
  );

  testWidgets('Final Plan does not render fake moved items in real mode', (
    tester,
  ) async {
    final api = _FakeFinalPlanApi(
      designs: [_designRow('d1', selected: true)],
      designDetails: {
        'd1': _designDetail(
          'd1',
          outputUrl: 'https://cdn.example.com/generated.png',
        ),
      },
      finalPlan: _savedPlan(),
    );

    await _pumpFinalPlan(tester, api);

    expect(
      find.text('Moved item details are not available yet.'),
      findsOneWidget,
    );
    for (final label in [
      'Desk',
      'Bed',
      'Sofa',
      'Rug',
      'TV',
      'Window',
      'Door',
    ]) {
      expect(find.text(label), findsNothing);
    }
  });

  testWidgets('missing selected design shows an honest error state', (
    tester,
  ) async {
    final api = _FakeFinalPlanApi(
      media: [_mediaRow('m1')],
      mediaUrls: {'m1': 'https://cdn.example.com/uploaded-room.jpg'},
    );

    await _pumpFinalPlan(tester, api, selectedDesignId: null);

    expect(find.text('No generated layout selected yet.'), findsOneWidget);
  });

  testWidgets('missing generated image URL shows an honest error state', (
    tester,
  ) async {
    final api = _FakeFinalPlanApi(
      designs: [_designRow('d1', selected: true)],
      designDetails: {'d1': _designDetail('d1')},
      finalPlan: _savedPlan(),
    );

    await _pumpFinalPlan(tester, api);

    expect(
      find.text('Selected layout has no generated image.'),
      findsOneWidget,
    );
  });

  testWidgets('mock data only appears when USE_MOCK_DATA=true', (tester) async {
    final api = _FakeFinalPlanApi();

    await _pumpFinalPlan(
      tester,
      api,
      selectedDesignId: null,
      withRemoteProject: false,
    );

    expect(
      find.text('No backend project is available for the final plan.'),
      findsOneWidget,
    );
    expect(find.byType(RoomScene), findsNothing);
    expect(find.byType(FloorPlanView), findsNothing);
    expect(find.byType(GeneratedRoomImage), findsNothing);
    for (final label in ['Desk', 'Bed', 'Sofa', 'Rug', 'TV', 'Shelf']) {
      expect(find.text(label), findsNothing);
    }
  });
}
