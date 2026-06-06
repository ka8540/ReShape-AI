import 'dart:convert';

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
  String? planJson,
  String? planStatus,
  String? planError,
}) {
  return {
    ..._designRow(id),
    'output_read_url': outputUrl,
    'reference_read_url': referenceUrl,
    'layout_plan_json': planJson,
    'layout_plan_status': planStatus,
    'layout_plan_error': planError,
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
    'layout_plan_json': planJson,
    'layout_plan_status': planJson == null ? null : 'succeeded',
    'layout_plan_error': null,
    'selected_design_output_read_url': null,
    'selected_design_reference_read_url': null,
    'export_status': 'none',
    'export_url': null,
  };
}

String _planJson({
  String itemName = 'Chair',
  String itemId = 'i1',
  bool includeDesk = false,
}) {
  return jsonEncode({
    'room_summary': 'Approximate plan from the selected generated layout.',
    'floor_plan': {
      'width': 100,
      'height': 100,
      'items': [
        {
          'item_id': itemId,
          'name': itemName,
          'category': itemName.toLowerCase(),
          'x': 12,
          'y': 58,
          'width': 34,
          'height': 12,
          'rotation': 0,
          'status': 'moved',
          'fixed': false,
        },
        if (includeDesk)
          {
            'item_id': 'i-desk',
            'name': 'Desk',
            'category': 'desk',
            'x': 5,
            'y': 8,
            'width': 20,
            'height': 10,
            'rotation': 0,
            'status': 'moved',
            'fixed': false,
          },
      ],
    },
    'moved_items': [
      {
        'item_id': itemId,
        'name': itemName,
        'from': 'left wall',
        'to': 'window wall',
        'reason': 'opens a clearer walkway',
      },
    ],
    'fixed_items': [
      {'item_id': 'i-window', 'name': 'Window', 'reason': 'structural item'},
    ],
    'checklist': [
      {
        'step': 1,
        'title': 'Move the $itemName',
        'details': 'Clear the walking path first.',
      },
    ],
  });
}

/// A realistic multi-item plan: furniture boxes plus a full-room wall and a
/// window, mirroring what the backend actually returns.
String _multiItemPlanJson() {
  return jsonEncode({
    'room_summary': 'Approximate living-room layout.',
    'floor_plan': {
      'width': 100,
      'height': 100,
      'items': [
        {
          'item_id': 'i-sofa',
          'name': 'Sofa',
          'category': 'sofa',
          'x': 20,
          'y': 60,
          'width': 40,
          'height': 18,
          'rotation': 0,
          'status': 'moved',
          'fixed': false,
        },
        {
          'item_id': 'i-rug',
          'name': 'Rug',
          'category': 'rug',
          'x': 30,
          'y': 40,
          'width': 35,
          'height': 25,
          'rotation': 0,
          'status': 'unchanged',
          'fixed': false,
        },
        {
          'item_id': 'i-window',
          'name': 'Window',
          'category': 'window',
          'x': 20,
          'y': 0,
          'width': 60,
          'height': 8,
          'rotation': 0,
          'status': 'structural',
          'fixed': true,
        },
        {
          'item_id': 'i-wall',
          'name': 'Wall',
          'category': 'wall',
          'x': 0,
          'y': 0,
          'width': 100,
          'height': 100,
          'rotation': 0,
          'status': 'structural',
          'fixed': true,
        },
      ],
    },
    'moved_items': [
      {
        'item_id': 'i-sofa',
        'name': 'Sofa',
        'from': 'left wall',
        'to': 'window wall',
        'reason': 'opens a clearer walkway',
      },
    ],
    'fixed_items': [
      {'item_id': 'i-window', 'name': 'Window', 'reason': 'structural item'},
    ],
    'checklist': [
      {'step': 1, 'title': 'Move the Sofa', 'details': 'Clear the path first.'},
    ],
  });
}

