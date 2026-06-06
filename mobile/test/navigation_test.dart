import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:respace_ai/app/navigation.dart';

Widget _page(String label, {VoidCallback? onBack}) {
  return Builder(
    builder: (context) => Scaffold(
      body: Column(
        children: [
          Text(label),
          if (onBack != null)
            TextButton(onPressed: () => onBack(), child: const Text('back')),
          TextButton(
            onPressed: () => context.push('/b'),
            child: const Text('go b'),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('safePop pops the pushed route when a back stack exists', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/a',
      routes: [
        GoRoute(path: '/a', builder: (_, _) => _page('A PAGE')),
        GoRoute(
          path: '/b',
          builder: (context, _) =>
              _page('B PAGE', onBack: () => safePop(context)),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('go b'));
    await tester.pumpAndSettle();
    expect(find.text('B PAGE'), findsOneWidget);

    // Real back stack -> pop back to A (not a forward navigation to a new A).
    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    expect(find.text('A PAGE'), findsOneWidget);
    expect(find.text('B PAGE'), findsNothing);
  });

  testWidgets('safePop falls back to a location when there is nothing to pop', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/a',
      routes: [
        GoRoute(
          path: '/a',
          builder: (context, _) =>
              _page('A PAGE', onBack: () => safePop(context, fallback: '/c')),
        ),
        GoRoute(path: '/c', builder: (_, _) => _page('C PAGE')),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('A PAGE'), findsOneWidget);

    // No back stack at the initial route -> deterministic fallback.
    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    expect(find.text('C PAGE'), findsOneWidget);
  });
}
