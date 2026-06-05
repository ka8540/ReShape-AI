import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:respace_ai/screens/screens.dart';
import 'package:respace_ai/services/api_service.dart';
import 'package:respace_ai/state/project_state.dart';

Map<String, dynamic> _row(
  String id,
  String name,
  String type, {
  bool fixed = false,
  bool structural = false,
  bool added = false,
}) {
  return {
    'id': id,
    'project_id': 'p1',
    'name': name,
    'type': type,
    'confidence': 0.9,
    'fixed': fixed,
    'structural': structural,
    'added_by_user': added,
  };
}

/// In-memory ApiService stand-in for the items endpoints.
class _FakeApi extends ApiService {
  _FakeApi(this.items) : super(Dio());

  List<Map<String, dynamic>> items;
  bool deleteCalled = false;

  @override
  Future<List<Map<String, dynamic>>> listItems(String projectId) async => items;

  @override
  Future<void> deleteItem({
    required String projectId,
    required String itemId,
  }) async {
    deleteCalled = true;
    items = items.where((i) => i['id'] != itemId).toList();
  }

  @override
  Future<Map<String, dynamic>> createItem({
    required String projectId,
    required String name,
    required String type,
    bool fixed = false,
    bool structural = false,
  }) async {
    final row = _row('new-$name', name, type, added: true);
    items = [...items, row];
    return row;
  }

  @override
  Future<Map<String, dynamic>> patchItem({
    required String projectId,
    required String itemId,
    Map<String, dynamic>? changes,
  }) async {
    items = items
        .map((i) => i['id'] == itemId ? {...i, ...?changes} : i)
        .toList();
    return items.firstWhere((i) => i['id'] == itemId);
  }

  @override
  Future<Map<String, dynamic>> retryProcessing(String projectId) async {
    return {'project_id': projectId, 'status': 'awaiting_user_review'};
  }
}

void main() {
  Future<_FakeApi> pumpReview(
    WidgetTester tester,
    List<Map<String, dynamic>> rows,
  ) async {
    tester.view.physicalSize = const Size(1200, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApi(rows);
    final container = ProviderContainer(
      overrides: [apiServiceProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    // Enable backend mode (useMockData is false by default in tests).
    container
        .read(projectControllerProvider.notifier)
        .setRemoteProjectId('p1');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ReviewItemsScreen()),
      ),
    );
    // Flush the post-frame fetch + async resolution.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
    return api;
  }

  testWidgets('renders backend items', (tester) async {
    await pumpReview(tester, [
      _row('i1', 'Sofa', 'sofa'),
      _row('i2', 'Window', 'window', fixed: true, structural: true),
    ]);

    expect(find.text('Review detected items'), findsOneWidget);
    expect(find.text('Sofa'), findsOneWidget);
    expect(find.text('Window'), findsOneWidget); // structural section
    expect(find.text('No items detected'), findsNothing);
  });

  testWidgets('shows empty state with retry when zero items', (tester) async {
    await pumpReview(tester, <Map<String, dynamic>>[]);

    expect(find.text('No items detected'), findsOneWidget);
    expect(find.text('Retry processing'), findsOneWidget);
    expect(find.text('Add missing item'), findsOneWidget);
  });

  testWidgets('delete removes the item from the UI', (tester) async {
    final api = await pumpReview(tester, [_row('i1', 'Sofa', 'sofa')]);

    expect(find.text('Sofa'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(api.deleteCalled, isTrue);
    expect(find.text('Sofa'), findsNothing);
    // With no items left, the empty state appears.
    expect(find.text('No items detected'), findsOneWidget);
  });

  testWidgets('fixed toggle updates the marked-fixed count', (tester) async {
    await pumpReview(tester, [
      _row('i1', 'Sofa', 'sofa'),
      _row('i2', 'Chair', 'chair'),
    ]);

    // 2 found, 0 fixed.
    expect(find.text('2'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('Fixed').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    // Now exactly one item is marked fixed.
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('manual add item creates and displays it', (tester) async {
    await pumpReview(tester, [_row('i1', 'Sofa', 'sofa')]);

    await tester.tap(find.text('Add missing item'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chair'));
    await tester.pumpAndSettle();

    expect(find.text('Chair'), findsOneWidget);
  });
}