/// A degenerate plan that only contains a wall while furniture was moved —
/// the renderer must warn instead of showing an empty card.
String _wallOnlyPlanJson() {
  return jsonEncode({
    'room_summary': 'Incomplete layout.',
    'floor_plan': {
      'width': 100,
      'height': 100,
      'items': [
        {
          'item_id': 'i-wall',
          'name': 'Wall',
          'category': 'wall',
          'x': 0,
          'y': 0,
          'width': 100,
          'height': 100,
          'rotation': 0,
          'status': 'structural',
          'fixed': true,
        },
      ],
    },
    'moved_items': [
      {
        'item_id': 'i-sofa',
        'name': 'Sofa',
        'from': 'left wall',
        'to': 'window wall',
        'reason': 'opens a clearer walkway',
      },
    ],
    'fixed_items': [],
    'checklist': [],
  });
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

  testWidgets('Final Plan renders floor plan from backend JSON', (
    tester,
  ) async {
    final planJson = _planJson(itemName: 'Armchair', itemId: 'i-armchair');
    final api = _FakeFinalPlanApi(
      designs: [_designRow('d1', selected: true)],
      designDetails: {
        'd1': _designDetail(
          'd1',
          outputUrl: 'https://cdn.example.com/generated.png',
          planJson: planJson,
          planStatus: 'succeeded',
        ),
      },
      items: [_itemRow('i-armchair', 'Armchair', 'chair')],
      finalPlan: _savedPlan(planJson: planJson),
    );

    await _pumpFinalPlan(tester, api);

    expect(find.text('Floor plan'), findsOneWidget);
    expect(find.text('Armchair'), findsWidgets);
    expect(
      find.text('Approximate plan from the selected generated layout.'),
      findsOneWidget,
    );
    expect(find.byType(FloorPlanView), findsNothing);
  });

  testWidgets('Final Plan renders moved item chips from backend JSON', (
    tester,
  ) async {
    final planJson = _planJson(itemName: 'Armchair', itemId: 'i-armchair');
    final api = _FakeFinalPlanApi(
      designs: [_designRow('d1', selected: true)],
      designDetails: {
        'd1': _designDetail(
          'd1',
          outputUrl: 'https://cdn.example.com/generated.png',
          planJson: planJson,
          planStatus: 'succeeded',
        ),
      },
      finalPlan: _savedPlan(planJson: planJson),
    );

    await _pumpFinalPlan(tester, api);

    expect(find.text('Moved'), findsOneWidget);
    expect(find.text('left wall -> window wall'), findsOneWidget);
    expect(find.text('opens a clearer walkway'), findsOneWidget);
  });

  testWidgets('Final Plan renders checklist from backend JSON', (tester) async {
    final planJson = _planJson(itemName: 'Armchair', itemId: 'i-armchair');
    final api = _FakeFinalPlanApi(
      designs: [_designRow('d1', selected: true)],
      designDetails: {
        'd1': _designDetail(
          'd1',
          outputUrl: 'https://cdn.example.com/generated.png',
          planJson: planJson,
          planStatus: 'succeeded',
        ),
      },
      finalPlan: _savedPlan(planJson: planJson),
    );

    await _pumpFinalPlan(tester, api);

    expect(find.text('Move the Armchair'), findsOneWidget);
    expect(find.text('Clear the walking path first.'), findsOneWidget);
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
        finalPlan: _savedPlan(planJson: _planJson(itemName: 'Chair')),
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

  testWidgets('missing structured plan shows honest empty state', (
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
      find.text('Structured move plan is not available yet.'),
      findsOneWidget,
    );
  });

  testWidgets('share/download does not pretend to export fake data', (
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
    await tester.tap(find.byIcon(Icons.share_rounded));
    await tester.pump();

    expect(find.text('Export is not available yet.'), findsOneWidget);
  });

  testWidgets('Final Plan renders multiple floor-plan items from backend', (
    tester,
  ) async {
    final planJson = _multiItemPlanJson();
    final api = _FakeFinalPlanApi(
      designs: [_designRow('d1', selected: true)],
      designDetails: {
        'd1': _designDetail(
          'd1',
          outputUrl: 'https://cdn.example.com/generated.png',
          planJson: planJson,
          planStatus: 'succeeded',
        ),
      },
      items: [
        _itemRow('i-sofa', 'Sofa', 'sofa'),
        _itemRow('i-rug', 'Rug', 'rug'),
      ],
      finalPlan: _savedPlan(planJson: planJson),
    );

    await _pumpFinalPlan(tester, api);

    // Multiple real furniture boxes render (Detected list + floor box = many).
    expect(find.text('Sofa'), findsWidgets);
    expect(find.text('Rug'), findsWidgets);
  });

  testWidgets('Final Plan does not render a full-room Wall as a box', (
    tester,
  ) async {
    final planJson = _multiItemPlanJson();
    final api = _FakeFinalPlanApi(
      designs: [_designRow('d1', selected: true)],
      designDetails: {
        'd1': _designDetail(
          'd1',
          outputUrl: 'https://cdn.example.com/generated.png',
          planJson: planJson,
          planStatus: 'succeeded',
        ),
      },
      finalPlan: _savedPlan(planJson: planJson),
    );

    await _pumpFinalPlan(tester, api);

    // The structural wall must not be drawn as a labelled box covering the card.
    expect(find.text('Wall'), findsNothing);
    // Furniture is still visible (not hidden behind a wall block).
    expect(find.text('Sofa'), findsWidgets);
  });

  testWidgets('Final Plan warns when floor plan has only a wall', (
    tester,
  ) async {
    final planJson = _wallOnlyPlanJson();
    final api = _FakeFinalPlanApi(
      designs: [_designRow('d1', selected: true)],
      designDetails: {
        'd1': _designDetail(
          'd1',
          outputUrl: 'https://cdn.example.com/generated.png',
          planJson: planJson,
          planStatus: 'succeeded',
        ),
      },
      finalPlan: _savedPlan(planJson: planJson),
    );

    await _pumpFinalPlan(tester, api);

    expect(
      find.text('Floor plan data is incomplete. Regenerate the layout.'),
      findsOneWidget,
    );
    expect(find.text('Wall'), findsNothing);
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
