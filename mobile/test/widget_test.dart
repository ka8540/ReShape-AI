import 'package:flutter_test/flutter_test.dart';

import 'package:respace_ai/main.dart';

void main() {
  testWidgets('renders the ReSpace AI welcome experience', (tester) async {
    await tester.pumpWidget(const ReSpaceBootstrap());

    expect(find.textContaining('ReSpace'), findsWidgets);
    expect(find.text('Get started'), findsOneWidget);
  });
}
